#!/bin/bash
set -e; set -o pipefail

function push()
{
	pushd $1 >/dev/null
}

function pop()
{
	popd &>/dev/null || true
}

function error()
{
	echo $@ >&2
}

function fatal()
{
	error $@
	exit 1
}

function check_commands()
{
	for cmd in $@; do
		hash "$cmd" 2> /dev/null || fatal "Missing command '$1'.";
	done
}

function load_loop()
{
	modprobe loop max_part=15
}

# TODO This is _too_ silent. Report errors when appropriate.
function unmount_image()
{
	loopdev=$1

	# If not mounted, nothing to do.
	(mount | grep --quiet "$loopdev") || return 0

	# Make sure we aren't in the mounted directory, otherwise unmount will
	# fail.
	[[ "$PWD" = "$(realpath $mount_dir)" ]] && pop || true

	sync
	umount $mount_dir

	(losetup --all | grep --quiet "$loopdev") || return 0
	losetup --detach $loopdev
}

# Replaces the current script with an elevated version of itself.
# If parameters need to be preserved, they need to be passed thorough via $@.
function elevate()
{
	if [[ $EUID != 0 ]]; then
		exec sudo -E $0 $@
		exit $?
	fi
}

function check_reload_loop()
{
	if [[ ! -e $max_part_path ]]; then
		error Loopback module not loaded, loading...

		load_loop
	elif (($(< $max_part_path) < 2)); then
		error Loopback module has too few partitions supported, attempting to reload...

		modprobe --remove loop
		load_loop
	fi
}

function say_image_loop()
{
	losetup --associated $image_path | awk '{print $1}' | tr --delete ':'
}

function mount_image_loop()
{
	losetup --find $image_path 2>/dev/null
	# Output mounted loop device partition.
	say_image_loop
}

function mount_looped_image()
{
	partdev=$1

	mkdir -p $mount_dir
	mount $partdev $mount_dir
}

function mount_image()
{
	loopdev=$(mount_image_loop)
	mount_looped_image ${loopdev}p1

	# Output loop device so we can cleanup.
	echo $loopdev
}

# Pretty crappy check but a decent enough estimate :)
function check_kernel_dir()
{
	target_dir=$1

	[[ -f "$target_dir/REPORTING-BUGS" ]] || \
		fatal "$PWD doesn't look like a kernel tree."
}

function do_parted()
{
	parted --script $image_path $@ 2>/dev/null
}

function reverse_list()
{
	rev_chr=$(echo "$@" | rev)

	for word in $rev_chr; do
		    printf "%s " "$(echo $word | rev)"
	done
	printf "\n"
}

function get_make_jobs()
{
	# Ref: http://stackoverflow.com/a/6481016
	cores=$(grep -c ^processor /proc/cpuinfo)
	# A good jobs value is cores+1.
	echo $((cores+1))
}
