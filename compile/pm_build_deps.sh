cd "$LIB_BUILD_DIR"

if [ "$COMPILE_FANCY" == "yes" ]; then
	# build_ncurses  # don't need
	build_readline
fi

# Configure advanced extensions
build_zlib
build_libdeflate  # clang-15: error: linker command failed with exit code 1 (use -v to see invocation) & included in php v7.3
# build_libzip  # already included in php

build_gmp
build_openssl
build_curl
build_yaml
build_leveldb

# libgd
if [ "$COMPILE_GD" == "yes" ]; then
	# For libgd
	build_libpng
	build_libjpeg

	# HAS_GD="--enable-gd"
	# HAS_GD="--with-gd=$BUILD_DIR/php/ext/gd/libgd"  # old arg for php under v7.3
	if [ "$DO_STATIC" == "yes" ]; then
		HAS_GD="--with-gd=static"  # for php v7.3+
	else
		HAS_GD="--with-gd=shared"  # for php v7.3+
	fi
else
	HAS_LIBPNG=""
	HAS_LIBJPEG=""
	HAS_GD=""
fi

build_libxml2
build_sqlite3

