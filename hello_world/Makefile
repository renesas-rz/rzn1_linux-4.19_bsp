ifeq ("$(CROSS_COMPILE)","")
	CC_CHECK:=echo !!ERROR!! CROSS_COMPILE not set
else
endif

ifeq ("$(BUILDROOT_DIR)","")
	BR_CHECK:=echo !!ERROR!! BUILDROOT_DIR not set
else
endif

ifeq ($(S),1)
	STATIC = -static
else
        STATIC =
endif

all: default

#######################################################################
# Toolchain setup
#######################################################################

# You want to build apps with the same toolchain and libraries
# that you built your root file system with. We'll assume you
# are using Buildroot.
# Therefore, make sure BUILDROOT is defined before calling this
# Makefile.


# 'BUILDROOT_DIR' should be imported after running setup_env.sh

# Define the base path of the toolchain and put it in the system path
ifeq ("$(wildcard $(BUILDROOT_DIR)/output/host/bin)","")
  # OLD Buildroot (before 2018), output/host/usr/bin contains host apps for building
  TC_PATH := $(BUILDROOT_DIR)/output/host/usr
else
  # NEW Buildroot as of 2018.11 2018, output/host/bin contains host apps for building
  TC_PATH := $(BUILDROOT_DIR)/output/host
endif
$(info TC_PATH=”$(TC_PATH)”)
export PATH:=$(TC_PATH)/bin:$(PATH)

# Find prefix of toolchain used for Buildroot
GCCEXE:=$(notdir $(wildcard $(TC_PATH)/bin/*abi*-gcc))
$(info CROSS_COMPILE=”$(CROSS_COMPILE)”) #Before setting CROSS_COMPILE just to see if already set. Remove.
CROSS_COMPILE:=$(subst gcc,,$(GCCEXE))
$(info CROSS_COMPILE=”$(CROSS_COMPILE)”)
#Or type $> ${CROSS_COMPILE}gcc
#on the command line

# Find the location of the sysroot where all the libraries and header files are
SYSROOT:=$(shell find $(TC_PATH) -name sysroot)
$(info SYSROOT=”$(SYSROOT)”)

# Manual setup if setup_env.sh is not used
#TC_PATH=/home/renesas/toolchain/buildroot-2014.05/output/host/usr
#TC_PATH=/home/sven/rzn_dev_setup/rzn1_linux-4.9_bsp/output/buildroot-2018.11/output/host/usr
#CROSS_COMPILE=arm-buildroot-linux-uclibcgnueabi-
ARCH:=arm

#######################################################################
# Application Specific setup
#######################################################################
app:=hello

LIBS:=
#CFLAGS="-I$(TC_PATH)/arm-buildroot-linux-uclibcgnueabi/sysroot/usr/include/libnl3/"

default:
	@$(BR_CHECK)
	$(CROSS_COMPILE)gcc $(STATIC) $(CFLAGS) --sysroot=$(SYSROOT) -o $(app) $(app).c $(LIBS)

install:
	@# Copy to Buildroot overlay directory (only for Renesas BSP users)
	mkdir -p $(BUILDROOT_DIR)/output/rootfs_overlay/usr/bin
	cp $(app) $(BUILDROOT_DIR)/output/rootfs_overlay/usr/bin
	@echo ''
	@echo 'Please run Buildroot again to repackage the rootfs image.'
	@echo 'For example:'
	@echo '  $$ cd $$BUILDROOT_DIR'
	@echo '  $$ make'

clean:
	@rm -f *.o
	@rm -f *.a
	@rm -f $(app)

