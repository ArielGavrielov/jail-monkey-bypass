#import "JMBRootListController.h"
#import "../Shared.h"
#import <Preferences/PSSpecifier.h>

@implementation JMBRootListController

- (instancetype)init
{
	self = [super init];
	if(self)
	{
		migratePreferencesIfNeeded();
	}
	return self;
}

- (NSString*)plistName
{
	return @"Root";
}

- (void)setPreferenceValue:(NSObject*)value specifier:(PSSpecifier*)specifier
{
	NSString* key = [specifier propertyForKey:@"key"];
	NSMutableDictionary* prefs = [NSDictionary dictionaryWithContentsOfFile:JAIL_MONKEY_BYPASS_PREFS_PATH].mutableCopy ?: [NSMutableDictionary new];
	prefs[key] = value;
	[prefs writeToFile:JAIL_MONKEY_BYPASS_PREFS_PATH atomically:YES];

	NSNumber* nestedEntryCount = [[specifier properties] objectForKey:@"nestedEntryCount"];
	if(nestedEntryCount)
	{
		NSInteger index = [_allSpecifiers indexOfObject:specifier];
		NSMutableArray* nestedEntries = [[_allSpecifiers subarrayWithRange:NSMakeRange(index + 1, [nestedEntryCount intValue])] mutableCopy];
		[self removeDisabledGroups:nestedEntries];

		if([(NSNumber*)value boolValue])
		{
			[self insertContiguousSpecifiers:nestedEntries afterSpecifier:specifier animated:YES];
		}
		else
		{
			[self removeContiguousSpecifiers:nestedEntries animated:YES];
		}
	}
	
	NSString* postNotification = [specifier propertyForKey:@"PostNotification"];
	if(postNotification)
	{
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)postNotification, NULL, NULL, YES);
	}
}

- (NSObject*)readPreferenceValue:(PSSpecifier*)specifier
{
	NSString* key = [specifier propertyForKey:@"key"];
	NSObject* defaultValue = [specifier propertyForKey:@"default"];

	NSDictionary* prefs = [NSDictionary dictionaryWithContentsOfFile:JAIL_MONKEY_BYPASS_PREFS_PATH];
	return prefs[key] ?: defaultValue;
}

@end