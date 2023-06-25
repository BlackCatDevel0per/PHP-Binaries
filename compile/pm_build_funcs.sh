# FIXME: add flag ` --with-pic` to every `EXTRA_CFLAGS`
function build_ncurses {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-shared=no --enable-static=yes --with-pic"
	else
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
	fi

	write_library ncurses "$NCURSES_VERSION"
	local ncurses_dir="./ncurses"

	if cant_use_cache "$ncurses_dir"; then
		rm -rf "$ncurses_dir"
		write_download
		download_file "http://ftp.gnu.org/gnu/ncurses/ncurses-$NCURSES_VERSION.tar.gz" "ncurses" | tar -zx >> $INSTALL_LOG 2>&1
		mv "ncurses-$NCURSES_VERSION" "$ncurses_dir"
		write_check
		cd "$ncurses_dir"
		RANLIB=$RANLIB ./configure --prefix="$INSTALL_DIR" \
		--without-ada \
		--without-manpages \
		--without-progs \
		--without-tests \
		--with-normal \
		--with-pthread \
		--without-debug \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$ncurses_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..

	# HAVE_NCURSES="--with-ncurses=$INSTALL_DIR"  # not used because it builds for readline
	# not tested!
	# if [ "$DO_STATIC" != "yes" ]; then
	# 	rm -f "$INSTALL_DIR/lib/libncurses.a"
	# fi
	write_done
}

function build_readline {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-shared=no --enable-static=yes"
	else
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
	fi

	write_library readline "$READLINE_VERSION"
	local readline_dir="./readline"

	if cant_use_cache "$readline_dir"; then
		rm -rf "$readline_dir"
		write_download
		download_file "http://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz" "readline" | tar -zx >> $INSTALL_LOG 2>&1
		mv "readline-$READLINE_VERSION" "$readline_dir"
		write_check
		cd "$readline_dir"
		# for new php is ncurses builds for readline
		RANLIB=$RANLIB ./configure --prefix="$INSTALL_DIR" \
		--with-curses="$INSTALL_DIR" \
		--enable-multibyte \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$readline_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..

	HAVE_READLINE="--with-readline=$INSTALL_DIR"
	# not tested
	# if [ "$DO_STATIC" != "yes" ]; then
	# 	rm -f "$INSTALL_DIR/lib/libreadline.a"
	# fi
	write_done
}

function build_zlib {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--static"
	else
		local EXTRA_FLAGS="--shared"
	fi

	write_library zlib "$ZLIB_VERSION"
	local zlib_dir="./zlib-$ZLIB_VERSION"

	if cant_use_cache "$zlib_dir"; then
		rm -rf "$zlib_dir"
		write_download
		download_file "https://github.com/madler/zlib/archive/v$ZLIB_VERSION.tar.gz" "zlib" | tar -zx >> $INSTALL_LOG 2>&1
		write_check
		cd "$zlib_dir"
		RANLIB=$RANLIB ./configure --prefix="$INSTALL_DIR" \
		$EXTRA_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$zlib_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	# if [ "$DO_STATIC" != "yes" ]; then
	# 	rm -f "$INSTALL_DIR/lib/libz.a"
	# fi
	write_done
}

function build_gmp {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# WARNING: Force static
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi
	export jm_cv_func_working_malloc=yes
	export ac_cv_func_malloc_0_nonnull=yes
	export jm_cv_func_working_realloc=yes
	export ac_cv_func_realloc_0_nonnull=yes

	if [ "$IS_CROSSCOMPILE" == "yes" ]; then
		local EXTRA_FLAGS=""
	else
		local EXTRA_FLAGS="$EXTRA_FLAGS --disable-assembly"
	fi

	write_library gmp "$GMP_VERSION"
	local gmp_dir="./gmp-$GMP_VERSION"

	if cant_use_cache "$gmp_dir"; then
		rm -rf "$gmp_dir"
		write_download
		download_file "https://gmplib.org/download/gmp/gmp-$GMP_VERSION.tar.bz2" "gmp" | tar -jx >> $INSTALL_LOG 2>&1
		write_check
		cd "$gmp_dir"
		# pthreads used instead of posix-threads
		RANLIB=$RANLIB ./configure --prefix="$INSTALL_DIR" \
			--disable-posix-threads \
			$EXTRA_FLAGS \
			$CONFIGURE_FLAGS ABI="$GMP_ABI" >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$gmp_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_openssl {
	#OpenSSL
	OPENSSL_CMD="./config"
	if [ "$OPENSSL_TARGET" != "" ]; then
		local OPENSSL_CMD="./Configure $OPENSSL_TARGET"
	fi
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="no-shared"
	else
		local EXTRA_FLAGS="shared"
	fi

	WITH_OPENSSL="--with-openssl=$INSTALL_DIR"

	write_library openssl "$OPENSSL_VERSION"
	local openssl_dir="./openssl-$OPENSSL_VERSION"

	if cant_use_cache "$openssl_dir"; then
		rm -rf "$openssl_dir"
		write_download
		download_file "http://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" "openssl" | tar -zx >> $INSTALL_LOG 2>&1

		write_check
		cd "$openssl_dir"
		RANLIB=$RANLIB $OPENSSL_CMD \
		--prefix="$INSTALL_DIR" \
		--openssldir="$INSTALL_DIR" \
		--libdir="$INSTALL_DIR/lib" \
		no-asm \
		no-hw \
		no-engine \
		$EXTRA_FLAGS >> $INSTALL_LOG 2>&1

		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$openssl_dir"
	fi
	write_install
	make install_sw >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_curl {
	if [ "$DO_STATIC" == "yes" ]; then
		# local EXTRA_FLAGS="--enable-static --disable-shared"  # no
		# local EXTRA_FLAGS="--enable-static"  # no
		# local EXTRA_FLAGS="--enable-static --enable-shared"  # no
		# local EXTRA_FLAGS="--disable-static --enable-shared"  # no
		# local EXTRA_FLAGS="--disable-shared" # well..
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory: '../lib/.libs/libcurl.so'
		# local EXTRA_FLAGS="--disable-static --enable-shared"
		# local EXTRA_FLAGS="--disable-shared"
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library curl "$CURL_VERSION"
	local curl_dir="./curl-$CURL_VERSION"
	if cant_use_cache "$curl_dir"; then
		rm -rf "$curl_dir"
		write_download
		download_file "https://github.com/curl/curl/archive/$CURL_VERSION.tar.gz" "curl" | tar -zx >> $INSTALL_LOG 2>&1
		write_check
		cd "$curl_dir"
		autoreconf -fi >> $INSTALL_LOG 2>&1
		autoupdate
		# ./buildconf --force >> $INSTALL_LOG 2>&1
		# --without-libidn \
		RANLIB=$RANLIB ./configure --disable-dependency-tracking \
		--enable-ipv6 \
		--enable-optimize \
		--enable-http \
		--enable-ftp \
		--disable-dict \
		--enable-file \
		--without-librtmp \
		--disable-gopher \
		--disable-imap \
		--disable-pop3 \
		--disable-rtsp \
		--disable-smtp \
		--disable-telnet \
		--disable-tftp \
		--disable-ldap \
		--disable-ldaps \
		--without-libidn2 \
		--without-brotli \
		--without-nghttp2 \
		--without-zstd \
		--with-zlib="$INSTALL_DIR" \
		--with-ssl="$INSTALL_DIR" \
		--enable-threaded-resolver \
		--prefix="$INSTALL_DIR" \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$curl_dir"
	fi

	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_yaml {
	if [ "$DO_STATIC" == "yes" ]; then
		# local EXTRA_FLAGS="--disable-shared --enable-static"
		# local EXTRA_FLAGS="--disable-shared"
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory
		# local EXTRA_FLAGS="--enable-shared --disable-static"
		# local EXTRA_FLAGS="--disable-shared"
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library yaml "$YAML_VERSION"
	local yaml_dir="./libyaml-$YAML_VERSION"
	if cant_use_cache "$yaml_dir"; then
		rm -rf "$yaml_dir"
		write_download
		download_file "https://github.com/yaml/libyaml/archive/$YAML_VERSION.tar.gz" "yaml" | tar -zx >> $INSTALL_LOG 2>&1
		cd "$yaml_dir"
		./bootstrap >> $INSTALL_LOG 2>&1

		write_check

		RANLIB=$RANLIB ./configure \
		--prefix="$INSTALL_DIR" \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		sed -i=".backup" 's/ tests win32/ win32/g' Makefile
		write_compile
		make -j $THREADS all >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$yaml_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_leveldb {
	write_library leveldb "$LEVELDB_VERSION"
	local leveldb_dir="./leveldb-$LEVELDB_VERSION"
	if cant_use_cache "$leveldb_dir"; then
		rm -rf "$leveldb_dir"
		write_download
		download_file "https://github.com/pmmp/leveldb/archive/$LEVELDB_VERSION.tar.gz" "leveldb" | tar -zx >> $INSTALL_LOG 2>&1
		#download_file "https://github.com/Mojang/leveldb-mcpe/archive/$LEVELDB_VERSION.tar.gz" | tar -zx >> $INSTALL_LOG 2>&1
		write_check
		cd "$leveldb_dir"
		if [ "$DO_STATIC" == "yes" ]; then  ###
			local EXTRA_FLAGS="-DBUILD_SHARED_LIBS=ON"
		else
			local EXTRA_FLAGS=""
		fi
		cmake . \
			-DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
			-DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
			-DCMAKE_INSTALL_LIBDIR=lib \
			-DLEVELDB_BUILD_TESTS=OFF \
			-DLEVELDB_BUILD_BENCHMARKS=OFF \
			-DLEVELDB_SNAPPY=OFF \
			-DLEVELDB_ZSTD=OFF \
			-DLEVELDB_TCMALLOC=OFF \
			-DCMAKE_BUILD_TYPE=Release \
			$CMAKE_GLOBAL_EXTRA_FLAGS \
			$EXTRA_FLAGS \
			>> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$leveldb_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_libpng {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory: './.libs/libpng16.so'
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library libpng "$LIBPNG_VERSION"
	local libpng_dir="./libpng-$LIBPNG_VERSION"
	if cant_use_cache "$libpng_dir"; then
		rm -rf "$libpng_dir"
		write_download
		download_file "https://sourceforge.net/projects/libpng/files/libpng16/$LIBPNG_VERSION/libpng-$LIBPNG_VERSION.tar.gz" "libpng" | tar -zx >> $INSTALL_LOG 2>&1
		write_check
		cd "$libpng_dir"
		LDFLAGS="$LDFLAGS -L${INSTALL_DIR}/lib" CPPFLAGS="$CPPFLAGS -I${INSTALL_DIR}/include" RANLIB=$RANLIB ./configure \
		--prefix="$INSTALL_DIR" \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$libpng_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..


	HAS_LIBPNG="--with-png-dir=$INSTALL_DIR"
	write_done
}

function build_libjpeg {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory: './.libs/libjpeg.so'
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library libjpeg "$LIBJPEG_VERSION"
	local libjpeg_dir="./libjpeg-$LIBJPEG_VERSION"
	if cant_use_cache "$libjpeg_dir"; then
		rm -rf "$libjpeg_dir"
		write_download
		download_file "http://ijg.org/files/jpegsrc.v$LIBJPEG_VERSION.tar.gz" "libjpeg" | tar -zx >> $INSTALL_LOG 2>&1
		mv jpeg-$LIBJPEG_VERSION "$libjpeg_dir"
		write_check
		cd "$libjpeg_dir"
		LDFLAGS="$LDFLAGS -L${INSTALL_DIR}/lib" CPPFLAGS="$CPPFLAGS -I${INSTALL_DIR}/include" RANLIB=$RANLIB ./configure \
		--prefix="$INSTALL_DIR" \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$libjpeg_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..


	HAS_LIBJPEG="--with-jpeg-dir=$INSTALL_DIR"
	# HAS_LIBJPEG="--with-jpeg"
	write_done
}

function build_libxml2 {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library libxml2 "$LIBXML_VERSION"
	local libxml2_dir="./libxml2-$LIBXML_VERSION"
	if cant_use_cache "$libxml2_dir"; then
		rm -rf "$libxml2_dir"
		write_download
		download_file "https://gitlab.gnome.org/GNOME/libxml2/-/archive/v$LIBXML_VERSION/libxml2-v$LIBXML_VERSION.tar.gz" "libxml2" | tar -xz >> $INSTALL_LOG 2>&1
		mv libxml2-v$LIBXML_VERSION "$libxml2_dir"
		write_check
		cd "$libxml2_dir"
		# sed -i.bak 's{libtoolize --version{"$LIBTOOLIZE" --version{' autogen.sh #needed for glibtool on macos
		./autogen.sh --prefix="$INSTALL_DIR" \
			--without-iconv \
			--without-python \
			--without-lzma \
			--with-zlib="$INSTALL_DIR" \
			--config-cache \
			$EXTRA_FLAGS \
			$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$libxml2_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_libzip {
	#libzip
	if [ "$DO_STATIC" == "yes" ]; then
		local CMAKE_LIBZIP_EXTRA_FLAGS="-DBUILD_SHARED_LIBS=OFF"
	else
		local CMAKE_LIBZIP_EXTRA_FLAGS="-DBUILD_SHARED_LIBS=OFF"
	fi

	write_library libzip "$LIBZIP_VERSION"
	local libzip_dir="./libzip-$LIBZIP_VERSION"
	if cant_use_cache "$libzip_dir"; then
		rm -rf "$libzip_dir"
		write_download
		download_file "https://libzip.org/download/libzip-$LIBZIP_VERSION.tar.gz" "libzip" | tar -zx >> $INSTALL_LOG 2>&1
		write_check
		cd "$libzip_dir"

		#we're using OpenSSL for crypto
		cmake . \
			-DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
			-DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
			-DCMAKE_INSTALL_LIBDIR=lib \
			$CMAKE_LIBZIP_EXTRA_FLAGS \
			$CMAKE_GLOBAL_EXTRA_FLAGS \
			-DBUILD_TOOLS=OFF \
			-DBUILD_REGRESS=OFF \
			-DBUILD_EXAMPLES=OFF \
			-DBUILD_DOC=OFF \
			-DENABLE_BZIP2=OFF \
			-DENABLE_COMMONCRYPTO=OFF \
			-DENABLE_GNUTLS=OFF \
			-DENABLE_MBEDTLS=OFF \
			-DENABLE_LZMA=OFF \
			-DENABLE_ZSTD=OFF >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$libzip_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

# Normal: local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"

function build_sqlite3 {
	if [ "$DO_STATIC" == "yes" ]; then
		local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		# clang-15: error: no such file or directory
		local EXTRA_FLAGS="--enable-shared=yes --enable-static=no"
		# local EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	fi

	write_library sqlite3 "$SQLITE3_VERSION"
	local sqlite3_dir="./sqlite3-$SQLITE3_VERSION"

	if cant_use_cache "$sqlite3_dir"; then
		rm -rf "$sqlite3_dir"
		write_download
		download_file "https://www.sqlite.org/$SQLITE3_YEAR/sqlite-autoconf-$SQLITE3_VERSION.tar.gz" "sqlite3" | tar -zx >> $INSTALL_LOG 2>&1
		mv sqlite-autoconf-$SQLITE3_VERSION "$sqlite3_dir" >> $INSTALL_LOG 2>&1
		write_check
		cd "$sqlite3_dir"
		LDFLAGS="$LDFLAGS -L${INSTALL_DIR}/lib" CPPFLAGS="$CPPFLAGS -I${INSTALL_DIR}/include" RANLIB=$RANLIB ./configure \
		--prefix="$INSTALL_DIR" \
		--disable-dependency-tracking \
		--enable-static-shell=no \
		$EXTRA_FLAGS \
		$CONFIGURE_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$sqlite3_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

function build_ext_pmmpthread {
	if [ "$DO_STATIC" == "yes" ]; then
		_EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		_EXTRA_FLAGS="--enable-static=no --enable-shared=yes"
	fi

	write_out pmmpthread "$EXT_PMMPTHREAD_VERSION"
	cd "$BUILD_DIR/php/ext"
	local pmmpthread_dir="./pmmpthread"

	if cant_use_cache "$pmmpthread_dir"; then
		write_check
		cd "$pmmpthread_dir"
		$INSTALL_DIR/bin/phpize  # lol, you need php to build php -_-
		RANLIB=$RANLIB ./configure \
		--with-php-config="$INSTALL_DIR/bin/php-config" \
		--prefix="$INSTALL_DIR" \
		$_EXTRA_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$pmmpthread_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	#if [ "$DO_STATIC" != "yes" ]; then
	#	rm -f "$INSTALL_DIR/lib/pthreads.la"
	#fi

	write_done
}

function build_ext_pthreads {
	if [ "$DO_STATIC" == "yes" ]; then
		_EXTRA_FLAGS="--enable-static=yes --enable-shared=no"
	else
		_EXTRA_FLAGS="--enable-static=no --enable-shared=yes"
	fi

	write_out pthreads "$EXT_PTHREADS_VERSION"
	cd "$BUILD_DIR/php/ext"
	local pthreads_dir="./pthreads"

	if cant_use_cache "$pthreads_dir"; then
		write_check
		cd "$pthreads_dir"
		$INSTALL_DIR/bin/phpize  # lol, you need php to build php -_-
		RANLIB=$RANLIB ./configure \
		--with-php-config="$INSTALL_DIR/bin/php-config" \
		--prefix="$INSTALL_DIR" \
		$_EXTRA_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$pthreads_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	#if [ "$DO_STATIC" != "yes" ]; then
	#	rm -f "$INSTALL_DIR/lib/pthreads.la"
	#fi

	write_done
}

function build_libdeflate {
	write_library libdeflate "$LIBDEFLATE_VERSION"
	local libdeflate_dir="./libdeflate-$LIBDEFLATE_VERSION"

	if [ "$DO_STATIC" == "yes" ]; then
		local CMAKE_LIBDEFLATE_EXTRA_FLAGS="-DLIBDEFLATE_BUILD_STATIC_LIB=ON -DLIBDEFLATE_BUILD_SHARED_LIB=OFF"
	else
		local CMAKE_LIBDEFLATE_EXTRA_FLAGS="-DLIBDEFLATE_BUILD_STATIC_LIB=OFF -DLIBDEFLATE_BUILD_SHARED_LIB=ON"
	fi

	if cant_use_cache "$libdeflate_dir"; then
		rm -rf "$libdeflate_dir"
		write_download
		# FIXME: Use new funcs.. & add option to choose between ext-libdeflate & libdeflate
		download_file "https://github.com/ebiggers/libdeflate/archive/$LIBDEFLATE_VERSION.tar.gz" "libdeflate" | tar -zx >> $INSTALL_LOG 2>&1
		cd "$libdeflate_dir"
		write_check
		cmake . \
			-DCMAKE_INSTALL_PREFIX="$INSTALL_DIR" \
			-DCMAKE_PREFIX_PATH="$INSTALL_DIR" \
			-DCMAKE_INSTALL_LIBDIR=lib \
			$CMAKE_GLOBAL_EXTRA_FLAGS \
			-DLIBDEFLATE_BUILD_GZIP=OFF \
			$CMAKE_LIBDEFLATE_EXTRA_FLAGS >> $INSTALL_LOG 2>&1
		write_compile
		make -j $THREADS >> $INSTALL_LOG 2>&1 && mark_cache
	else
		write_caching
		cd "$libdeflate_dir"
	fi
	write_install
	make install >> $INSTALL_LOG 2>&1
	cd ..
	write_done
}

