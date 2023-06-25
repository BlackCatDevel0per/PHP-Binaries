echo -n "[PHP]"

if [ "$DO_OPTIMIZE" != "no" ]; then
	echo -n " enabling optimizations..."
	PHP_OPTIMIZATION="--enable-inline-optimization "
else
	PHP_OPTIMIZATION="--disable-inline-optimization "
fi
write_check
# FIXME: Fix all paths if script will change in future!
cd "$BUILD_DIR/php"
rm -f ./aclocal.m4 >> $INSTALL_LOG 2>&1
rm -rf ./autom4te.cache/ >> $INSTALL_LOG 2>&1
rm -f ./configure >> $INSTALL_LOG 2>&1

# autoreconnf fails after autoupdate..
# autoreconf --force >> $INSTALL_LOG 2>&1
# autoupdate
./buildconf --force >> $INSTALL_LOG 2>&1

if [ "$COMPILE_GD" == "yes" ]; then
	EXTENSIONS="$EXTENSIONS --enable-exif"
fi

if [ "$DO_STATIC" == "yes" ]; then
	# EXTENSIONS="$EXTENSIONS --enable-zip=static"
	EXTENSIONS="$EXTENSIONS --with-gmp=static"
else
	# EXTENSIONS="$EXTENSIONS --enable-zip=shared"
	EXTENSIONS="$EXTENSIONS --with-gmp=shared"
fi

#hack for curl with pkg-config (ext/curl doesn't give --static to pkg-config on static builds)
if [ "$DO_STATIC" == "yes" ]; then
	if [ -z "$PKG_CONFIG" ]; then
		PKG_CONFIG="$(which pkg-config)" || true
	fi
	if [ ! -z "$PKG_CONFIG" ]; then
		#only export this if pkg-config exists, otherwise leave it (it'll fall back to curl-config)

		echo '#!/bin/sh' > "$BUILD_DIR/pkg-config-wrapper"
		echo 'exec '$PKG_CONFIG' "$@" --static' >> "$BUILD_DIR/pkg-config-wrapper"
		chmod +x "$BUILD_DIR/pkg-config-wrapper"
		export PKG_CONFIG="$BUILD_DIR/pkg-config-wrapper"
	fi
fi


if [ "$IS_CROSSCOMPILE" == "yes" ]; then
	sed -i=".backup" 's/pthreads_working=no/pthreads_working=yes/' ./configure
	if [ "$IS_WINDOWS" != "yes" ]; then
		if [ "$COMPILE_FOR_ANDROID" == "no" ]; then
			export LIBS="$LIBS -lpthread -ldl -lresolv"
		else
			export LIBS="$LIBS -lpthread -lresolv"
		fi
	else
		export LIBS="$LIBS -lpthread"
	fi

	mv ext/mysqlnd/config9.m4 ext/mysqlnd/config.m4
	sed  -i=".backup" "s{ext/mysqlnd/php_mysqlnd_config.h{config.h{" ext/mysqlnd/mysqlnd_portability.h
elif [ "$DO_STATIC" == "yes" ]; then
	export LIBS="$LIBS -ldl"
fi

if [ "$IS_WINDOWS" != "yes" ]; then
	HAVE_PCNTL="--enable-pcntl"
else
	HAVE_PCNTL="--disable-pcntl"
	cp -f ./win32/build/config.* ./main >> $INSTALL_LOG 2>&1
	sed 's:@PREFIX@:$DIR/bin/php7:' ./main/config.w32.h.in > ./wmain/config.w32.h 2>> $INSTALL_LOG
fi

if [[ "$(uname -s)" == "Darwin" ]] && [[ "$IS_CROSSCOMPILE" != "yes" ]]; then
	sed -i=".backup" 's/flock_type=unknown/flock_type=bsd/' ./configure
	export EXTRA_CFLAGS=-lresolv
fi

if [[ "$COMPILE_DEBUG" == "yes" ]]; then
	HAS_DEBUG="--enable-debug"
else
	HAS_DEBUG="--disable-debug"
fi

if [ "$FSANITIZE_OPTIONS" != "" ]; then
	CFLAGS="$CFLAGS -fsanitize=$FSANITIZE_OPTIONS -fno-omit-frame-pointer"
	CXXFLAGS="$CXXFLAGS -fsanitize=$FSANITIZE_OPTIONS -fno-omit-frame-pointer"
	LDFLAGS="-fsanitize=$FSANITIZE_OPTIONS $LDFLAGS"
fi

# Fix error - ./configure: line 56218: syntax error near unexpected token `LIBDEFLATE,'
sed -i 's/PKG_CHECK_MODULES(LIBDEFLATE, libdeflate)/# &/' configure

# Apply some patches from aur (phpXX - XX is major version)
find $PHP_PATCHES -name "*.patch" -exec sh -c 'echo "[PATCH] Applying source patch {}"; patch -p1 -i "{}"' \;
# for patch_file in $(ls -1 $PHP_PATCHES/*.patch); do
#     echo "[PATCH] Applying source patch $patch_file"
#     patch -p1 -i "$patch_file"
# done

# Configuration args for current php version ($PHP_CONF var)
source "$PHP_CONF"

RANLIB=$RANLIB CFLAGS="$CFLAGS $FLAGS_LTO" CXXFLAGS="$CXXFLAGS $FLAGS_LTO" LDFLAGS="$LDFLAGS $FLAGS_LTO" ./configure $PHP_OPTIMIZATION $PHP_CONF_ARGS \
$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1

# FIXME: Recheck output log funcs..

write_compile
if [ "$COMPILE_FOR_ANDROID" == "yes" ]; then
	sed -i=".backup" 's/-export-dynamic/-all-static/g' Makefile
fi
sed -i=".backup" 's/PHP_BINARIES. pharcmd$/PHP_BINARIES)/g' Makefile
sed -i=".backup" 's/install-programs install-pharcmd$/install-programs/g' Makefile

if [[ "$DO_STATIC" == "yes" ]]; then
	sed -i=".backup" 's/--mode=link $(CC)/--mode=link $(CXX)/g' Makefile
fi

