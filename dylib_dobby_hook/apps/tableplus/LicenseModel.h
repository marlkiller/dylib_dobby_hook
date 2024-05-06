//
//  LicenseModel.h
//  dylib_dobby_hook
//
//  Created by 马治武 on 2024/1/15.
//

#import "Mapper.h"

@interface LicenseModel : Mapper {
    NSString * _sign;
    NSString * _email;
    NSString * _deviceID;
    NSString * _purchasedAt;
    double _nextChargeAt;
    NSString * _updatesAvailableUntil;
}
@property (copy,nonatomic) NSString * sign;
@property (copy,nonatomic) NSString * email;
@property (copy,nonatomic) NSString * deviceID;
@property (copy,nonatomic) NSString * purchasedAt;
@property (nonatomic) double nextChargeAt;
@property (copy,nonatomic) NSString * updatesAvailableUntil;
//- (void).cxx_destruct;
@end
