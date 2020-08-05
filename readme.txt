=====================================================
See DOCS/RZ-N1D-System-Setup-Tutorial for details
===================================================== 
This package is a build environment for the A7-cores for U-Boot, Linux, building a root file system with Buildroot, and for cross-compiling user applications. 

It also explains how to use and debug the CM3-core. (The HWOS-side of the RZ/N).

-----------------------------------------------------
The package includes a build-script, build.sh, which downloads, adds patches, and builds U-Boot, Buildroot, Linux. It also downloads a crosscompiler, installs it, and sets up the environment so that you can cross-compile the kernel for ARM (the RZ/N1 A7) and your own linux applications. It does some other things aswell.

The build script build.sh helps with many different tasks; such as downloading, updating, building, and configuring the following.
  •	U-Boot.
  •	Buildroot. To create a root file system, incorporating Busybox to provide a small powerful linux command set.
  •	The linux kernel (based on the configuration rzn1_defconfig) 
  •	Cross-compiler (arm-linux-gnueabihf by default) Sets you up to cross-compile code for the RZ/N A7 core with minimum effort.
  •	Host DFU utility

Follow the menu by just typing 
>./build.sh
It will do the following automatically for you when you run it. 
•	Sets up build environment variables
•	Downloads source code
•	Applies patches to source code

-----------------------------------------------------
These are  env. vars setup for Buildroot and for cross-compiling. (Examples.)
ROOTDIR=~//rzn_dev_setup/rzn1_linux-4.19_bsp
OUTDIR=~//rzn_dev_setup/rzn1_linux-4.19_bsp/output
PATH=~//rzn_dev_setup/rzn1_linux-4.19_bsp/output/buildroot-2019.02.6/output/host/usr/bin:~//bin:~//.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
PWD=~//rzn_dev_setup/rzn1_linux-4.19_bsp
TOOLCHAIN_DIR=~//rzn_dev_setup/rzn1_linux-4.19_bsp/output/buildroot-2019.02.6/output/host/usr
ARCH=arm
CROSS_COMPILE=arm-linux-gnueabihf-
PROFILEHOME=~//RZN
BUILDROOT_DIR=~//rzn_dev_setup/rzn1_linux-4.19_bsp/output/buildroot-2019.02.6
-----------------------------------------------------
