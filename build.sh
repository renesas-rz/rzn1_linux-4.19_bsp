#!/bin/bash
#   http://sources.buildroot.net/

# ==========================================================================
# CHANGE HISTORY
#
# CS: Added repo https://github.com/renesas-rz/rzn1_linux.git to kernel sections build and update.
# 
# CS, 10/31/18: Changed U-Boot build section to be acc. to 1.3.1 U-Boot manual. 
#   
# ==========================================================================

# Function: User usage
function usage {
  echo -ne "\033[1;31m" # RED TEXT
  echo -e "\nWhat do you want to build?"
  echo -ne "\033[00m" # END TEXT COLOR
  echo -e "    ./build.sh config                  : Target Board Selection ($BOARD)"
  echo -e ""
  echo -e "    ./build.sh buildroot               : Builds Root File System (and installs toolchain)"
  echo -e "    ./build.sh u-boot                  : Builds u-boot"
  echo -e "    ./build.sh kernel                  : Builds Linux kernel. Default is to build uImage"
  echo -e ""
  echo -e "    ./build.sh env                     : Set up the Build environment so you can run 'make' directly"
  echo -e ""
  echo -e "    ./build.sh dfu-util                : Installs dfu-util"
  echo -e ""
  echo -e "  You may also do things like:"
  echo -e "    ./build.sh kernel menuconfig       : Open the kernel config GUI to enable options/drivers"
#  echo -e "    ./build.sh kernel rzn1_xip_defconfig : Switch to XIP version of the kernel"
#  echo -e "    ./build.sh kernel xipImage         : Build the XIP kernel image"
  echo -e "    ./build.sh buildroot menuconfig    : Open the Buildroot config GUI to select additinal apps to build"
  echo -e ""
  echo -e "    Current Target: $BOARD"
  echo -e ""
}

# Function: banner_color
function banner_yellow {
  echo -ne "\033[1;33m" # YELLOW TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}
function banner_red {
  echo -ne "\033[1;31m" # RED TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}
function banner_green {
  echo -ne "\033[1;32m" # GREEN TEXT
  echo "============== $1 =============="
  echo -ne "\033[00m"
}

##### Check if toolchain is installed correctly #####
function check_for_toolchain {
  CHECK=$(which ${CROSS_COMPILE}gcc)
  if [ "$CHECK" == "" ] ; then
    # Toolchain was found in path, so maybe it was hard coded in setup_env.sh
    return/
  fi
  if [ ! -e $OUTDIR/br_version.txt ] ; then
    banner_red "Toolchain not installed yet."
    echo -e "Buildroot will download and install the toolchain."
    echo -e "Please run \"./build.sh buildroot\" first and select the toolchain you would like to use."
    exit
  fi
}

# Save current config settings to file
function save_config {
  echo "BOARD=$BOARD" > output/config.txt
  echo "UBOOTCONFIG=$UBOOTCONFIG" >> output/config.txt
  echo "UBOOTBOARD=$UBOOTBOARD" >> output/config.txt
  echo "KERNELCONFIG=$KERNELCONFIG" >> output/config.txt
}


###############################################################################
# boards
###############################################################################
   BRD_NAMES[0]=rzn1d ; BRD_DESC[0]="RZ/N1D RSK"
 UBOOTCONFIG[0]=rzn1d400-db_config
  UBOOTBOARD[0]=TARGET_RENESAS_RZN1D400_DB
KERNELCONFIG[0]=rzn1_defconfig

   BRD_NAMES[1]=rzn1s ; BRD_DESC[1]="RZ/N1S RSK"
 UBOOTCONFIG[1]=rzn1s324-db_config
  UBOOTBOARD[1]=TARGET_RENESAS_RZN1S324_DB
KERNELCONFIG[1]=rzn1_defconfig

#Defaults
       BOARD=${BRD_NAMES[0]}
 UBOOTCONFIG=${UBOOTCONFIG[0]}
  UBOOTBOARD=${UBOOTBOARD[0]}
KERNELCONFIG=${KERNELCONFIG[0]}


###############################################################################
# script start
###############################################################################
# Save current directory
ROOTDIR=`pwd`

# Create output build directory
if [ ! -e output ] ; then
  mkdir -p output
fi

# Create config.txt file, or read in current settings
if [ ! -e output/config.txt ] ; then
  save_config
else
  source output/config.txt
fi

# Check command line
if [ "$1" == "" ] ; then
  usage
  exit
fi

# Run build environment setup
if [ "$ENV_SET" != "1" ] ; then
  # Because we are using 'source', ROOTDIR can be seen in setup_env.sh
  source ./setup_env.sh
fi

# Find out how many CPU processor cores we have on this machine
# so we can build faster by using multi-threaded builds
NPROC=2
if [ "$(which nproc)" != "" ] ; then  # make sure nproc is installed
  NPROC=$(nproc)
fi
BUILD_THREADS=$(expr $NPROC + $NPROC)

###############################################################################
# config
###############################################################################
if [ "$1" == "config" ] ; then

BRD_CNT=$(echo ${#BRD_NAMES[@]})
BRD_CNT_MAX_INDEX=$(expr $BRD_CNT - 1)

  while [ "1" == "1" ]
  do

    CURRENT_DESC="custom"

    for i in `seq 0 $BRD_CNT_MAX_INDEX` ; do
      if [ "$BOARD" == "${BRD_NAMES[$i]}" ] ; then
        CURRENT_DESC="${BRD_DESC[$i]}"
        break
      fi
    done

    whiptail --title "Build Environment Setup"  --noitem --menu "Make changes the items below as needed.\nYou may use ESC+ESC to cancel." 0 0 0 \
	"     Target Board: $BOARD [$CURRENT_DESC]" "" \
	" u-boot defconfig: $UBOOTCONFIG" "" \
	"  u-boot board ID: $UBOOTBOARD" "" \
	" kernel defconfig: $KERNELCONFIG" "" \
	"Save" "" 2> /tmp/answer.txt

    #ans=$(head -c 3 /tmp/answer.txt)
    ans=$(cat /tmp/answer.txt)

    if [ "$ans" == "" ]; then
      break;
    fi

    if [ "$(grep "Target Board" /tmp/answer.txt)" != "" ] ; then

    whiptail --title "Build Environment Setup" --menu \
"Please select the platform you want to build for.\n"\
"If you have your own custom board, choose the last\n"\
"entry and enter the string name that you used for when\n"\
"creating your BSP.\n"\
"For example, if you enter \"rztoaster\", we will assume:\n"\
" * rztoaster_defconfig (for u-boot and kernel)\n"\
" * rztoaster_xip_defconfig (for XIP kernel)\n"\
" * r7s72100-rztoaster.dts (for Device Tree)\n"\
 0 0 40 \
	"1. ${BRD_NAMES[0]}" ":${BRD_DESC[0]}" \
	"2. ${BRD_NAMES[1]}" ":${BRD_DESC[1]}" \
	"3. ${BRD_NAMES[2]}" ":${BRD_DESC[2]}" \
	"4. ${BRD_NAMES[3]}" ":${BRD_DESC[3]}" \
	"5. ${BRD_NAMES[4]}" ":${BRD_DESC[4]}" \
	"6. ${BRD_NAMES[5]}" ": Define your own board..." \
 2> /tmp/answer.txt
    ans=$(cat /tmp/answer.txt)

    # No selection (cancel)
    if [ "$ans" == "" ] ; then
      continue
    fi

    CUR_INDEX=$(head -c 1 /tmp/answer.txt)
    CUR_INDEX=$(expr $CUR_INDEX - 1)

    if [ "$CUR_INDEX" == "5" ] ; then
      whiptail --title "Custom board name selection" --inputbox "Enter your board name:" 0 0 \
      2> /tmp/answer.txt
      # No selection (cancel)
      if [ "$ans" == "" ] ; then
        continue
      fi
      BRD_NAMES[5]=$(cat /tmp/answer.txt)

      whiptail --title "Custom board selected" --msgbox "In the main menu, please adjust settings as needed" 0 0
    fi

    BOARD=${BRD_NAMES[$CUR_INDEX]}
    UBOOTCONFIG=${UBOOTCONFIG[$CUR_INDEX]}
    UBOOTBOARD=${UBOOTBOARD[$CUR_INDEX]}
    KERNELCONFIG=${KERNELCONFIG[$CUR_INDEX]}

    continue
  fi

  if [ "$(grep "Save" /tmp/answer.txt)" != "" ] ; then
    save_config
    break;
  fi

  done

  exit
fi

###############################################################################
# env
###############################################################################
if [ "$1" == "env" ] ; then

  check_for_toolchain

  echo "Copy/paste this line and execute it in your command window."
  echo ""
  echo 'export ROOTDIR=$(pwd) ; source ./setup_env.sh'
  echo ""
  echo "Then, you can execute 'make' directly in u-boot, linux, buildroot, etc..."
  exit
fi

###############################################################################
# dfu-util
###############################################################################
if [ "$1" == "dfu-util" ] ; then

  #CHECK=`which dfu-util`
  #if [ "$CHECK" != "" ] ; then
  #  banner_green "dfu-util is already installed"
  #  exit
  #fi

  cd $OUTDIR

  CHECK=`which git`
  if [ "$CHECK" == "" ] ; then
    banner_red "git is not installed"
    echo -e "You need git in order to download the kernel"
    echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install git\n"
    echo -e "Exiting build script.\n"
    exit
  fi

  if [ ! -e dfu-util ] ; then

    banner_yellow "Building dfu-util"

    git clone http://git.code.sf.net/p/dfu-util/dfu-util
    cd dfu-util
    git checkout -b rzn1 604de4b1
    git am ${ROOTDIR}/dfu-util/patches/00*.patch

    ./autogen.sh
    ./configure
    make

    banner_yellow "For this next command, you will need to enter your sudo password"
    echo "sudo make install"
    sudo make install

    banner_green "dfu-util is now installed"
  fi
  exit

  banner_green "dfu-util is already installed"
  exit
fi



###############################################################################
# build kernel
###############################################################################
if [ "$1" == "kernel" ] || [ "$1" == "k" ] ; then
  banner_yellow "Building kernel"

  check_for_toolchain

  if [ "$2" == "" ] ; then
    echo " "
    echo "What do you want to build?"
    echo "For example:  (case sensitive)"
    echo " Traditional kernel:  ./build.sh kernel uImage"
#    echo "         XIP kernel:  ./build.sh kernel xipImage"
    echo "  Kernel config GUI:  ./build.sh kernel menuconfig"
    exit
  fi

  if [ "$2" == "uImage" ] ; then
    CHECK=$(which mkimage)
    if [ "$CHECK" == "" ] ; then
      banner_red "mkimage is not installed"
      echo -e "You need the program mkimage installed in order to build a kernel uImage."
      echo -e "\tsudo apt-get install -y --force-yes --fix-missing build-essential libncurses5-dev u-boot-tools gettext bison flex libusb-1.0-0-dev\n\n"
      echo -e "Exiting build script.\n"
      exit
    fi
  fi

  cd $OUTDIR

  # install rzn1_linux
  if [ ! -e rzn1_linux ] ; then

    CHECK=`which git`
    if [ "$CHECK" == "" ] ; then
      banner_red "git is not installed"
      echo -e "You need git in order to download the kernel"
      echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install git\n"
      echo -e "Exiting build script.\n"
      exit
    fi

    #git clone -b rzn1-stable https://github.com/renesas-rz/rzn1_linux.git
    git clone -b rzn1-stable-v4.19 https://github.com/renesas-rz/rzn1_linux.git
    
    echo ""
    echo "Downloaded rzn1_linux kernel."
  fi

  cd rzn1_linux
  
  # build
  IMG_BUILD=0
  XIPCHECK=`grep -s CONFIG_XIP_KERNEL=y .config`

  if [ "$2" == "uImage" ] ;then
    IMG_BUILD=1

    if [ ! -e .config ] || [ "$XIPCHECK" != "" ]; then
      # Need to configure kernel first
      #make ${BOARD}_defconfig
	make ${KERNELCONFIG}
    fi
    # re-configure kernel if we changed target board
    #CHECK=$(grep -i CONFIG_MACH_${BOARD}=y .config )
    #if [ "$CHECK" == "" ] ; then
    #  echo "Reconfiguring for new board..."
    #  make ${BOARD}_defconfig
    #fi

    # To build a uImage, you need to specify LOADADDR.
    if [ "$BOARD" == "rzn1d" ] || [ "$BOARD" == "rzn1s" ] ; then
      MY_LOADADDR='LOADADDR=0x80008000'
    fi
    if [ "$3" != "" ] ; then
      MY_LOADADDR=LOADADDR=$3
    fi
    if [ "$MY_LOADADDR" == "" ] ; then
      banner_red "Missing load address (LOADADDR)"
      echo "When building a uImage, you need to specify the load address on the kernel"
      echo "build command line (make LOADADDR=0x55555555 uImage) so u-boot"
      echo "will know where in RAM to decompress the kernel to."
      echo "Examples:"
      echo "   ./build.sh kernel uImage 0x80008000"
      exit
    fi
  fi
  if [ "$2" == "xipImage" ] ;then
    IMG_BUILD=2
    if [ ! -e .config ] || [ "$XIPCHECK" == "" ]; then
      # Need to configure kernel first
      make ${BOARD}_xip_defconfig
    fi
    # re-configure kernel if we changed target board
    CHECK=$(grep -i CONFIG_MACH_${BOARD}=y .config )
    if [ "$CHECK" == "" ] ; then
      echo "Reconfiguring for new board..."
      make ${BOARD}_xip_defconfig
    fi

    # LOADADDR is not needed when building a xipImage
    MY_LOADADDR=
  fi

  if [ "$IMG_BUILD" != "0" ] ; then
    # NOTE: Adding "LOCALVERSION=" to the command line will get rid of the
    #       plus sign (+) at the end of the kernel version string. Alternatively,
    #       we could have created a empty ".scmversion" file in the root.
    # NOTE: We have to make the Device Tree Blobs too, so we'll add 'dtbs' to
    #       the command line
    echo -e "make $MY_LOADADDR LOCALVERSION= -j$BUILD_THREADS $2 dtbs\n"
    make $MY_LOADADDR LOCALVERSION= -j$BUILD_THREADS $2 dtbs

    if [ ! -e vmlinux ] ; then
      # did not build, so exit
      banner_red "Kernel Build failed. Exiting build script."
      exit
    else
      banner_green "Kernel Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make -j$BUILD_THREADS $2 $3 $4\n"
      make -j$BUILD_THREADS $2 $3 $4
  fi

  cd $ROOTDIR
fi

###############################################################################
# build u-boot
#
# Clones from https://github.com/renesas-rz/rzn1_u-boot.git
# Merges and builds according to DVD 1.3.1 release.
###############################################################################
if [ "$1" == "u-boot" ] || [ "$1" == "u" ] ; then
  check_for_toolchain
  
  # The dtc program is inside the kernel source tree
  if [ -e $OUTDIR/rzn1_linux/scripts/dtc/dtc ] ; then
    PATH=$PATH:$OUTDIR/rzn1_linux/scripts/dtc
  fi

  CHECK=`which dtc`
  if [ "$CHECK" == "" ] ; then
    banner_red "dtc is not installed"
    echo -e "You need the 'dtc' program (device tree compiler) in order to build the device trees in the u-boot source"
    echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install device-tree-compiler\n\n"
    echo -e "NOTE: It is also included in the rzn1_linux kernel source tree, so if you build the kernel first, "
    echo -e "we can just use that version you do not need to manally install it.\n\n"
    echo -e "Exiting build script.\n"
    exit
  else
    echo -e "DTC installed.\n"
  fi

  cd $OUTDIR

  banner_yellow Observe!
  echo -e "This is for the 1.3.1 DVD and higher revisions and follows RZN1-U-Boot-User-Manual"
  echo -e "chapters U-Boot Setup and Build."
  echo -e "New u-boot branch is at https://github.com/renesas-rz/rzn1_u-boot.git"
  banner_yellow "Building u-boot"
  

  # install u-boot
  if [ ! -e u-boot ] ; then

    #Download u-boot
    git clone http://git.denx.de/u-boot.git
    echo "cloning from git.denx.de/u-boot.git..."

    CHECK=`which git`
    if [ "$CHECK" == "" ] ; then
      banner_red "git is not installed"
      echo -e "You need git in order to download the kernel"
      echo -e "In Ubuntu, you can install it by running:\n\tsudo apt-get install git\n"
      echo -e "Exiting build script.\n"
      exit
    fi
  else
    banner_yellow "Directory u-boot exists; skipping clone/download of u-boot."
  fi

  cd u-boot
  
  # Checkout a branch based on the 2017.01 version:
  git checkout -b rzn1 v2017.01
  
  # Set the BSP version to according to the release, for example:
  BSP_VERSION=v1.4.4
  
  # Fetch the RZ/N1 branch and merge it in:
  git remote add renesas-rz https://github.com/renesas-rz/rzn1_u-boot.git
  git fetch --tags renesas-rz
  git merge rzn1-public-$BSP_VERSION

  # Build.
  # Setup configuration for Renesas RZ/N1D-DB Board
  make rzn1d400-db_config
  # Setup configuration for Renesas RZ/N1S-DB Board
  #make rzn1s324-db_config
  # Setup configuration for Renesas RZ/N1S IO-Link Board
  #make rzn1s-io-link_config
  # Setup configuration for Renesas RZ/N1L-DB Board
  #make rzn1l-db_config
  
  # Build U-Boot
  if [ "$2" == "" ] ;then

    # default build
    make
    if [ ! -e u-boot.bin ] ; then
      # did not build, so exit
      banner_red "u-boot Build failed. Exiting build script."
      exit
    else
      banner_green "u-boot Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make $2 $3 $4\n"
      make $2 $3 $4
  fi

  cd $ROOTDIR

  echo -e "The Elf executable is stored as 'u-boot' but must be converted to a Renesas SPKG image before download via DFU."
  echo -e "DONE build u-boot.\n"

  exit  
  
  # ====================================================================
  # Rest of u-boot section below not used but kept in case needed for later(!)
  # ====================================================================
  
  # Configure u-boot
  if [ ! -e .config ] ;then
    make ${UBOOTCONFIG}
  fi

  # re-configure u-boot if we changed target board
  CHECK=$(grep $UBOOTBOARD .config)
  if [ "$CHECK" == "" ] ; then
    echo "Reconfiguring for new board..."
    make ${UBOOTCONFIG}
  fi

  # Build u-boot
  if [ "$2" == "" ] ;then

    # default build
    make

    if [ ! -e u-boot.bin ] ; then
      # did not build, so exit
      banner_red "u-boot Build failed. Exiting build script."
      exit
    else
      banner_green "u-boot Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make $2 $3 $4\n"
      make $2 $3 $4
  fi

  cd $ROOTDIR

fi

###############################################################################
# build buildroot
###############################################################################
if [ "$1" == "buildroot" ]  || [ "$1" == "b" ] ; then
  banner_yellow "Building buildroot"

  cd $OUTDIR

  if [ ! -e br_version.txt ] ; then
    echo "What version of Buildroot do you want to use?"
    echo "1. buildroot-2018.11.4 (may exist later 2018.11 version)"
    echo "2. buildroot-2019.02.6 (LTS - may exist later 2019.02 version)"
    echo -n "(Select number)=> "
    read ANSWER
    if [ "$ANSWER" == "1" ] ; then
      echo "export BR_VERSION=2018.11.4" > br_version.txt
    elif [ "$ANSWER" == "2" ] ; then
      echo "export BR_VERSION=2019.02.6" > br_version.txt
    else
      echo "ERROR: \"$ANSWER\" is an invalid selection!"
      exit
    fi
    source br_version.txt
  fi

  # manaully download the toolchain
  #if [ ! -e gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz ] ; then
  #  wget https://releases.linaro.org/components/toolchain/binaries/6.3-2017.02/arm-linux-gnueabihf/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz
  #fi

  #if [ ! -e gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf ] ; then
  #  tar xf gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf.tar.xz
  #fi
   #export PATH=/usr/share/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/bin:$PATH
   #export CROSS_COMPILE="arm-linux-gnueabihf-"
   #export ARCH=arm


  # Download buildroot-$BR_VERSION.tar.bz2
  if [ ! -e buildroot-$BR_VERSION.tar.bz2 ] ;then
    wget http://buildroot.uclibc.org/downloads/buildroot-$BR_VERSION.tar.bz2
  fi

  # extract buildroot-$BR_VERSION
  if [ ! -e buildroot-$BR_VERSION/README ] ;then
    echo "extracting buildroot..."
    tar -xf buildroot-$BR_VERSION.tar.bz2
  fi

  cd buildroot-$BR_VERSION

  # If it's an LTS version, apply any update patches    //TODO
  if [ "$BR_VERSION" == "2017.02" ] ; then

    CHECK=`grep " BR2_VERSION " Makefile`
    if [ "$CHECK" == "export BR2_VERSION := 2019.02" ] ; then
      banner_yellow "Updating Buildroot version from 2019.02 to 2019.02.1"
      sleep 1
      patch -s -p1 -i $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/br_2019.02.0_to_2019.02.1.patch
    fi

    CHECK=`grep " BR2_VERSION " Makefile`
    if [ "$CHECK" == "export BR2_VERSION := 2019.02.1" ] ; then
      banner_yellow "Updating Buildroot version from 2019.02.1 to 2019.02.2"
      sleep 1
      patch -s -p1 -i $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/br_2019.02.1_to_2019.02.2.patch
    fi

    CHECK=`grep " BR2_VERSION " Makefile`
    if [ "$CHECK" == "export BR2_VERSION := 2019.02.2" ] ; then
      banner_yellow "Updating Buildroot version from 2019.02.2 to 2019.02.3"
      sleep 1
      patch -s -p1 -i $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/br_2019.02.2_to_2019.02.3.patch
    fi

    # Created by doing:
    #   git diff 2019.02   2019.02.1 > br_2019.02.0_to_2019.02.1.patch
    #   git diff 2019.02.1 2019.02.2 > br_2019.02.1_to_2019.02.2.patch
    #   git diff 2019.02.2 2019.02.3 > br_2019.02.2_to_2019.02.3.patch
  fi

  if [ ! -e output ] ; then
    mkdir -p output
  fi

  # Copy in our rootfs_overlay directory
  if [ ! -e output/rootfs_overlay ] ; then
    cp -a $ROOTDIR/patches-buildroot/rootfs_overlay output
  fi

 # Patch and Configure Buildroot for RZ/N
  if [ ! -e configs/rzn1_defconfig ]; then
    echo $BR_VERSION
    # Apply Renesas Buildroot patches (begin with renesas_)
    for i in $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/renesas_*.patch; do patch -p1 < $i; done

    # Ask the user if they want to use the glib based Linaro toolchain
    # or build a uclib toolchain from scratch.
    banner_yellow "Toolchain selection"
    #echo -e "\n\n[ Toolchain selection ]"
    echo -e "What toolchain and C Library do you want to use for building applications?"
    echo ""
    echo "By default, we suggest the Linaro pre-built toolchain with hardware float"
    echo "support and glib C Libraries."
    echo ""
    echo "It is also possible to configure Buildroot to download and build from source"
    echo "a uClibc or musl based toolchain. Note that while uClibc or musl produces a smaller binary"
    echo "footprint, some open souce applications are not compatible. (musl is more compatible than uClibC)"
    echo ""
    echo "Finaly, you may also configure Buildroot to use a toolchain that is already"
    echo "install on your machine."
    echo ""
    echo "What would you like to do?"
    echo "  1. Use the default Linaro toolchain (recommended)"
    echo "  2. Install Buildroot and then let me decide in the configuration menu (advanced)"
    echo -n "=> "
    for i in 1 2 3 ; do
      echo -n " Enter your choice (1 or 2): "
      read TC_CHOICE
      if [ "$TC_CHOICE" == "1" ] ; then break; fi
      if [ "$TC_CHOICE" == "2" ] ; then break; fi
      TRY=$i
    done

    if [ "$TRY" == "3" ] ; then
      echo -e "\nI give up! I have no idea what you want to do."
      exit
    fi

    # Copy in our default Buildroot config for the RSK
    # NOTE: It was made by running this inside buildroot
    #   make savedefconfig BR2_DEFCONFIG=../../patches-buildroot/rzn1_defconfig
    # or rather
    #   ./build.sh buildroot savedefconfig BR2_DEFCONFIG=../../patches-buildroot/rzn1_defconfig
    #          NOTE: 'BR2_PACKAGE_JPEG=y' has to be manually added before
    #                'BR2_PACKAGE_JPEG_TURBO=y' (a bug in savedefconfig I assume)
    #
    cp -a $ROOTDIR/patches-buildroot/buildroot-$BR_VERSION/*_defconfig configs/

    # Just build the minimum file systerm. Users can go back and add more if they want to later.
    make rzn1_defconfig

    if [ "$TC_CHOICE" == "2" ] ; then

      # User wants to select the toolchain themselves.
      make menuconfig

      echo ""
      echo "======================================================================="
      echo ""
      echo " If everything is how you like it, you can now build your system by running:"
      echo "     ./build.sh buildroot"
      echo ""
      echo " Or you can add additional SW packages by running:"
      echo "     ./build.sh buildroot menuconfig"
      echo ""

      exit

    fi
  fi

  # Trim buildroot temporary build files since they are not longer needed
  if [ "$2" == "trim" ] ;then

    echo "This will remove a good portion of intermediate build files under"
    echo "under the output/build directory since after they are build, they don't"
    echo "really serve much purpose anymore."
    echo ""
    echo -n "Continue? [y/N] "
    read ANS
    if [ "$ANS" != "y" ] || [ "$ANS" == "Y" ] ; then
      exit
    fi

    echo "First, we'll remove all the build files from output/build/host-* because once"
    echo "they are built and copied to output/host, there is not more use for them".
    echo "We only need to kee the .stamp_xxx files to tell Buildroot that they've already"
    echo "been built."
    echo -n "Press return to continue..."
    echo TRIMMING:
    TOTAL=`du -s -h -c $(ls -d output/build/host-*) | grep total`
    for HOST_DIR in $(ls -d output/build/host-*)
    do
      du -s -h $HOST_DIR
      find $HOST_DIR -type f ! -name '.stamp_*' -delete
      find $HOST_DIR -type l -delete
      rm -r -f `find $HOST_DIR -type d -name ".*"`
      find $HOST_DIR -type d -empty -delete
    done
    echo ""
    echo -n $TOTAL
    echo " deleted"

    echo ""
    echo "Next we will look at packages that you have already built and installed in your root"
    echo "file system. After the binaries have been copied to output/target and build libraries"
    echo "have been copied to output/staging, there is no more use for the files under output/build."
    echo ""
    echo "HINT: Just pressing enter defaults to 'y' "
    echo ""
    for BUILD_DIR in $(ls -d output/build/*)
    do
      #echo $BUILD_DIR
      #echo "${BUILD_DIR:13}"
      BUILD_DIR_NAME=${BUILD_DIR:13:18}

      # ignore the host- directories
      if [ "${BUILD_DIR_NAME:0:5}" == "host-" ] ; then
        continue
      fi

      # skip busybox because that is one that can be reconfigured
      # and reinstalled even after initial built
      if [ "${BUILD_DIR_NAME:0:7}" == "busybox" ] ; then
        continue
      fi

      # skip toolchain
      if [ "${BUILD_DIR_NAME:0:9}" == "toolchain" ] ; then
        continue
      fi

      # skip skeleton
      if [ "${BUILD_DIR_NAME:0:8}" == "skeleton" ] ; then
        continue
      fi

      # ignore directories without stamps
      if [ ! -e $BUILD_DIR/.stamp_target_installed ] ; then
        continue
      fi

      echo -n "Clean $BUILD_DIR_NAME ? [ Y/n ]: "
      read ANS
      if [ "$ANS" == "" ] || [ "$ANS" == "y" ] || [ "$ANS" == "Y" ] ; then

        du -s -h $BUILD_DIR
        find $BUILD_DIR -type f ! -name '.stamp_*' -delete
        find $BUILD_DIR -type l -delete
        rm -r -f `find $BUILD_DIR -type d -name ".*"`
        find $BUILD_DIR -type d -empty -delete
      fi
    done

    exit
  fi

  # Build Buildroot
  if [ "$2" == "" ] ;then

    # default build
    make

    if [ ! -e output/images/rootfs.tar ] ; then
      # did not build, so exit
      banner_red "Buildroot Build failed. Exiting build script."
      exit
    else
      banner_green "Buildroot Build Successful"
    fi
  else
      # user wants to build something special
      banner_yellow "Custom Build"
      echo -e "make $2 $3 $4 $5\n"
      make $2 $3 $4 $5
  fi

  cd $ROOTDIR
fi

###############################################################################
# build axfs
###############################################################################
if [ "$1" == "axfs" ] ; then
  banner_yellow "Building axfs"

  cd $OUTDIR

  if [ ! -e axfs/mkfs.axfs ] ; then
    mkdir -p axfs
    cd axfs
    #  Build mkfs.axfs from source
    #  cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.c .
    #  cp -a ../../axfs/mkfs.axfs-legacy/linux .
    #  cp -a ../../axfs/mkfs.axfs-legacy/Makefile .
    #  make

    # Just copy the pre-build version
    CHECK=$(uname -m)
    if [ "$CHECK" == "x86_64" ] ; then
      # 64-bit OS
      cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.64 mkfs.axfs
    else
      # 32-bit OS
      cp -a ../../axfs/mkfs.axfs-legacy/mkfs.axfs.32 mkfs.axfs
    fi

    cd ..
  fi


  cd axfs

  # NOTE: If the 's' attribute is set on busybox executable (which it is by default when
  #   Buildroot builds it), and the file owner is not 'root' (which it will not be because
  #   you were not root when you ran Buildroot) you can't boot and will just keep getting
  #   a "Permission denied" message after the file system is mounted"
  chmod a-s $BUILDROOT_DIR/output/target/bin/busybox

  #./mkfs.axfs -s -a $BUILDROOT_DIR/output/target rootfs.axfs.bin
  ./mkfs.axfs -s -a ../buildroot-$BR_VERSION/output/target rootfs.axfs.bin

  if [ ! -e rootfs.axfs.bin ] ; then
    # did not build, so exit
    banner_red "axfs Build failed. Exiting build script."
    exit
  else
    banner_green "axfs Build Successful"
    echo -e "You can find your AXFS image to flash here:"
    echo -e "\t$(pwd)/rootfs.axfs.bin"
  fi

  cd $ROOTDIR
fi

###############################################################################
# update
###############################################################################
if [ "$1" == "update" ] ; then
  banner_yellow "repository update"

  if [ "$2" == "" ] ; then
    echo -e "Update:"
    echo -e "This command will 'git pull' the latest code from the github repositories."
    echo -e "Any changes you have made will be save and re-applied after the updated."
    echo -e "Basically, we will do the following:"
    echo -e "  git stash      # save current changes"
    echo -e "  git pull       # download latest version"
    echo -e "  git stash pop  # re-apply saved changes"
    echo -e ""
    echo -e "  ./build.sh update b   # updates bsp build scripts"
    echo -e "  ./build.sh update u   # updates uboot source"
    echo -e "  ./build.sh update k   # updates kernel source"
    echo -e ""
    exit
  fi
 
  if [ "$2" == "b" ] ; then
    git stash
    git pull
    git stash pop
    exit
  fi

  cd $OUTDIR

  if [ "$2" == "k" ] ; then
    if [ ! -e rzn1_linux ] ; then
      #git clone -b rzn1-stable       https://github.com/renesas-rz/rzn1_linux.git
       git clone -b rzn1-stable-v4.19 https://github.com/renesas-rz/rzn1_linux.git
    else
      cd rzn1_linux
      git stash                     # <== user changes saved.
      git checkout rzn1-stable-v4.19
      git pull                      # <== latest updates (ree).
      git stash pop                 # <== user changes reinserted.
    fi
    exit
  fi
  
  if [ "$2" == "u" ] ; then
    if [ ! -e u-boot ] ; then
      #Download u-boot
      git clone http://git.denx.de/u-boot.git
      echo "cloning from git.denx.de/u-boot.git..."
    else
      cd u-boot
      git stash
      git checkout master
      git pull
      git stash pop
    fi
    exit
  fi
fi