//
//  RPVInstalledMainHeaderView.h
//  iOS
//
//  Created by Matt Clarke on 09/01/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RPVInstalledViewController.h"

@interface RPVInstalledMainHeaderView : UIView
@property(nonatomic,weak) RPVInstalledViewController *delegate;
- (void)configureWithTitle:(NSString*)title;

@end
