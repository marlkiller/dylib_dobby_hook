//
//  HackCommon.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "HackProtocolDefault.h"
#if TARGET_OS_OSX
#import <Cocoa/Cocoa.h>
#endif

#import <LocalizationManager.h>
@implementation HackProtocolDefault

- (void)firstLaunch{    
    NSAlert *alert = [[NSAlert alloc] init];
    NSString *alertTip = [LocalizationManager localizedStringForKey:@"alert_tip"];
    NSString *alertMessage = [LocalizationManager localizedStringForKey:@"alert_message"];
    NSString *alertButtonTitle = [LocalizationManager localizedStringForKey:@"alert_button"];
    
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert setMessageText:alertTip];
    [alert setInformativeText:alertMessage];
    [alert addButtonWithTitle:alertButtonTitle];
    [alert runModal];
};

@end

