COMPILE_FOR_ANDROID=no
HAVE_MYSQLI="--enable-mysqlnd --with-mysqli=mysqlnd"
COMPILE_TARGET=""
IS_CROSSCOMPILE="no"
IS_WINDOWS="no"
DO_OPTIMIZE="yes"
OPTIMIZE_TARGET=""
DO_SHARED="yes"
DO_STATIC="no"  # some libs..?
USE_COMPILER="gcc"  # gcc or clang+llvm & ccache  # mv need rename var..
DO_CLEANUP_BUILD="no"  # set yes for autoremove build in `install_data`
DO_CLEANUP="yes"  # set yes for autoremove
COMPILE_DEBUG="no"

HAVE_NCURSES="--without-ncurses"
HAVE_READLINE="--without-readline"

HAVE_OPCACHE="yes"  # TODO: Use other jit implementation.. 
HAVE_OPCACHE_JIT="yes"  # Turn on opcache.jit after built opcache (HAVE_OPCACHE="yes")
HAVE_XDEBUG="no"  # This has a major impact on performance.
FSANITIZE_OPTIONS=""
FLAGS_LTO=""

LD_PRELOAD=""

COMPILE_GD="no"

COMPILE_FANCY="no"

PM_VERSION_MAJOR=""

while getopts "::t:C:j:f:a:P:c:l:h:O:u:srdxfgnJ" OPTION; do

	case $OPTION in
		l)
			mkdir "$OPTARG" 2> /dev/null
			LIB_BUILD_DIR="$(cd $OPTARG; pwd)"
			write_opt "Reusing previously built libraries in $LIB_BUILD_DIR if found"
			write_warning "Reusing previously built libraries may break if different args were used!"
			;;
		c)
			mkdir "$OPTARG" 2> /dev/null
			DOWNLOAD_CACHE="$(cd $OPTARG; pwd)"
			write_opt "Caching downloaded files in $DOWNLOAD_CACHE and reusing if available"
			;;
		t)
			write_opt "Set target to $OPTARG"
			COMPILE_TARGET="$OPTARG"
			;;
		C)
			write_opt "Set compiler to $OPTARG"
			USE_COMPILER="$OPTARG"
			;;
		j)
			write_opt "Set make threads to $OPTARG"
			THREADS="$OPTARG"
			;;
		r)
			write_opt "Will compile readline and ncurses"
			COMPILE_FANCY="yes"
			;;
		d)
			write_opt "Will compile everything with debugging symbols, will not remove sources"
			COMPILE_DEBUG="yes"
			DO_CLEANUP="no"
			CFLAGS="$CFLAGS -g"
			CXXFLAGS="$CXXFLAGS -g"
			;;
		x)
			write_opt "Doing cross-compile"
			IS_CROSSCOMPILE="yes"
			;;
		s)
			write_opt "Will compile everything statically"
			DO_STATIC="yes"
			DO_SHARED="no"
			CFLAGS="$CFLAGS -static"  ###
			;;
		f)
			write_opt "Enabling abusive optimizations $OPTARG..."
			DO_OPTIMIZE="yes"
			OPTIMIZE_TARGET="$OPTARG"
			;;
		g)
			write_opt "Will enable GD2"
			COMPILE_GD="yes"  # Fails.. mb need some deps...
			;;
		n)
			write_opt "Will not remove sources after completing compilation"
			DO_CLEANUP="no"
			;;
		b)
			write_opt "Will not remove builds after completing compilation"
			DO_CLEANUP_BUILD="no"
			;;
		u)
			write_opt "march is $OPTARG"
			march="$OPTARG"
			;;

		h)
			write_opt "mtune is $OPTARG"
			mtune="$OPTARG"
			;;
		a)
			write_opt "Will pass -fsanitize=$OPTARG to compilers and linkers"
			FSANITIZE_OPTIONS="$OPTARG"
			;;
		P)
			PM_VERSION_MAJOR="$OPTARG"
			[ "$PM_VERSION_MAJOR" != "" ] && write_opt "PocketMine-MP major version is $OPTARG"
			;;
		J)
			write_opt "Compiling JIT support in OPcache (unstable)"
			HAVE_OPCACHE_JIT="yes"
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			exit 1
			;;
	esac
done

