//
//  dylib_dobby_hook.m
//  dylib_dobby_hook
//
//  Created by artemis on 2024/1/14.
//

#import "dylib_dobby_hook.h"
#import "dobby.h"
#import <Cocoa/Cocoa.h>

@implementation dylib_dobby_hook


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
void init(){
    
    NSLog(@"before %d", sum(1, 2));
    NSLog(@"%s", DobbyGetVersion());
    DobbyHook(sum, mySum, (void *)&sum_p);
    NSLog(@"after %d", sum(1, 2));
    NSLog(@"origin %d", sum_p(1, 2));
    
}
// INIT TEST END



void AirBuddy() {
    
}

+ (void) load {
    
    
    init();
    
    NSString *appName = [[NSBundle mainBundle] bundleIdentifier];
    const char *myAppBundleName = [appName UTF8String];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"确认执行破解操作吗？"];
    [alert addButtonWithTitle:@"确认"];
    [alert addButtonWithTitle:@"取消"];
    NSInteger response = [alert runModal];
    
    if (response == NSAlertFirstButtonReturn) {
        // 用户选择了确认按钮
        AirBuddy();
    } else {
        // 用户选择了取消按钮
        return;
    }
    
    
}
@end
