#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#import "Shared.h"

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

%hook JailMonkey
- (BOOL)isJailBroken {
  return NO;
}
%end

%ctor {
  	NSString *executablePath = safe_getExecutablePath();

	if(executablePath && [executablePath containsString:@"/Application"]) {
		NSString* identifier = safe_getBundleIdentifier();
		NSDictionary* preferences = [[NSDictionary alloc] initWithContentsOfFile:JAIL_MONKEY_BYPASS_PREFS_PATH];

		NSNumber* tweakEnabledNum = [preferences objectForKey:@"enabled"];
		BOOL tweakEnabled = tweakEnabledNum ? tweakEnabledNum.boolValue : YES;

		if(!tweakEnabled) return;

		NSNumber* specificAppsNum = [preferences objectForKey:@"specificApps"];
		BOOL specificAppsEnabled = specificAppsNum ? specificAppsNum.boolValue : YES;
		NSArray* enabledApps = [preferences objectForKey:@"enabledApplications"];

		if(specificAppsEnabled && ![enabledApps containsObject:identifier]) return;

		%init;
  	}
}