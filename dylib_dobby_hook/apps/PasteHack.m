#import <Foundation/Foundation.h>
#import "Constant.h"
#import "dobby.h"
#import "MemoryUtils.h"
#import <objc/runtime.h>
#import "common_ret.h"
#import "HackProtocolDefault.h"

@interface PasteHack : HackProtocolDefault

@end

@implementation PasteHack


- (NSString *)getAppName {
    return @"com.wiheads.paste";
}

- (NSString *)getSupportAppVersion {
    return @"4.";
}

int (*validSubscriptionOri)(void);

//int validSubscriptionNew(int arg0, int arg1) {
//    return 1;
//}
//int _cloudKitNew(int arg0, int arg1) {
//    return 1;
//}

- (int) hook_ubiquityIdentityToken {
    NSLog(@">>>>>> hook_ubiquityIdentityToken");
    return 0;
}

- (BOOL)hack {

    // 有効なサブスクリプションをフックする
    //    intptr_t validSubscription = [MemoryUtils getPtrFromAddress:0x1002e14dc];
    //    DobbyHook(validSubscription, validSubscriptionNew, (void *)&validSubscriptionOri);
    // cloudkitをフックする
    //    intptr_t _cloudKit = [MemoryUtils getPtrFromAddress:0x1002b7a68];
    //    DobbyHook(_cloudKit, ret1, (void *)&_cloudKitOri);
    
    [MemoryUtils hookInstanceMethod:objc_getClass("NSFileManager") originalSelector:NSSelectorFromString(@"ubiquityIdentityToken") swizzledClass:[self class] swizzledSelector:NSSelectorFromString(@"hook_ubiquityIdentityToken")];
    
    NSString *searchFilePath = [[Constant getCurrentAppPath] stringByAppendingString:@"/Contents/MacOS/Paste"];
    uintptr_t fileOffset =[MemoryUtils getCurrentArchFileOffset: searchFilePath];
    
    // 有効なサブスクリプションかどうか
    hookSubscription(searchFilePath, fileOffset);
    
    
    // これらの重要なiCloudとCloudKit関連のメソッドをフックすることで、開発者はアプリケーションが再署名された後に潜在的なクラッシュを適切に処理し、アプリケーションの他の部分が正常に動作し続けることを確保できます。これは、元のiCloudサービスに正常にアクセスできない場合の対応戦略です。
    // 参照：dylib_dobby_hook/utils/CommonRetOC.m
    
    // アプリケーションとiCloud key-valueストレージとの相互作用を制御または監視する
    [MemoryUtils hookClassMethod:
         NSClassFromString(@"NSUbiquitousKeyValueStore")
                originalSelector:NSSelectorFromString(@"defaultStore") swizzledClass:[self class] swizzledSelector:@selector(hook_defaultStore)
    ];
    
    // アプリケーションがiCloudファイルストレージにアクセスする動作を制御または監視する
    [MemoryUtils hookInstanceMethod:
        NSClassFromString(@"NSFileManager")
                originalSelector:NSSelectorFromString(@"URLForUbiquityContainerIdentifier:") swizzledClass:[self class] swizzledSelector:@selector(hook_NSFileManager:)
    ];

    // アプリケーションと特定のCloudKitコンテナとの相互作用を制御または監視する
    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"containerWithIdentifier:") swizzledClass:[self class] swizzledSelector:@selector(hook_containerWithIdentifier: )
    ];
    
    // アプリケーションとデフォルトのCloudKitコンテナとの相互作用を制御または監視する
    [MemoryUtils hookClassMethod:
        NSClassFromString(@"CKContainer")
                  originalSelector:NSSelectorFromString(@"defaultContainer") swizzledClass:[self class] swizzledSelector:@selector(hook_defaultContainer)
    ];
    
    return YES;
}

void hookSubscription(NSString *searchFilePath, uintptr_t fileOffset) {

#if defined(__arm64__) || defined(__aarch64__)
    NSString *sub_0x10031f878Code = @"F8 5F BC A9 F6 57 01 A9 F4 4F 02 A9 FD 7B 03 A9 FD C3 00 91 F5 03 01 AA F6 03 00 AA 57 1B 00 D0 F7 62 29 91";
#elif defined(__x86_64__)
    NSString *sub_0x10031f878Code = @"55 48 89 E5 41 57 41 56 41 54 53 49 89 F7 49 89 FC 48 8D 3D";
#endif
    
    NSArray *globalOffsets =[MemoryUtils searchMachineCodeOffsets:(NSString *)searchFilePath
                                                      machineCode:sub_0x10031f878Code
                                                            count:(int)1];
    uintptr_t globalOffset = [globalOffsets[0] unsignedIntegerValue];
    
    intptr_t validSubscription = [MemoryUtils getPtrFromGlobalOffset:0 targetFunctionOffset:(uintptr_t)globalOffset reduceOffset:(uintptr_t)fileOffset];
    DobbyHook((void *)validSubscription, (void *)ret1, (void *)&validSubscriptionOri);
}

@end
