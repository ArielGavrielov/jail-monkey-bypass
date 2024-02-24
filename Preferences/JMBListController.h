#import <Preferences/PSListController.h>

@interface JMBListController : PSListController
{
  NSArray* _allSpecifiers;
}

- (NSString*)plistName;
- (void)removeDisabledGroups:(NSMutableArray*)specifiers;
@end