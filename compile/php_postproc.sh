function relativize_macos_library_paths {
	IFS=$'\n' OTOOL_OUTPUT=($(otool -L "$1"))

	for (( i=0; i<${#OTOOL_OUTPUT[@]}; i++ ))
		do
		CURRENT_DYLIB_NAME=$(echo ${OTOOL_OUTPUT[$i]} | sed 's# (compatibility version .*##' | xargs)
		if [[ "$CURRENT_DYLIB_NAME" == "$INSTALL_DIR/"* ]]; then
			NEW_DYLIB_NAME=$(echo "$CURRENT_DYLIB_NAME" | sed "s{$INSTALL_DIR{@loader_path/..{" | xargs)
			install_name_tool -change "$CURRENT_DYLIB_NAME" "$NEW_DYLIB_NAME" "$1" >> $INSTALL_LOG 2>&1
		elif [[ "$CURRENT_DYLIB_NAME" != "/usr/lib/"* ]] && [[ "$CURRENT_DYLIB_NAME" != "/System/"* ]] && [[ "$CURRENT_DYLIB_NAME" != "@loader_path"* ]] && [[ "$CURRENT_DYLIB_NAME" != "@rpath"* ]]; then
			echo "[ERROR] Detected linkage to non-local non-system library $CURRENT_DYLIB_NAME by $1"
			exit 1
		fi
	done
}

function relativize_macos_all_libraries_paths {
	set +e
	for _library in $(find "$INSTALL_DIR" -name "*.dylib" -o -name "*.so"); do
		relativize_macos_library_paths "$_library"
	done
	set -e
}

if [[ "$(uname -s)" == "Darwin" ]] && [[ "$IS_CROSSCOMPILE" != "yes" ]]; then
	set +e
	install_name_tool -delete_rpath "$INSTALL_DIR/lib" "$INSTALL_DIR/bin/php" >> $INSTALL_LOG 2>&1

	relativize_macos_library_paths "$INSTALL_DIR/bin/php"

	relativize_macos_all_libraries_paths
	set -e
fi

# Build as ext.
# if [ "$PM_VERSION_MAJOR" -ge 5 ]; then
# 	build_ext_pthreads
# else
# 	build_ext_pmmpthread
# fi

# Tests..
# Check opcache work
if [ "$HAVE_OPCACHE" == "yes" ]; then
	set +e
	TEST_OPCACHE=$($INSTALL_DIR/bin/php -r '$ogs = opcache_get_status(); $oe = $ogs["opcache_enabled"]; echo "opcache_enabled: ".$oe."\n";')
	echo $TEST_OPCACHE | grep "opcache_enabled: 1" >> /dev/null && write_warning "OPcache may not work! Please recheck with php -r 'var_dump(opcache_get_status());'"
	# [ $? != 0 ] && write_error "OPcache not work!" && exit 1
	set -e
fi

