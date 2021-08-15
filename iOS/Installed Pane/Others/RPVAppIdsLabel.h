//
//  RPVAppIdsLabel.h
//  iOS
//
//  Created by soh on 2021/03/08.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RPVAppIDViewController.h"

@interface RPVAppIdsLabel : UILabel
@property (nonatomic, getter=isUpdating) BOOL updating;
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, strong) RPVAppIDViewController *alertController;
- (void)updateText;
@end
