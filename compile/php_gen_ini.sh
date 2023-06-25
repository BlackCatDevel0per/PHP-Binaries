# Fill php.ini
echo -n " generating php.ini..."
trap - DEBUG
TIMEZONE=$(date +%Z)  # FIXME: Incorrect format..
al2ini "memory_limit=1024M"
al2ini "date.timezone=$TIMEZONE"
al2ini "short_open_tag=0"
al2ini "asp_tags=0"
al2ini ";phar.readonly=0"
al2ini "phar.require_hash=1"
al2ini "igbinary.compact_strings=0"
if [[ "$COMPILE_DEBUG" == "yes" ]]; then
	al2ini "zend.assertions=1"
else
	al2ini "zend.assertions=-1"
fi
al2ini "error_reporting=-1"
al2ini "display_errors=1"
al2ini "display_startup_errors=1"
al2ini "recursionguard.enabled=0 ;disabled due to minor performance impact, only enable this if you need it for debugging"

if [ "$HAVE_OPCACHE" == "yes" ]; then
	al2ini "zend_extension=opcache.so"
	al2ini "opcache.enable=1"
	al2ini "opcache.enable_cli=1"
	al2ini "opcache.save_comments=1"
	al2ini "opcache.validate_timestamps=1"
	al2ini "opcache.revalidate_freq=0"
	al2ini "opcache.file_update_protection=0"
	al2ini "opcache.fast_shutdown=0"
	al2ini ";opcache.max_accelerated_files=4096"
	al2ini "opcache.interned_strings_buffer=8"
	al2ini "opcache.memory_consumption=128"
	# al2ini "opcache.optimization_level=0xffffffff"  # old
	al2ini ";opcache.optimization_level=0x7FFFBFFF ; for php under 7.3.0 version"
	al2ini "opcache.optimization_level=0x7FFEBFFF ; https://github.com/php/php-src/blob/53c1b485741f31a17b24f4db2b39afeb9f4c8aba/ext/opcache/Optimizer/zend_optimizer.h"
	if [ "$HAVE_OPCACHE_JIT" == "yes" ]; then
		al2ini ""
		al2ini "; ---- ! WARNING ! ----"
		al2ini "; JIT can provide big performance improvements, but as of PHP $PHP_VERSION it is still unstable. For this reason, it is disabled by default."
		al2ini "; Enable it at your own risk. See https://www.php.net/manual/en/opcache.configuration.php#ini.opcache.jit for possible options."
		al2ini "opcache.jit=on"
		al2ini "opcache.jit_buffer_size=128M"
	fi
fi
if [ "$COMPILE_TARGET" == "mac-"* ]; then
	al2ini ""
	al2ini ";we don't have permission to allocate executable memory on macOS due to not being codesigned"
	al2ini ";workaround this for now by disabling PCRE JIT"
	al2ini "pcre.jit=off"
fi

write_done

# mb need other messages for extensions..

if [[ "$HAVE_XDEBUG" == "yes" ]]; then
	write_library "xdebug" "$EXT_XDEBUG_VERSION"
	get_github_extension "xdebug" "$EXT_XDEBUG_VERSION" "xdebug" "xdebug"
	write_check
	cd "$BUILD_DIR/php/ext/xdebug"
	"$INSTALL_DIR/bin/phpize" >> $INSTALL_LOG 2>&1
	./configure --with-php-config="$INSTALL_DIR/bin/php-config" >> $INSTALL_LOG 2>&1
	write_compile

	make -j4 >> $INSTALL_LOG 2>&1
	write_install
	make install >> $INSTALL_LOG 2>&1
	al2ini ""
	al2ini ";WARNING: When loaded, xdebug 3.2.0 will cause segfaults whenever an uncaught error is thrown, even if xdebug.mode=off. Load it at your own risk."
	al2ini "zend_extension=xdebug.so"
	al2ini ";https://xdebug.org/docs/all_settings#mode"
	al2ini "xdebug.mode=off"
	al2ini "xdebug.start_with_request=yes"
	al2ini ";The following overrides allow profiler, gc stats and traces to work correctly in ZTS"
	al2ini "xdebug.profiler_output_name=cachegrind.%s.%p.%r"
	al2ini "xdebug.gc_stats_output_name=gcstats.%s.%p.%r"
	al2ini "xdebug.trace_output_name=trace.%s.%p.%r"
	write_done
	write_info "Xdebug is included, but disabled by default. To enable it, change 'xdebug.mode' in your php.ini file."
fi

