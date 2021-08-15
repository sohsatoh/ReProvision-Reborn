//
//  RPVFullscreenAlertController.m
//  iOS
//
//  Created by Matt Clarke on 16/01/2020.
//  Copyright © 2020 Matt Clarke. All rights reserved.
//

#import "RPVFullscreenAlertController.h"

@implementation RPVFullscreenAlertController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];

    self.topBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.topBackgroundView];

    self.topBackgroundGradientLayer = [CAGradientLayer layer];
    self.topBackgroundGradientLayer.frame = CGRectZero;

    UIColor *startColor = [UIColor colorWithRed:147.0 / 255.0 green:99.0 / 255.0 blue:207.0 / 255.0 alpha:1.0];
    UIColor *endColor = [UIColor colorWithRed:116.0 / 255.0 green:158.0 / 255.0 blue:201.0 / 255.0 alpha:1.0];
    self.topBackgroundGradientLayer.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    self.topBackgroundGradientLayer.startPoint = CGPointMake(0.75, 0.75);
    self.topBackgroundGradientLayer.endPoint = CGPointMake(0.25, 0.25);

    [self.topBackgroundView.layer insertSublayer:self.topBackgroundGradientLayer atIndex:0];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:34];

    [self.topBackgroundView addSubview:self.titleLabel];

    self.bodyContainerView = [[UIView alloc] initWithFrame:CGRectZero];
    self.bodyContainerView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.bodyContainerView];

    self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(onDismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton sizeToFit];

    [self.view addSubview:self.dismissButton];

    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.titleLabel.textColor = [UIColor whiteColor];

    [self layoutWithSize:[UIScreen mainScreen].bounds.size];
}

- (void)layoutWithSize:(CGSize)size {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];

    self.topBackgroundView.frame = CGRectMake(0, 0, self.view.bounds.size.width, (statusBarFrame.size.height + 30) * 2);
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.topBackgroundGradientLayer.frame = self.topBackgroundView.bounds;
    [CATransaction commit];

    self.titleLabel.frame = CGRectMake(size.width * 0.1, statusBarFrame.size.height + 30, size.width * 0.8, 60);

    CGFloat safeAreaBottomInset = 34;

    self.dismissButton.frame = CGRectMake(size.width * 0.1, self.view.frame.size.height - self.dismissButton.frame.size.height - safeAreaBottomInset, size.width * 0.8, self.dismissButton.frame.size.height);

    self.bodyContainerView.frame = CGRectMake(size.width * 0.1, self.topBackgroundView.frame.origin.y + self.topBackgroundView.frame.size.height + (statusBarFrame.size.height / 2), size.width * 0.8, size.height - self.topBackgroundView.frame.size.height - statusBarFrame.size.height - self.dismissButton.frame.size.height - safeAreaBottomInset);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self layoutWithSize:size];
}

- (void)onDismiss:(id)sender {
    self.onDismiss();
}

@end
