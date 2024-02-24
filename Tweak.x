#import "Shared.h"
#import <Foundation/Foundation.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>

NSString *safe_getExecutablePath() {
	char executablePathC[PATH_MAX];
	uint32_t executablePathCSize = sizeof(executablePathC);
	_NSGetExecutablePath(&executablePathC[0], &executablePathCSize);
	return [NSString stringWithUTF8String:executablePathC];
}

NSString* safe_getBundleIdentifier() {
	CFBundleRef mainBundle = CFBundleGetMainBundle();

	if(mainBundle != NULL) {
		CFStringRef bundleIdentifierCF = CFBundleGetIdentifier(mainBundle);

		return (__bridge NSString*)bundleIdentifierCF;
	}

	return nil;
}

void (*__BKSTerminateApplicationForReasonAndReportWithDescription)(NSString *bundleID, int reasonID, bool report, NSString *description);

void loadBackboardServices(void) {
	static dispatch_once_t onceToken;
    dispatch_once (&onceToken, ^{
        void* bbsHandle = dlopen("/System/Library/PrivateFrameworks/BackBoardServices.framework/BackBoardServices", RTLD_NOW);
		__BKSTerminateApplicationForReasonAndReportWithDescription = dlsym(bbsHandle, "BKSTerminateApplicationForReasonAndReportWithDescription");
    });
}

void handleEnabledAppsChange() {
	static NSDictionary* cachedPrefs;
	NSDictionary* newPrefs = [NSDictionary dictionaryWithContentsOfFile:JAIL_MONKEY_BYPASS_PREFS_PATH];

	if(cachedPrefs) {
		NSMutableSet* oldEnabledApps = [NSMutableSet setWithArray:cachedPrefs[@"enabledApplications"]?:@[]];
		NSMutableSet* newEnabledApps = [NSMutableSet setWithArray:newPrefs[@"enabledApplications"]?:@[]];

		NSMutableSet* disabledApps = [oldEnabledApps mutableCopy];
		NSMutableSet* enabledApps = [newEnabledApps mutableCopy];

		[enabledApps minusSet:oldEnabledApps];
		[disabledApps minusSet:newEnabledApps];

		NSMutableSet* changedApps = disabledApps.mutableCopy;
		[changedApps unionSet:enabledApps];

		for(NSString* changedAppId in changedApps) {
			loadBackboardServices();
			__BKSTerminateApplicationForReasonAndReportWithDescription(changedAppId, 5, false, @"JailMonkeyBypass - prefs changed, killed");
		}
	}

	cachedPrefs = newPrefs;
}

@group(Application)
%hook JailMonkey
- (BOOL)isJailBroken {
  NSLog(@"JailMonkey isJailbroken called.");
  return NO;
}
%end
@end

%ctor {
  	NSString *executablePath = safe_getExecutablePath();

	if(executablePath) {
		NSString *processName = [executablePath lastPathComponent];

		if([processName isEqualToString:@"SpringBoard"]) {
			migratePreferencesIfNeeded();
			CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)handleEnabledAppsChange, CFSTR("com.ariel.jailmonkeybypassprefs/ReloadPrefs"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
			handleEnabledAppsChange();
		} else if([executablePath containsString:@"/Application"]) {
			NSString* identifier = safe_getBundleIdentifier();
			NSDictionary* preferences = [[NSDictionary alloc] initWithContentsOfFile:JAIL_MONKEY_BYPASS_PREFS_PATH];
			NSNumber* globallyEnabledNum = [preferences objectForKey:@"enabled"];
			BOOL globallyEnabled = globallyEnabledNum ? globallyEnabledNum.boolValue : YES;

			if(!globallyEnabled) return;

			NSArray* enabledApps = [preferences objectForKey:@"enabledApplications"];
			if(![enabledApps containsObject:identifier]) return;

			%init(Application);
		}
  	}
}