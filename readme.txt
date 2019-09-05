=====================================================
See DOCS/RZ-N1D-System-Setup-Tutorial for details
===================================================== 
This package is a build environment for U-Boot, Linux, for building a root file sytem, and cross-compiling added applications.

This package includes a build-script, build.sh, which downloads, adds patches, and builds U-Boot, Buildroot, Linux. It also downloads a crosscompiler, installs it, and sets up the environment so that you can cross-compile the kernel for ARM (the RZ/N1 A7) and your own linux applications. It does some other things aswell.

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
