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

function fatal()
{
	echo $@ >&2
	exit 1
}

function check_md5()
{
	filename=$1

	expected=$(grep $filename md5.sum | awk '{print $1}')
	actual=$(md5sum $filename | awk '{print $1}')
	rm md5.sum
}

function get_check()
{
	version=$1
	url=ftp://ftp.gnu.org/pub/gnu/gcc/gcc-$version/gcc-core-$version.tar.bz2
	filename=$(basename $url)
	urldir=$(dirname $url)
	md5url=$urldir/md5.sum

	wget --quiet $url
	echo "Attempting to check md5 signature..."
	# More recent gcc's have gpg signatures, skipping checking that for now.
	wget --quiet $md5url && check_md5 $filename || echo "...missing md5sum, skipping."

	[ "$expected" != "$actual" ] && fatal "md5sum mismatch: $actual != $expected" || true

	tar xf $filename
	rm $filename
}

function apply()
{
	target_dir=$1
	patch_name=$2

	patch --quiet --force --directory=$target_dir --strip=1 <$patch_name.diff
}

function config()
{
	version=$1
	build_dir="build-$version"

	mkdir $build_dir && cd $build_dir
	../gcc-$version/configure --quiet --disable-locale --disable-shared \
				  --disable-nls --enable-languages=c \
                                  --prefix=/opt/gcc-$version \
				  --program-suffix="-$version"

	# Remain in the build directory for, well, building :]
}

function build()
{
	# Assumes the current directory is the build directory.

	compiler_version=$1

	# Ref: http://stackoverflow.com/a/6481016
	cores=$(grep -c ^processor /proc/cpuinfo)
	# A good jobs value is cores+1.
	jobs=$((cores+1))

	opts="--jobs=$jobs "
	if [ -n "$compiler_version" ]; then
		compiler_path="/opt/gcc-$compiler_version/bin/gcc-$compiler_version"

		opts+="CC=$compiler_path"
		echo "Compiling with $compiler_version..."
	fi

	make $opts &>/dev/null
}

function installgcc()
{
	# Assumes the current directory is the build directory.

	# Since we've specified a directory prefix and file suffix, this won't
	# interfere with existing gccs.
	sudo make install &>/dev/null
}

function go()
{
	version=$1
	compiler_version=$2

	echo "Retrieving gcc $version..."
	get_check $version

	echo "Applying patch..."
	# We have to fix up a breaking change: struct siginfo is now siginfo_t.
	apply "gcc-$version" "siginfo_$version"

	echo "Configuring..."
	config $version

	echo "Building..."
	build $compiler_version

	echo "Installing..."
	installgcc

	# Now we're done building, leave the build dir.
	cd ..

	echo "gcc $version Done!"
}

tmpdir=$(mktemp --directory)
# See http://stackoverflow.com/a/4774063.
scriptdir=$(cd $(dirname $0); pwd -P)

push $scriptdir/patches
cp siginfo_3.2.3.diff siginfo_3.4.6.diff $tmpdir
pop

push $tmpdir

go 3.4.6
go 3.2.3 3.4.6

popd
