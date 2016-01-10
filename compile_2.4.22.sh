#!/bin/bash
set -e; set -o pipefail

target_dir=${1:-$PWD}
# See http://stackoverflow.com/a/4774063.
script_dir=$(cd $(dirname $0); pwd -P)
# Various fixes required to make the kernel compile.
patches="mov_size_fix acpi_function_args_fix build_tool_fix"
# This path will be available once install_gcc3.sh has completed.
gcc_path=/opt/gcc-3.2.3/bin/gcc-3.2.3

function push()
{
	pushd $1 >/dev/null
}

function pop()
{
	popd >/dev/null
}

function fatal()
{
	echo $@ >&2
	exit 1
}

function check_kernel_dir()
{
	[ ! -f REPORTING-BUGS ] && fatal "$PWD doesn't look like a kernel tree." || true
}

function check_config()
{
	[ ! -f .config ] && fatal "Missing .config - run make menuconfig first." || true
}

function install_gcc3()
{
	version=$1

	echo "gcc $version missing, installing..."
	$script_dir/install_gcc3.sh
}

function check_gcc_or_install()
{
	version=$1

	[ ! -d /opt/gcc-$version/bin ] && install_gcc3 $version || true
}

function apply_patch()
{
	patch_path=$1
	extra_opts=$2

	patch $extra_opts --quiet --force --strip=1 <$patch_path
}

function apply_patches()
{
	extra_opts=$1
	patch_dir=$script_dir/patches

	for patch in $patches; do
		path=$patch_dir/$patch.diff
		apply_patch $path $extra_opts
	done
}

function revert_patches()
{
	apply_patches --reverse
}

function mak()
{
	# Ref: http://stackoverflow.com/a/6481016
	cores=$(grep -c ^processor /proc/cpuinfo)
	# A good jobs value is cores+1.
	jobs=$((cores+1))

	make CC=$gcc_path --jobs=$jobs $@ >/dev/null
}

function build_kernel()
{
	# For an older kernel like 2.4.22 we need to make a dependency step
	# first.
	mak dep
	# bzImage is the general compilation target.
	mak bzImage
}

push $target_dir

check_kernel_dir
check_config
check_gcc_or_install 3.2.3

apply_patches
# Revert patches immediately afterwards to get slightly saner diffs.
trap revert_patches EXIT

build_kernel

pop
