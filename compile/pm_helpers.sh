#!/usr/bin/env bash

function cant_use_cache {
	if [ -f "$1/.compile.sh.cache" ]; then
		return 1
	else
		return 0
	fi
}
function mark_cache {
	touch "./.compile.sh.cache"
}

# Check dependencies
function check_dependencies {
	if [ "$USE_COMPILER" == "clang" ]; then
		COMPILE_SH_DEPENDENCIES=( make autoconf automake libtool m4 getconf gzip bzip2 bison ccache clang llvm-ranlib git cmake pkg-config re2c )
	elif [ "$USE_COMPILER" == "gcc" ]; then
		COMPILE_SH_DEPENDENCIES=( make autoconf automake libtool m4 getconf gzip bzip2 bison ccache g++ git cmake pkg-config re2c )
	else
		write_error "Only supported gcc, clang+llvm with ccache! Not `$USE_COMPILER`"
		exit 1
	fi
	ERRORS=0
	for(( i=0; i<${#COMPILE_SH_DEPENDENCIES[@]}; i++ ))
	do
		type "${COMPILE_SH_DEPENDENCIES[$i]}" >> $INSTALL_LOG 2>&1 || { write_error "Please install \"${COMPILE_SH_DEPENDENCIES[$i]}\""; ((ERRORS++)); }
	done

	type wget >> $INSTALL_LOG 2>&1 || type curl >> $INSTALL_LOG || { echo >&2 "[ERROR] Please install \"wget\" or \"curl\""; ((ERRORS++)); }

	if [ "$(uname -s)" == "Darwin" ]; then
		type glibtool >> $INSTALL_LOG 2>&1 || { echo >&2 "[ERROR] Please install GNU libtool"; ((ERRORS++)); }
		export LIBTOOL=glibtool
		export LIBTOOLIZE=glibtoolize
		export PATH="/opt/homebrew/opt/bison/bin:$PATH"
		[[ $(bison --version) == "bison (GNU Bison) 3."* ]] || { echo >&2 "[ERROR] MacOS bundled bison is too old. Install bison using Homebrew and update your PATH variable according to its instructions before running this script."; ((ERRORS++)); }
	else
		type libtool >> $INSTALL_LOG 2>&1 || { echo >&2 "[ERROR] Please install \"libtool\" or \"libtool-bin\""; ((ERRORS++)); }
		export LIBTOOL=libtool
		export LIBTOOLIZE=libtoolize
	fi

	if [ $ERRORS -ne 0 ]; then
		exit 1
	fi
}

#Needed to use aliases
shopt -s expand_aliases
type wget >> $INSTALL_LOG 2>&1
if [ $? -eq 0 ]; then
	alias _download_file="wget --no-check-certificate -nv -O -"
else
	type curl >> $INSTALL_LOG 2>&1
	if [ $? -eq 0 ]; then
		alias _download_file="curl --insecure --silent --show-error --location --globoff"
		# alias _download_file="wget --no-check-certificate -nv -O -"
	else
		write_error "curl or wget not found"
		exit 1
	fi
fi

DOWNLOAD_CACHE=""

function download_file {
	local url="$1"
	local prefix="$2"
	local cached_filename="$prefix-${url##*/}"

	if [[ "$DOWNLOAD_CACHE" != "" ]]; then
		if [[ ! -d "$DOWNLOAD_CACHE" ]]; then
			mkdir "$DOWNLOAD_CACHE" >> $INSTALL_LOG 2>&1
		fi
		if [[ -f "$DOWNLOAD_CACHE/$cached_filename" ]]; then
			write_info "Cache hit for URL: $url" >> $INSTALL_LOG
		else
			write_info "Downloading file to cache: $url" >> $INSTALL_LOG
			_download_file "$1" > "$DOWNLOAD_CACHE/$cached_filename" 2>> $INSTALL_LOG 2>&1
		fi
		cat "$DOWNLOAD_CACHE/$cached_filename" 2>> $INSTALL_LOG
	else
		write_info "Downloading non-cached file: $url" >> $INSTALL_LOG 2>&1
		_download_file "$1" 2>> $INSTALL_LOG
	fi
}

# PECL libraries

# 1: extension name
# 2: extension version
# 3: URL to get .tar.gz from
# 4: Name of extracted directory to move
function get_extension_tar_gz {
	write_download_ext $1 $2
	download_file "$3" "php-ext-$1" | tar -zx >> $INSTALL_LOG 2>&1
	mv "$4" "$BUILD_DIR/php/ext/$1"
	write_done
}

# 1: extension name
# 2: extension version
# 3: github user name
# 4: github repo name
function get_github_extension {
	# if is github tag will remove `v` prefix under commit tag it will add it.
	local tags_info=$(curl -s "https://api.github.com/repos/$3/$4/tags")
	local tag_version=$(echo "$tags_info" | grep -E "\"name\":\s*\"v?$2\"" | head -n 1)
	# tag_version=$(echo $tag_version | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')  # remove tabs..
	local tag_prefix=""
	if [[ $tag_version == *v* ]]; then
		tag_prefix="v"
	fi

	get_extension_tar_gz "$1" "$2" "https://github.com/$3/$4/archive/$tag_prefix$2.tar.gz" "$4-$2"
}

# 1: extension name
# 2: extension version
function get_pecl_extension {
	get_extension_tar_gz "$1" "$2" "http://pecl.php.net/get/$1-$2.tgz" "$1-$2"
}

function cleanup {
	# Clean build dir
	cd "$DIR"
	if [ "$DO_CLEANUP_BUILD" == "yes" ]; then
		write_info "Cleaning build dir..."
		rm -rf "$BUILD_DIR" >> $INSTALL_LOG 2>&1
	fi

	# Cleanup distribution dir
	if [ "$DO_CLEANUP" == "yes" ]; then
		write_info "Cleaning up..."
		rm -f "$INSTALL_DIR/bin/curl"* >> $INSTALL_LOG 2>&1
		rm -f "$INSTALL_DIR/bin/curl-config"* >> $INSTALL_LOG 2>&1
		rm -f "$INSTALL_DIR/bin/c_rehash"* >> $INSTALL_LOG 2>&1
		rm -f "$INSTALL_DIR/bin/openssl"* >> $INSTALL_LOG 2>&1
		# mb need just disable man pages..
		rm -rf "$INSTALL_DIR/man" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/php/man" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/share/man" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/share/doc" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/share/gtk-doc" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/php" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/misc" >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/lib/"*.a >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/lib/"*.la >> $INSTALL_LOG 2>&1
		rm -rf "$INSTALL_DIR/include" >> $INSTALL_LOG 2>&1
		write_done 2
	fi
}

function al2ini {
	echo "$1" >> "$PHP_INI"
}

