//
//  dylib_dobby_hook.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/14.
//

#import "dylib_dobby_hook.h"
#import "dobby.h"
#import "Constant.h"
#import "MemoryUtils.h"
#import <Cocoa/Cocoa.h>

@implementation dylib_dobby_hook

#ifdef DEBUG
const bool SHOW_ALARM = true;
#else
const bool SHOW_ALARM = false;
#endif

// INIT TEST START
int sum(int a, int b) {
    return a+b;
}
//函数指针用于保存被替换函数的地址
static int (*sum_p)(int a, int b);

//新函数
int mySum(int a,int b){
    return a - b;
}
void initTest(void){
    
    NSLog(@"before %d", sum(1, 2));
    NSLog(@"%s", DobbyGetVersion());
//    DobbyHook(sum, mySum, (void *)&sum_p);
    DobbyHook(sum, mySum, nil);
    NSLog(@"after %d", sum(1, 2));
//    NSLog(@"origin %d", sum_p(1, 2));
    
}
// INIT TEST END


+ (void) load {
    
    
//    initTest();
    NSLog(@">>>>>> dylib_dobby_hook load");
    if ([Constant isFirstOpen] && ![Constant isHelper]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"Cracked By\n[marlkiller/dylib_dobby_hook]"];
        [alert setInformativeText:@"仅供研究学习使用，请勿用于非法用途"];
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    }
    if (SHOW_ALARM && ![Constant isHelper]) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"FBI warning"];
        [alert setInformativeText:@"Please confirm if the app has been backed up.\nIf there are any issues, please restore it yourself!"];
        [alert addButtonWithTitle:@"Confirm"];
        [alert addButtonWithTitle:@"Cancel"];
        NSInteger response = [alert runModal];
        if (response == NSAlertFirstButtonReturn) {
            [Constant doHack];
        } else {
            return;
        }
    }else {
        [Constant doHack];
    }
}
@end
