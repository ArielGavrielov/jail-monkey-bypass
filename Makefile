TARGET := iphone:clang:16.5:14.0

TWEAK_NAME = Jail-Monkey-Bypass
PACKAGE_VERSION = 1.0.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_FILES = Tweak.x Shared.m
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = AltList
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
