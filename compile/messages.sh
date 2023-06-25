function write_out {
	echo "[$1] $2"
}

function write_info {
	write_out INFO "$1" >&2
}

function write_warning {
	write_out WARNING "$1" >&2
}

function write_error {
	write_out ERROR "$1" >&2
}

function write_opt {
	write_out opt "$1" >&2
}

function write_status {
	echo -n " $1..."
}

function write_library {
  echo -n "[$1 $2]"
}

function write_download_ext {
  echo -n "  $1: downloading $2..."
}

function write_caching {
  write_status "using cache"
}

function write_download {
	write_status "downloading"
}
function write_check {
	write_status "checking"
}
function write_compile {
	write_status "compiling"
}
function write_install {
	write_status "installing"
}

function is_int {
  [[ "$1" =~ ^[0-9]+$ ]]
}

function write_done {
	local echo_new_line="${1:-0}"
	if is_int $echo_new_line && [ $echo_new_line != 2 ]; then
		echo -n " done!"
	else
		echo "done!"
	fi
	if is_int $echo_new_line && [ $echo_new_line != 1 ]; then
		echo
	fi
}

