//
//  RPVAppIdsLabel.m
//  iOS
//
//  Created by soh on 2021/03/08.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVAppIdsLabel.h"

#import "RPVAccountChecker.h"
#import "RPVResources.h"

#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad


@implementation RPVAppIdsLabel
- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLabel];
    }
    return self;
}

- (void)setupLabel {
    self.textColor = [UIColor blackColor];
    self.font = [UIFont systemFontOfSize:IS_IPAD ? 20 : 16 weight:UIFontWeightRegular];
    self.textAlignment = NSTextAlignmentCenter;
    self.alertController = [[RPVAppIDViewController alloc] init];

    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(labelTapped)];
    [self addGestureRecognizer:tapGesture];

    [self updateText];
}

- (void)updateText {
    self.updating = YES;

    [[RPVAccountChecker sharedInstance] listAllApplicationsWithCompletionHandler:^(NSError *error, NSArray *appIds) {
        if (appIds) {
            NSMutableArray *appIdsMutableArray = [appIds mutableCopy];
            NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"applicationExpiryDate" ascending:YES];
            [appIdsMutableArray sortUsingDescriptors:@[sortByDate]];
            self.alertController.appIdsDataSource = appIdsMutableArray;

            NSString *text = [NSString stringWithFormat:@"%lu App IDs found", (unsigned long)[appIdsMutableArray count]];
            dispatch_async(dispatch_get_main_queue(), ^{
                // update text on main thread
                self.text = text;
                [self.alertController.appIdsTableView reloadData];
                [self.alertController.view setNeedsLayout];
            });
        } else {
            self.text = @"App IDs could not be retrieved";
            self.alertController.appIdsDataSource = nil;
        }
        self.updating = NO;
    }];
}

- (void)labelTapped {
    // Open fullscreen alert
    if (self.updating) return;
    self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    self.alertController.onDismiss = ^{
        [UIView animateWithDuration:0.25 animations:^{
            self.alertWindow.alpha = 0.0;
        } completion:^(BOOL finished) {
            if (finished) {
                [self.alertWindow setHidden:YES];
                self.alertWindow = nil;
            }
        }];
    };

    self.alertWindow.rootViewController = self.alertController;
    self.alertWindow.windowLevel = UIWindowLevelStatusBar;
    self.alertWindow.alpha = 0;
    [self.alertWindow setTintColor:[UIColor colorWithRed:147.0 / 255.0 green:99.0 / 255.0 blue:207.0 / 255.0 alpha:1.0]];

    [self.alertWindow makeKeyAndVisible];

    [UIView animateWithDuration:0.25 animations:^{
        self.alertWindow.alpha = 1.0;
    } completion:^(BOOL finished){
        // do something...
    }];
}

@end
