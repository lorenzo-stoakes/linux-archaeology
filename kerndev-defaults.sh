#!/bin/bash
set -e; set -o pipefail

# Default to 386, a better supported platform for 2.4.22 :)
export arch=${KERNDEV_ARCH:-i386}

case $arch in
i386)
	export arch_patches="build32"

	;;
"x86_64")
	;;
*)
	fatal "Unknown architecture $arch."
	;;
esac

export max_part_path=/sys/module/loop/parameters/max_part
export images_dir=$HOME/kerndev/qemu-images
export mount_dir=$images_dir/disk
export image_filename=rootfs_2.4.22.$arch.img
export image_path=$images_dir/$image_filename
export mbr_path=/usr/lib/syslinux/bios/mbr.bin
export image_size_mb=2048
export qemu_mem=4G
export bzImage_rel_path=arch/$arch/boot/bzImage
export default_linux_dir=$HOME/kerndev/kernels/historical
export debian_release=sarge
export debian_url=http://archive.debian.org/debian
