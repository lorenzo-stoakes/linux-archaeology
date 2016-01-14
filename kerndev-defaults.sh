#!/bin/bash
set -e; set -o pipefail

export max_part_path=/sys/module/loop/parameters/max_part
export bzImage_rel_path=arch/x86_64/boot/bzImage
export images_dir=$HOME/kerndev-images
export mount_dir=$images_dir/disk
export image_filename=rootfs_2.4.22.img
export image_path=$images_dir/$image_filename
export mbr_path=/usr/lib/syslinux/bios/mbr.bin
export image_size_mb=2048
export qemu_mem=4G
