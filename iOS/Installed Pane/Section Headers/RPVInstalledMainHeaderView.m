//
//  RPVInstalledMainHeaderView.m
//  iOS
//
//  Created by Matt Clarke on 09/01/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "RPVInstalledMainHeaderView.h"

@interface RPVInstalledMainHeaderView ()

@property (nonatomic, strong) UIView *titleView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *button;

@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

static CGFloat titleSize = 36;
static CGFloat dateSize = 18;
static CGFloat inset = 20;

@implementation RPVInstalledMainHeaderView

- (void)_configureViewsIfNecessary {
    if(!self.titleView) {
        self.titleView = [[UIView alloc] initWithFrame:CGRectZero];
        self.titleView.backgroundColor = [UIColor clearColor];
        [self addSubview:self.titleView];
    }

    if (!self.titleLabel) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.titleLabel.text = @"TITLE";
        self.titleLabel.font = [UIFont systemFontOfSize:33 weight:UIFontWeightBold];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textColor = [UIColor whiteColor];

        [self.titleView addSubview:self.titleLabel];
    }

    if(!self.button) {
        self.button = [UIButton buttonWithType:UIButtonTypeCustom];
        self.button.backgroundColor = [UIColor colorWithRed:240.0/255.0 green:240.0/255.0 blue:248.0/255.0 alpha:1.0];

        [self.button setTitle:@"Add" forState:UIControlStateNormal];

        [self.button setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0] forState:UIControlStateNormal];
        [self.button setTitleColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:0.5] forState:UIControlStateHighlighted];

        self.button.titleLabel.font = [UIFont boldSystemFontOfSize:14];

        self.button.layer.cornerRadius = 28.0/2.0;

        [self.button addTarget:self action:@selector(_buttonWasTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.button addTarget:self action:@selector(_buttonWasHighlighted:) forControlEvents:UIControlEventTouchDown];
        [self.button addTarget:self action:@selector(_buttonNotHighlighted:) forControlEvents:UIControlEventTouchUpOutside];

        [self.titleView addSubview:self.button];
    }

    if (!self.dateLabel) {
        self.dateLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.dateLabel.font = [UIFont boldSystemFontOfSize:12];
        self.dateLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.5];

        [self addSubview:self.dateLabel];

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"EEEE d MMMM"];

        self.dateLabel.text = [self _formattedDateForNow];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signingDidBegin:) name:@"jp.soh.reprovision/signingInProgress" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_signingDidComplete:) name:@"jp.soh.reprovision/signingComplete" object:nil];
}

// Disable button when signing is in progress!
- (void)_signingDidBegin:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.button.enabled = NO;
        self.button.alpha = 0.5;
    });
}

// And re-enable if needed
- (void)_signingDidComplete:(id)sender {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.button.alpha = self.button.enabled ? 1.0 : 0.5;
    });
}

- (NSString*)_formattedDateForNow {
    NSDate *now = [NSDate date];
    return [[self.dateFormatter stringFromDate:now] uppercaseString];
}

- (void)configureWithTitle:(NSString*)title {
    [self _configureViewsIfNecessary];

    self.titleLabel.text = title;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat buttonTextMargin = 20;
    CGFloat insetMargin = 20;

    self.titleView.frame = CGRectMake(0, self.frame.size.height - titleSize - (inset / 4), self.frame.size.width, titleSize);

    self.titleLabel.frame = CGRectMake(inset, 0, self.titleView.frame.size.width - (inset * 2), self.titleView.frame.size.height);

    [self.button sizeToFit];
    self.button.frame = CGRectMake(self.frame.size.width - insetMargin - self.button.frame.size.width - (buttonTextMargin * 2), self.titleView.frame.size.height/2 - 28/2, self.button.frame.size.width + (buttonTextMargin * 2), 28);
    for (CALayer *layer in self.button.layer.sublayers) {
        layer.frame = self.button.bounds;
    }

    self.dateLabel.frame = CGRectMake(inset, self.frame.size.height - self.titleLabel.frame.size.height - (inset / 2) - dateSize, self.frame.size.width - (inset * 2), dateSize);
}

- (void)_buttonWasHighlighted:(id)sender {
    self.button.alpha = 0.75;
}

- (void)_buttonNotHighlighted:(id)sender {
    self.button.alpha = 1.0;
}

- (void)_buttonWasTapped:(id)sender {
    [self.delegate installButtonTapped];
    [self _buttonNotHighlighted:nil]; // Reset background colour
}

@end
