#!/usr/bin/env bash

# Download extensions
cd "$BUILD_DIR/php"
write_out "PHP" "Downloading additional extensions..."


get_github_extension "yaml" "$EXT_YAML_VERSION" "php" "pecl-file_formats-yaml"
#get_pecl_extension "yaml" "$EXT_YAML_VERSION"

get_github_extension "igbinary" "$EXT_IGBINARY_VERSION" "igbinary" "igbinary"

get_github_extension "ds" "$EXT_DS_VERSION" "php-ds" "ext-ds"

get_github_extension "recursionguard" "$EXT_RECURSIONGUARD_VERSION" "pmmp" "ext-recursionguard"

write_download_ext "crypto" "$EXT_CRYPTO_VERSION"
git clone https://github.com/bukka/php-crypto.git "$BUILD_DIR/php/ext/crypto" >> $INSTALL_LOG 2>&1
write_check
cd "$BUILD_DIR/php/ext/crypto"
git checkout "$EXT_CRYPTO_VERSION" >> $INSTALL_LOG 2>&1
git submodule update --init --recursive >> $INSTALL_LOG 2>&1
cd "$BUILD_DIR"
write_done

get_github_extension "leveldb" "$EXT_LEVELDB_VERSION" "pmmp" "php-leveldb"

get_github_extension "pmmpthread" "$EXT_PMMPTHREAD_VERSION" "pmmp" "ext-pmmpthread"
if [ "$PM_VERSION_MAJOR" -ge 5 ]; then
	get_github_extension "chunkutils2" "$EXT_CHUNKUTILS2_VERSION" "pmmp" "ext-chunkutils2"
	CHUNKUTILS_EXT_FLAG="--enable-chunkutils2"

	THREAD_EXT_FLAGS="--enable-pmmpthread"
else
	get_github_extension "pocketmine-chunkutils" "$EXT_POCKETMINE_CHUNKUTILS_VERSION" "dktapps" "PocketMine-C-ChunkUtils"
	CHUNKUTILS_EXT_FLAG="--enable-pocketmine-chunkutils"

	# You can use older original pthreads, but it's so old & so buggy..
	THREAD_EXT_FLAGS="--enable-pthreads"
fi

# clang-15: error: linker command failed with exit code 1 (use -v to see invocation)
# get_github_extension "libdeflate" "$EXT_LIBDEFLATE_VERSION" "pmmp" "ext-libdeflate"

get_github_extension "morton" "$EXT_MORTON_VERSION" "pmmp" "ext-morton"

get_github_extension "xxhash" "$EXT_XXHASH_VERSION" "pmmp" "ext-xxhash"

# arraydebug just for debug
# get_github_extension "arraydebug" "$EXT_ARRAYDEBUG_VERSION" "pmmp" "ext-arraydebug"

