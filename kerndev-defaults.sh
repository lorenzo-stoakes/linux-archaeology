#!/bin/bash
set -e; set -o pipefail

# Default to host arch.
export arch=${KERNDEV_ARCH:-$(uname -m)}
case $arch in
i386)
	export musl_flags="CFLAGS=-m32"
	export arch_patches="build32"
	export busybox_arch=i586
	# Versions above this just die on init.
	export busybox_version=1.19.0

	;;
"x86_64")
	export busybox_arch=x86_64
	export busybox_version="."
	;;
*)
	fatal "Unknown architecture $arch."
	;;
esac

export max_part_path=/sys/module/loop/parameters/max_part
export images_dir=$HOME/kerndev-images
export mount_dir=$images_dir/disk
export image_filename=rootfs_2.4.22.$arch.img
export image_path=$images_dir/$image_filename
export mbr_path=/usr/lib/syslinux/bios/mbr.bin
export image_size_mb=2048
export qemu_mem=4G
export bzImage_rel_path=arch/$arch/boot/bzImage
export default_linux_dir=$HOME/linux-historical
