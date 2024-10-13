//
//  LocalizationManager.h
//  dylib_dobby_hook
//
//  Created by voidm on 2024/10/11.
//

#ifndef LocalizationManager_h
#define LocalizationManager_h
#import <Foundation/Foundation.h>


@interface LocalizationManager : NSObject

+ (NSString *)localizedStringForKey:(NSString *)key;

@end


#endif /* LocalizationManager_h */
