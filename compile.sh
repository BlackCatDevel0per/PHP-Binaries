#!/usr/bin/env bash

# FIXME: Update some libs! For examples first look at aur php73/74 package
[ -z "$PHP_VERSION" ] && PHP_VERSION="7.3.33"
# [ -z "$PHP_VERSION" ] && PHP_VERSION="7.3.23"

PHP_MAJOR_VERSION=$(echo $PHP_VERSION | cut -d. -f-2)
PHP_PATCH_VERSION=$(echo $PHP_VERSION | cut -d '.' -f 3)

echo "[PocketMine] PHP compiler for Linux, MacOS and Android"
DIR="$(pwd)"

SCRIPT_COMPONENTS="$DIR/compile"
SCRIPT_CONF="$SCRIPT_COMPONENTS/conf"
SCRIPT_PHP_CONFS="$SCRIPT_CONF/php_confs"

PHP_CONF_DEF="$SCRIPT_CONF/php_def"
PHP_CONF="$SCRIPT_PHP_CONFS/$PHP_MAJOR_VERSION"
PHP_PATCHES_DIR="$DIR/patches"
PHP_PATCHES="$PHP_PATCHES_DIR/$PHP_MAJOR_VERSION"

SCRIPT_LIBS_VERSIONS="$SCRIPT_CONF/libs_versions"
# Versions vars of libs
source "$SCRIPT_LIBS_VERSIONS/$PHP_MAJOR_VERSION"

# Logging messages funcs
source "$SCRIPT_COMPONENTS/messages.sh"

BASE_BUILD_DIR="$DIR/install_data"
#libtool and autoconf have a "feature" where it looks for install.sh/install-sh in ./ ../ and ../../
#this extra subdir makes sure that it doesn't find anything it's not supposed to be looking for.
BUILD_DIR="$BASE_BUILD_DIR/subdir"
LIB_BUILD_DIR="$BUILD_DIR/lib"
INSTALL_DIR="$DIR/bin/php7"

INSTALL_LOG="$DIR/install.log"
PHP_INI="$INSTALL_DIR/bin/php.ini"

date > $INSTALL_LOG 2>&1
uname -a >> $INSTALL_LOG 2>&1
write_info "Checking dependencies"

# Helper funcs like cache ops, check dependencies, downloading
source "$SCRIPT_COMPONENTS/pm_helpers.sh"

# Configuration vars for PM dependencies
source "$SCRIPT_COMPONENTS/pm_conf.sh"

check_dependencies

# Check set compiler vars (clang+llvm can't compile some dependencies and not recommended to use for current time..)
# TODO: Support some other compilers..
if [ "$USE_COMPILER" == "clang" ]; then
	write_info "Using clang+llvm & ccache"
	export LD=lld
	export CC="ccache clang"
	export CXX="ccache clang++"
	export AR="ccache llvm-ar"
	export AS="ccache llvm-as"
	export RANLIB=llvm-ranlib
elif [ "$USE_COMPILER" == "gcc" ]; then
	write_info "Using gcc.."
	export LD="ld"
	export CC="ccache gcc"
	export CXX="ccache g++"
	export AR="ccache gcc-ar"
	export AS="ccache gcc-as"
	export RANLIB=gcc-ranlib
fi

# Check compiler & etc.
source "$SCRIPT_COMPONENTS/pm_check.sh"

# PHP 7
write_out "PHP" "downloading $PHP_VERSION..."

# if from github
# download_file "https://github.com/php/php-src/archive/php-$PHP_VERSION.tar.gz" "php" | tar -zx >> $INSTALL_LOG 2>&1
# mv php-src-php-$PHP_VERSION php
# If from php.net
download_file "https://php.net/distributions/php-$PHP_VERSION.tar.xz" "php" | tar -Jx >> $INSTALL_LOG 2>&1
mv php-$PHP_VERSION php

# Download some PM extensions..
source "$SCRIPT_COMPONENTS/pm_dload_ext.sh"
# Build functions for PM dependencies
source "$SCRIPT_COMPONENTS/pm_build_funcs.sh"
# Build PM dependencies (libs)
source "$SCRIPT_COMPONENTS/pm_build_deps.sh"

# PHP sources configuration under build
source "$SCRIPT_COMPONENTS/php_conf.sh"

# Build sources..
make -j $THREADS >> $INSTALL_LOG 2>&1
write_install
make install >> $INSTALL_LOG 2>&1

# Just print configure options
$INSTALL_DIR/bin/php-config --configure-options >> $INSTALL_LOG 2>&1

# Generate php.ini file
source "$SCRIPT_COMPONENTS/php_gen_ini.sh"

# Post processing after build (for other os..)
source "$SCRIPT_COMPONENTS/php_postproc.sh"

cleanup

date >> $INSTALL_LOG 2>&1
write_out "PocketMine" "You should start the server now using \"./start.sh\"."
write_out "PocketMine" "If it doesn't work, please send the \"install.log\" file to the Bug Tracker."
write_out "PocketMine" "Don't forget to run fix_ext_dir.sh to fix extensions load errors!"  # TODO: mb add fix/check to start.sh

