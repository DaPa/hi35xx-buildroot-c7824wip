################################################################################
#
# myOpenCam
#
################################################################################

MYOPENCAM_SITE = $(TOPDIR)/package/myopencam
MYOPENCAM_SITE_METHOD = local
#MYOPENCAM_SOURCE = myopencam-$(MYOPENCAM_VERSION).tgz
MYOPENCAM_INSTALL_STAGING = NO
MYOPENCAM_DEPENDENCIES = himpp-hi3518v100 linux

MYOPENCAM_PREFIX = $(call qstrip,$(BR2_PACKAGE_MYOPENCAM_PREFIX))

MYOPENCAM_MAKE_OPTS = ARCH=arm
MYOPENCAM_MAKE_OPTS += HIARCH=hi3518
MYOPENCAM_MAKE_OPTS += LIBC=uclibc
MYOPENCAM_MAKE_OPTS += CROSS=$(TARGET_CROSS)
MYOPENCAM_MAKE_OPTS += CROSS_COMPILE=$(TARGET_CROSS)
MYOPENCAM_MAKE_OPTS += LINUX_ROOT=$(LINUX_DIR)

MYOPENCAM_MAKE_OPTS += INC_STAGING_DIR=$(STAGING_DIR)/usr/include/$(BR2_PACKAGE_HIMPP_CHIP)mpp
MYOPENCAM_MAKE_OPTS += LIB_STAGING_DIR=$(STAGING_DIR)/usr/lib

#
# --- extract / pull / build area

#define MYOPENCAM_EXTRACT_CMDS
#   mkdir -p $(@D)
#   $(TAR) -zxf $(DL_DIR)/$(MYOPENCAM_SOURCE) \
#       --strip-components=2 -C $(@D)
#endef

define my_build
    ( cd $(@D)/$(1) && $(MAKE1) $(MYOPENCAM_MAKE_OPTS) ) || exit 1;
endef

#define MYOPENCAM_BUILD_CMDS
#    ( cd $(@D)/lib; \
#    for f in *.a; do \
#      $(TARGET_CC) -shared -fPIC -o $${f%.a}.so \
#                   -Wl,--whole-archive $$f -Wl,--no-whole-archive \
#      || exit 1; \
#    done; \
#    );
#endef

# ---
#


###############################################################################
# kernel drivers
###############################################################################

ifeq ($(BR2_PACKAGE_MYOPENCAM_MODULES),y)
	# Kernel modules to build
	MYOPENCAM_MODULE_SUBDIRS = \
		kdriver/mymotogpio \
		kdriver/wtdg \
		kdriver/rtc

	MYOPENCAM_MODULE_MAKE_OPTS = \
		KERNELDIR=$(LINUX_DIR), \
    	KVERSION=$(LINUX_VERSION_PROBED)
endif

ifeq ($(BR2_PACKAGE_MYOPENCAM),y)
	# install ONLY existing .ko modules from kdriver folder level
	KDRIVER_TO_INSTALL = $(shell cd $(@D)/kdriver && find -name \*.ko)
	KDRIVER_TARGET_DIR = $(TARGET_DIR)$(MYOPENCAM_PREFIX)/kdriver
endif


###############################################################################
# libraries
###############################################################################

ifeq ($(BR2_PACKAGE_MYOPENCAM),y)
    #MYOPENCAM_BUILD_CMDS += $(call my_build,lib)
	#LIBRARIES_TO_INSTALL = ...
endif


###############################################################################
# main app
###############################################################################

ifeq ($(BR2_PACKAGE_MYOPENCAM),y)
    #MYOPENCAM_BUILD_CMDS += $(call my_build,src)
	#PROGRAMS_TO_INSTALL = ...
endif


###############################################################################
# tests
###############################################################################

ifeq ($(BR2_PACKAGE_MYOPENCAM_TESTS),y)
    MYOPENCAM_BUILD_CMDS += $(call my_build,tests)
endif

# ---


#
# --- install area

define MYOPENCAM_TARGET_INSTALL_KDRIVERS
    for f in $(KDRIVER_TO_INSTALL); do \
      $(INSTALL) -D $(@D)/kdriver/$$f \
                 $(KDRIVER_TARGET_DIR)/$$f \
      || exit 1; \
    done
endef


define MYOPENCAM_TARGET_INSTALL_LIBRARIES
   for f in $(@D)/lib/*.so; do \
     t=`basename $$f`; \
     $(INSTALL) -D -m 0755 $$f \
                $(TARGET_DIR)/usr/lib/$$t \
     || exit 1; \
   done
endef


define MYOPENCAM_TARGET_INSTALL_PROGRAMS
#   for f in $(PROGRAM_TO_INSTALL); do \
#     t=`basename $$f`; \
#     $(INSTALL) -D -m 0755 $(@D)/$$f \
#                $(TARGET_DIR)$(HIMPP_PREFIX)/bin/$$t \
#     || exit 1; \
#     $(TARGET_STRIP) --strip-all \
#                $(TARGET_DIR)$(HIMPP_PREFIX)/bin/$$t; \
#   done
endef

define MYOPENCAM_TARGET_INSTALL_TESTS
    if [ "X$(BR2_PACKAGE_MYOPENCAM_TESTS)" = "Xy" ]; then \
        mkdir -p $(TARGET_DIR)/$(MYOPENCAM_PREFIX)/tests; \
        for f in $(@D)/tests/* $(TESTS_TO_INSTALL); do \
            if [[ -x $$f || $$f == *.cfg ]]; then \
                t=`basename $$f`; \
                cp -a $$f $(TARGET_DIR)/$(MYOPENCAM_PREFIX)/tests/$$t; \
            fi \
        done \
    fi
endef

define MYOPENCAM_INSTALL_TARGET_CMDS
    $(MYOPENCAM_TARGET_INSTALL_KDRIVERS)
    $(MYOPENCAM_TARGET_INSTALL_LIBRARIES)
    $(MYOPENCAM_TARGET_INSTALL_PROGRAMS)
    $(MYOPENCAM_TARGET_INSTALL_TESTS)
    $(INSTALL) -m 0755 -D package/myopencam/myopencam.sh \
        $(TARGET_DIR)/$(MYOPENCAM_PREFIX)/myopencam.sh
    $(INSTALL) -m 0755 -D package/myopencam/low_power.sh \
        $(TARGET_DIR)/$(MYOPENCAM_PREFIX)/low_power.sh
endef

define MYOPENCAM_INSTALL_INIT_SYSV
    $(INSTALL) -m 0755 -D package/myopencam/S90myopencam \
        $(TARGET_DIR)/etc/init.d/S90myopencam
    sed -r -i -e "s;^MYOPENCAM_PREFIX=.*$$;MYOPENCAM_PREFIX=$(MYOPENCAM_PREFIX);" \
        $(TARGET_DIR)/etc/init.d/S90myopencam
endef


$(eval $(kernel-module))
$(eval $(generic-package))

