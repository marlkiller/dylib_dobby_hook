//
//  HackCommon.m
//  dylib_dobby_hook
//
//  Created by voidm on 2024/7/27.
//

#import <Foundation/Foundation.h>
#import "HackProtocolDefault.h"
#import <LocalizationManager.h>
#import "UIKit/UIKit.h"

static UIWindow *blockWindow = nil;

@implementation HackProtocolDefault

void ShowPremiumPopup(NSString *titleText,NSString *messageText,NSString *buttonText) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (blockWindow) return;

        UIWindowScene *scene = nil;

        if (@available(iOS 13.0, *)) {
            for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
                if (s.activationState == UISceneActivationStateForegroundActive &&
                    [s isKindOfClass:UIWindowScene.class]) {
                    scene = (UIWindowScene *)s;
                    break;
                }
            }
            if (!scene) return;
            blockWindow = [[UIWindow alloc] initWithWindowScene:scene];
        } else {
            blockWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        }

        blockWindow.frame = UIScreen.mainScreen.bounds;
        blockWindow.windowLevel = UIWindowLevelAlert + 9999;
        blockWindow.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.45];

        UIViewController *root = [UIViewController new];
        root.view.backgroundColor = UIColor.clearColor;
        blockWindow.rootViewController = root;
        [blockWindow makeKeyAndVisible];

        UIView *card = [[UIView alloc] initWithFrame:CGRectMake(30, 0, UIScreen.mainScreen.bounds.size.width - 60, 300)];
        card.center = root.view.center;
        card.backgroundColor = [UIColor colorWithRed:0.10 green:0.11 blue:0.16 alpha:1.0];
        card.layer.cornerRadius = 26;
        card.layer.shadowColor = UIColor.blackColor.CGColor;
        card.layer.shadowOpacity = 0.35;
        card.layer.shadowRadius = 25;
        card.layer.shadowOffset = CGSizeMake(0, 12);
        card.transform = CGAffineTransformMakeScale(0.85, 0.85);
        card.alpha = 0;

        UILabel *badge = [[UILabel alloc] initWithFrame:CGRectMake(20, 22, card.bounds.size.width - 40, 30)];
        badge.text = titleText;
        badge.textAlignment = NSTextAlignmentCenter;
        badge.textColor = [UIColor colorWithRed:1.0 green:0.78 blue:0.25 alpha:1.0];
        badge.font = [UIFont boldSystemFontOfSize:28];

        //UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(20, 65, card.bounds.size.width - 40, 35)];
        //title.text = titleText;
        //title.textAlignment = NSTextAlignmentCenter;
        //title.textColor = UIColor.whiteColor;
        //title.font = [UIFont boldSystemFontOfSize:18];

        UILabel *message = [[UILabel alloc] initWithFrame:CGRectMake(28, 60, card.bounds.size.width - 56, 150)];
        message.text = messageText;
        message.textAlignment = NSTextAlignmentCenter;
        message.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
        message.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
        message.numberOfLines = 0;

        UIButton *okButton = [UIButton buttonWithType:UIButtonTypeSystem];
        okButton.frame = CGRectMake(28, 230, card.bounds.size.width - 56, 52);
        okButton.backgroundColor = [UIColor colorWithRed:0.25 green:0.47 blue:1.0 alpha:1.0];
        okButton.layer.cornerRadius = 16;
        [okButton setTitle:@"OK" forState:UIControlStateNormal];
        [okButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        okButton.titleLabel.font = [UIFont boldSystemFontOfSize:17];

        [okButton addAction:[UIAction actionWithHandler:^(__kindof UIAction * _Nonnull action) {
            [UIView animateWithDuration:0.2 animations:^{
                card.alpha = 0;
                blockWindow.alpha = 0;
            } completion:^(BOOL finished) {
                blockWindow.hidden = YES;
                blockWindow.rootViewController = nil;
                blockWindow = nil;
            }];
        }] forControlEvents:UIControlEventTouchUpInside];

        [card addSubview:badge];
        //[card addSubview:title];
        [card addSubview:message];
        [card addSubview:okButton];
        [root.view addSubview:card];

        [UIView animateWithDuration:0.32
                              delay:0
             usingSpringWithDamping:0.78
              initialSpringVelocity:0.8
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            card.alpha = 1;
            card.transform = CGAffineTransformIdentity;
        } completion:nil];
    });
}


- (void)firstLaunch{
        ShowPremiumPopup([LocalizationManager localizedStringForKey:@"alert_tip"],[LocalizationManager localizedStringForKey:@"alert_message"],[LocalizationManager localizedStringForKey:@"alert_button"]);
};


@end

