//
//  CommonRetOC.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#ifndef CommonRetOC_h
#define CommonRetOC_h
#import "HackProtocol.h"
#import "Logger.h"

@interface CommonRetOC : NSObject <HackProtocol>
- (void)ret;
- (void)ret_;
- (void)ret__;

- (int)ret1;
- (int)ret0;
+ (int)ret1;
+ (int)ret0;


/**
 * [NSUbiquitousKeyValueStore +defaultStore]
 *  Check iCloud Key-Value Store
 */
+ (id)hook_defaultStore;

/**
 * [NSFileManager -ubiquityIdentityToken]
 *  Check iCloud file storage status
 */
- (id)hook_ubiquityIdentityToken;
- (id)hook_URLForUbiquityContainerIdentifier:containerIdentifier;





///codesign -d --entitlements :- /path/to/YourApp.app
///com.apple.developer.icloud-services: Ensure iCloud services are enabled.
///com.apple.developer.ubiquity-container-identifiers: Check container identifiers.
/**
 * [CKContainer +containerWithIdentifier:]
 *  Get a specific iCloud container by its identifier.
 */
+ (id)hook_containerWithIdentifier:identifier;

/**
 * [CKContainer +defaultContainer]
 *  Get the default iCloud container for the app.
 */
+ (id)hook_defaultContainer;

- (void)startMonitorInjection:processName;


- (void)hook_AllSecItem;
- (void)hook_AllSecCode:teamIdentifier;

@end

#endif /* CommonRetOC_h */
