ifeq ($(THEOS_PACKAGE_SCHEME),rootless)
	ARCHS = arm64 arm64e
	TARGET = iphone:clang:16.5:15.0
else
	ARCHS = arm64 arm64e
	TARGET = iphone:clang:16.5:13.0
endif

TWEAK_NAME = Jail-Monkey-Bypass
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

$(TWEAK_NAME)_FILES = Tweak.x
$(TWEAK_NAME)_EXTRA_FRAMEWORKS = AltList
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
