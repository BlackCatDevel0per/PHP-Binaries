if [ "$PM_VERSION_MAJOR" == "" ]; then
	write_opt "PocketMine-MP major version is 4"
	PM_VERSION_MAJOR=4
	# echo "Please specify PocketMine-MP major version target with -P (e.g. -P5)"
	# exit 1
fi

write_opt "Compiling with configuration for PocketMine-MP $PM_VERSION_MAJOR"

GMP_ABI=""
TOOLCHAIN_PREFIX=""
OPENSSL_TARGET=""
CMAKE_GLOBAL_EXTRA_FLAGS=""

# Crosscompile
if [ "$IS_CROSSCOMPILE" == "yes" ]; then
	export CROSS_COMPILER="$PATH"
	if [[ "$COMPILE_TARGET" == "win" ]] || [[ "$COMPILE_TARGET" == "win64" ]]; then
		TOOLCHAIN_PREFIX="x86_64-w64-mingw32"
		[ -z "$march" ] && march=x86_64;
		[ -z "$mtune" ] && mtune=nocona;
		CFLAGS="$CFLAGS -mconsole"
		CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX --target=$TOOLCHAIN_PREFIX --build=$TOOLCHAIN_PREFIX"
		IS_WINDOWS="yes"
		OPENSSL_TARGET="mingw64"
		GMP_ABI="64"
		write_info "Cross-compiling for Windows 64-bit"
	elif [ "$COMPILE_TARGET" == "mac" ]; then
		[ -z "$march" ] && march=prescott;
		[ -z "$mtune" ] && mtune=generic;
		CFLAGS="$CFLAGS -fomit-frame-pointer";
		TOOLCHAIN_PREFIX="i686-apple-darwin10"
		CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX"
		#zlib doesn't use the correct ranlib
		RANLIB=$TOOLCHAIN_PREFIX-ranlib
		CFLAGS="$CFLAGS -Qunused-arguments -Wno-error=unused-command-line-argument-hard-error-in-future"
		ARCHFLAGS="-Wno-error=unused-command-line-argument-hard-error-in-future"
		OPENSSL_TARGET="darwin64-x86_64-cc"
		GMP_ABI="32"
		write_info "Cross-compiling for Intel MacOS"
	elif [ "$COMPILE_TARGET" == "android-aarch64" ]; then
		COMPILE_FOR_ANDROID=yes
		[ -z "$march" ] && march="armv8-a";
		[ -z "$mtune" ] && mtune=generic;
		TOOLCHAIN_PREFIX="aarch64-linux-musl"
		CONFIGURE_FLAGS="--host=$TOOLCHAIN_PREFIX"
		# Why static???
		CFLAGS="-static $CFLAGS"
		CXXFLAGS="-static $CXXFLAGS"
		if [ "$USE_COMPILER" == "clang" ]; then
			LDFLAGS="-static -Wl,-static"  # clang########
		elif [ "$USE_COMPILER" == "gcc" ]; then
			LDFLAGS="-static -static-libgcc -Wl,-static"
		fi
		DO_STATIC="yes"
		OPENSSL_TARGET="linux-aarch64"
		export ac_cv_func_fnmatch_works=yes #musl should be OK
		write_info "Cross-compiling for Android ARMv8 (aarch64)"
	#TODO: add cross-compile for aarch64 platforms (ios, rpi)
	else
		echo "Please supply a proper platform [mac win win64 android-aarch64] to cross-compile"
		exit 1
	fi
# Just compile for desktop/server
else
	if [[ "$COMPILE_TARGET" == "" ]] && [[ "$(uname -s)" == "Darwin" ]]; then
		if [ "$(uname -m)" == "arm64" ]; then
			COMPILE_TARGET="mac-arm64"
		else
			COMPILE_TARGET="mac-x86-64"
		fi
	fi
	if [[ "$COMPILE_TARGET" == "linux" ]] || [[ "$COMPILE_TARGET" == "linux64" ]]; then
		[ -z "$march" ] && march=x86-64;
		[ -z "$mtune" ] && mtune=skylake;
		CFLAGS="$CFLAGS -m64"
		GMP_ABI="64"
		OPENSSL_TARGET="linux-x86_64"
		write_info "Compiling for Linux x86_64"
	elif [[ "$COMPILE_TARGET" == "mac-x86-64" ]]; then
		[ -z "$march" ] && march=core2;
		[ -z "$mtune" ] && mtune=generic;
		[ -z "$MACOSX_DEPLOYMENT_TARGET" ] && export MACOSX_DEPLOYMENT_TARGET=10.9;
		CFLAGS="$CFLAGS -m64 -arch x86_64 -fomit-frame-pointer -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
		LDFLAGS="$LDFLAGS -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
		if [ "$DO_STATIC" == "no" ]; then
			LDFLAGS="$LDFLAGS -Wl,-rpath,@loader_path/../lib";
			export DYLD_LIBRARY_PATH="@loader_path/../lib"
		fi
		CFLAGS="$CFLAGS -Qunused-arguments -Wno-error=unused-command-line-argument-hard-error-in-future"
		ARCHFLAGS="-Wno-error=unused-command-line-argument-hard-error-in-future"
		GMP_ABI="64"
		OPENSSL_TARGET="darwin64-x86_64-cc"
		CMAKE_GLOBAL_EXTRA_FLAGS="-DCMAKE_OSX_ARCHITECTURES=x86_64"
		write_info "Compiling for MacOS x86_64"
	#TODO: add aarch64 platforms (ios, android, rpi)
	elif [[ "$COMPILE_TARGET" == "mac-arm64" ]]; then
		[ -z "$MACOSX_DEPLOYMENT_TARGET" ] && export MACOSX_DEPLOYMENT_TARGET=11.0;
		CFLAGS="$CFLAGS -arch arm64 -fomit-frame-pointer -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
		LDFLAGS="$LDFLAGS -mmacosx-version-min=$MACOSX_DEPLOYMENT_TARGET"
		if [ "$DO_STATIC" == "no" ]; then
			LDFLAGS="$LDFLAGS -Wl,-rpath,@loader_path/../lib";
			export DYLD_LIBRARY_PATH="@loader_path/../lib"
		fi
		CFLAGS="$CFLAGS -Qunused-arguments"
		GMP_ABI="64"
		OPENSSL_TARGET="darwin64-arm64-cc"
		CMAKE_GLOBAL_EXTRA_FLAGS="-DCMAKE_OSX_ARCHITECTURES=arm64"
		write_info "Compiling for MacOS M1"
	elif [[ "$COMPILE_TARGET" != "" ]]; then
		echo "Please supply a proper platform [mac-arm64 mac-x86-64 linux linux64] to compile for"
		exit 1
	elif [ -z "$COMPILE_TARGET" ]; then  # if no $COMPILE_TARGET
		if [ `getconf LONG_BIT` == "64" ]; then
			[ -z "$march" ] && march=native;  # if no march set it to native  x86-64
			[ -z "$mtune" ] && mtune=native;  # if no mtune set it to native
			write_info "Compiling for march=$march mtune=$mtune using 64-bit"
			if [ "$(uname -m)" != "aarch64" ]; then
				CFLAGS="-m64 $CFLAGS"
			fi
			GMP_ABI="64"
		else
			write_error "PocketMine-MP is no longer supported on 32-bit systems"
			exit 1
		fi
	fi
fi

if [ "$DO_STATIC" == "yes" ]; then
	HAVE_OPCACHE="no" #doesn't work on static builds
	HAVE_OPCACHE_JIT="no"
	write_warning "OPcache cannot be used on static builds; this may have a negative effect on performance"
	if [ "$FSANITIZE_OPTIONS" != "" ]; then
		write_warning "Sanitizers cannot be used on static builds"
	fi
	if [ "$HAVE_XDEBUG" == "yes" ]; then
		write_warning "Xdebug cannot be built in static mode"
		HAVE_XDEBUG="no"
	fi
fi

if [ "$DO_OPTIMIZE" != "no" ]; then
	if [ "$USE_COMPILER" == "clang" ]; then
		FLAGS_LTO="-fvisibility=hidden -flto"  # llvm..?
	fi
	# CFLAGS="$CFLAGS -O2 -ftree-vectorize -fomit-frame-pointer -funswitch-loops -fivopts"
	CFLAGS="$CFLAGS -O3 -ftree-vectorize -fomit-frame-pointer -funswitch-loops -fivopts"
	if [ "$COMPILE_TARGET" != "mac-x86-64" ] && [ "$COMPILE_TARGET" != "mac-arm64" ]; then
		CFLAGS="$CFLAGS -funsafe-loop-optimizations -ftracer -frename-registers"
	fi

	if [ "$OPTIMIZE_TARGET" == "arm" ]; then
		CFLAGS="$CFLAGS -mfpu=vfp"
	elif [ "$OPTIMIZE_TARGET" == "x86_64" ]; then
		if [ "$USE_COMPILER" == "clang" ]; then
			CFLAGS="$CFLAGS -mmmx -msse -msse2 -msse3 -mfpmath=sse -msahf"
		elif [ "$USE_COMPILER" == "gcc" ]; then
			CFLAGS="$CFLAGS -mmmx -msse -msse2 -msse3 -mfpmath=sse -free -msahf -ftree-parallelize-loops=4"
		fi
	elif [ "$OPTIMIZE_TARGET" == "x86" ]; then
		CFLAGS="$CFLAGS -mmmx -msse -msse2 -mfpmath=sse -m128bit-long-double -malign-double -ftree-parallelize-loops=4"
	fi
fi

if [ "$TOOLCHAIN_PREFIX" != "" ]; then
		write_out "Tools" "Setting toolchains.."
		if [ "$USE_COMPILER" == "clang" ]; then
			export LD="$TOOLCHAIN_PREFIX-lld"
			export CC="ccache $TOOLCHAIN_PREFIX-clang"
			export CXX="ccache $TOOLCHAIN_PREFIX-clang++"
			export CPP="ccache $TOOLCHAIN_PREFIX-cpp"
			export AR="ccache $TOOLCHAIN_PREFIX-ar"
			export RANLIB="$TOOLCHAIN_PREFIX-ranlib"
		elif [ "$USE_COMPILER" == "gcc" ]; then
			export LD="$TOOLCHAIN_PREFIX-ld"
			export CC="ccache $TOOLCHAIN_PREFIX-gcc"
			export CXX="ccache $TOOLCHAIN_PREFIX-g++"
			export CPP="ccache $TOOLCHAIN_PREFIX-cpp"
			export AR="ccache $TOOLCHAIN_PREFIX-ar"
			export RANLIB="$TOOLCHAIN_PREFIX-ranlib"
		fi
fi

# test if host has compiler
echo "#include <stdio.h>" > test.c
echo "int main(void){" >> test.c
echo "printf(\"Hello world\n\");" >> test.c
echo "return 0;" >> test.c
echo "}" >> test.c


type $CC >> $INSTALL_LOG 2>&1 || { echo >&2 "[ERROR] Please install \"$CC\""; exit 1; }

if [ -z "$THREADS" ]; then
	write_warning "Only 1 thread is used by default. Increase thread count using -j (e.g. -j 4) to compile faster."
	THREADS=1;
fi
[ -z "$CFLAGS" ] && CFLAGS="";

if [ "$DO_STATIC" == "no" ]; then
	[ -z "$LDFLAGS" ] && LDFLAGS="-Wl,-rpath='\$\$ORIGIN/../lib' -Wl,-rpath-link='\$\$ORIGIN/../lib'";
fi

[ -z "$CONFIGURE_FLAGS" ] && CONFIGURE_FLAGS="";

if [ "$mtune" != "none" ]; then
	$CC -march=$march -mtune=$mtune $CFLAGS -o test test.c >> $INSTALL_LOG 2>&1
	if [ $? -eq 0 ]; then
		CFLAGS="-march=$march -mtune=$mtune -fno-gcse $CFLAGS"
	fi
else
	$CC -march=$march $CFLAGS -o test test.c >> $INSTALL_LOG 2>&1
	if [ $? -eq 0 ]; then
		CFLAGS="-march=$march -fno-gcse $CFLAGS"
	fi
fi

# Check sanitizers
if [ "$FSANITIZE_OPTIONS" != "" ]; then
	CFLAGS="$CFLAGS" CXXFLAGS="$CXXFLAGS" LDFLAGS="$LDFLAGS" $CC -fsanitize=$FSANITIZE_OPTIONS -o asan-test test.c >> $INSTALL_LOG 2>&1 && \
		chmod +x asan-test >> $INSTALL_LOG 2>&1 && \
		./asan-test >> $INSTALL_LOG 2>&1 && \
		rm asan-test >> $INSTALL_LOG 2>&1
	if [ $? -ne 0 ]; then
		write_error "One or more sanitizers are not working. Check install.log for details."
		exit 1
	else
		write_info "All selected sanitizers are working"
	fi
fi

rm test.* >> $INSTALL_LOG 2>&1
rm test >> $INSTALL_LOG 2>&1

export CC="$CC"
export CXX="$CXX"
export CFLAGS="-fPIC $CFLAGS"
export CXXFLAGS="$CFLAGS $CXXFLAGS"
export LDFLAGS="$LDFLAGS"
export CPPFLAGS="$CPPFLAGS"
export LIBRARY_PATH="$INSTALL_DIR/lib:$LIBRARY_PATH"
export PKG_CONFIG_PATH="$INSTALL_DIR/lib/pkgconfig"

#some stuff (like curl) makes assumptions about library paths that break due to different behaviour in pkgconf vs pkg-config
export PKG_CONFIG_ALLOW_SYSTEM_LIBS="yes"
export PKG_CONFIG_ALLOW_SYSTEM_CFLAGS="yes"

rm -r -f "$BASE_BUILD_DIR" >> $INSTALL_LOG 2>&1
rm -r -f bin/ >> $INSTALL_LOG 2>&1
mkdir -m 0755 "$BASE_BUILD_DIR" >> $INSTALL_LOG 2>&1
mkdir -m 0755 "$BUILD_DIR" >> $INSTALL_LOG 2>&1
mkdir -m 0755 -p $INSTALL_DIR >> $INSTALL_LOG 2>&1
mkdir -m 0755 -p "$LIB_BUILD_DIR" >> $INSTALL_LOG 2>&1
cd "$BUILD_DIR"
set -e

