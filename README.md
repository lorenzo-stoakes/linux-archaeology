# Linux Archaeology

This repository contains a series of tools and instructions for the purposes of
working with ancient linux kernels.

It's useful to use the [linux-historical][linux-historical] repo in conjunction
with these scripts in order to get hold of a specific old version of linux.

## 2.4.22

__NOTE:__ These steps may work on other version of the kernel also however
[2.4.22][linux-2.4.22] is the only one I've tried them against.

1. Get hold of the kernel at [2.4.22][linux-2.4.22].

2. Run `make menuconfig` and set up the kernel as you require.

3. Run `kerndev-build-2.4.22` either from the kernel directory or if elsewhere,
   specify the kernel directory as the first parameter. The script will
   automatically obtain and install GCC versions 3.2.3 and 3.4.6 (3.2.3 is what
   we need for the kernel, 3.4.6 is needed to compile 3.2.3.) - the compilers
   will be installed in `/opt/gcc-3.2.3` and `/opt/gcc-3.4.6` and receive
   `-3.2.3` and `-3.4.6` suffixes to ensure no conflict with existing GCC
   installs.

__WARNING:__ Installing GCC 3.2.3 and 3.4.6 requires `sudo` and I disclaim any
rage incidents that come out of a bug which loses you data :)

[linux-historical]:https://github.com/lorenzo-stoakes/linux-historical
[linux-2.4.22]:https://github.com/lorenzo-stoakes/linux-historical/tree/v2.4.22
