#!/bin/bash
set -e; set -o pipefail

function push()
{
	pushd $1 >/dev/null
}

function pop()
{
	popd >/dev/null
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

function unmount_image()
{
	loopdev=$1

	push $images_dir

	umount disk 2>/dev/null || true
	losetup --detach $loopdev 2>/dev/null || true

	pop
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
	if [ ! -e $max_part_path ]; then
		error Loopback module not loaded, loading...

		load_loop
	elif (($(< $max_part_path) < 2)); then
		error Loopback module has too few partitions supported, attempting to reload...

		modprobe --remove loop
		load_loop
	fi
}

function mount_image_loop()
{
	losetup --find $image_path 2>/dev/null
	# Output mounted loop device partition.
	losetup --associated $image_path | awk '{print $1}' | tr --delete ':'
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
