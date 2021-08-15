//
//  RPVEntitlementsViewController.m
//  iOS
//
//  Created by soh on 2021/08/16.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVEntitlementsViewController.h"
#import "EESigning.h"

@implementation RPVEntitlementsViewController

- (void)loadView {
    [super loadView];

    self.titleLabel.text = @"Entitlements";

    self.entitlementsView = [[UITextView alloc] initWithFrame:CGRectZero];
    self.entitlementsView.editable = NO;
    self.entitlementsView.textAlignment = NSTextAlignmentLeft;
    self.entitlementsView.backgroundColor = [UIColor colorWithRed:0.09 green:0.11 blue:0.13 alpha:1.00];
    self.entitlementsView.textColor = [UIColor colorWithRed:0.79 green:0.82 blue:0.85 alpha:1.00];
    self.entitlementsView.font = [UIFont fontWithName:@"Menlo-Regular" size:12.0];

    [self.bodyContainerView addSubview:self.entitlementsView];

    [self layoutWithSize:[UIScreen mainScreen].bounds.size];
}

- (void)layoutWithSize:(CGSize)size {
    [super layoutWithSize:size];

    self.entitlementsView.frame = CGRectMake(0, 0, self.bodyContainerView.frame.size.width, self.bodyContainerView.frame.size.height);
}

- (void)updateEntitlementsViewForBinaryAtLocation:(NSString *)location {
    NSMutableDictionary *entitlements = [EESigning getEntitlementsForBinaryAtLocation:location];
    if (entitlements) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.entitlementsView.text = [entitlements description];
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.entitlementsView.text = @"Error";
        });
    }
}
@end
