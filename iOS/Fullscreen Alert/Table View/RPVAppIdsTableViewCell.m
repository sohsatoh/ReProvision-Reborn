//
//  RPVAppIdsTableViewCell.m
//  iOS
//
//  Created by soh on 2021/03/09.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//
//

#import "RPVAppIdsTableViewCell.h"
#import "RPVApplication.h"
#import "RPVResources.h"

#import <MarqueeLabel.h>

#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

@interface RPVAppIdsTableViewCell ()

@property (nonatomic, readwrite) BOOL noApplicationsInThisSection;

@property (nonatomic, strong) NSDate *expiryDate;

@property (nonatomic, strong) MarqueeLabel *displayNameLabel;
@property (nonatomic, strong) MarqueeLabel *identifierLabel;
@property (nonatomic, strong) NSString *identifier;

@property (nonatomic, strong) MarqueeLabel *timeRemainingLabel;

@end

static CGFloat inset = 20;

@implementation RPVAppIdsTableViewCell
- (void)layoutSubviews {
    [super layoutSubviews];

    self.contentView.frame = CGRectMake(0, inset/3.0, self.frame.size.width, self.frame.size.height - inset/1.5);

    if (!self.noApplicationsInThisSection) {
        CGFloat xInset = 10;
        CGFloat yInset = 10;

        CGFloat displayNameHeight = IS_IPAD ? 27 : 18;
        self.displayNameLabel.frame = CGRectMake(xInset + xInset*1.25, (self.contentView.frame.size.height/2) - displayNameHeight + 2, self.contentView.frame.size.width - (xInset + 25), displayNameHeight);

        CGFloat identifierHeight = IS_IPAD ? 22.5 : 15;
        CGRect timeRemainingRect = [RPVResources boundedRectForFont:self.timeRemainingLabel.font andText:self.timeRemainingLabel.text width:self.contentView.frame.size.width - (self.displayNameLabel.frame.origin.x + 20)];

        self.timeRemainingLabel.frame = CGRectMake(self.contentView.frame.size.width - 25 - timeRemainingRect.size.width, (self.contentView.frame.size.height/2) + 3, timeRemainingRect.size.width + 10, identifierHeight);

        self.identifierLabel.frame = CGRectMake(self.displayNameLabel.frame.origin.x, (self.contentView.frame.size.height/2) + 4, self.contentView.frame.size.width - (xInset + xInset*1.25 + 10 + self.timeRemainingLabel.frame.size.width), identifierHeight);

    } else {
        self.displayNameLabel.frame = self.contentView.bounds;
    }
}

- (void)_setupUIIfNecessary {
    if (!self.displayNameLabel) {
        self.displayNameLabel = [[MarqueeLabel alloc] initWithFrame:CGRectZero];

        self.displayNameLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 20 : 16 weight:UIFontWeightBold];
        self.displayNameLabel.text = @"DISPLAY_NAME";
        self.displayNameLabel.numberOfLines = 0;

        // MarqueeLabel specific
        self.displayNameLabel.fadeLength = 8.0;
        self.displayNameLabel.trailingBuffer = 10.0;

        [self.contentView addSubview:self.displayNameLabel];
    }

    if (!self.identifierLabel) {
        self.identifierLabel = [[MarqueeLabel alloc] initWithFrame:CGRectZero];

        self.identifierLabel.text = @"BUNDLE_IDENTIFIER";
        self.identifierLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 12.5 : 11 weight:UIFontWeightRegular];

        // MarqueeLabel specific
        self.identifierLabel.fadeLength = 8.0;
        self.identifierLabel.trailingBuffer = 10.0;

        [self.contentView addSubview:self.identifierLabel];
    }

    if (!self.timeRemainingLabel) {
        self.timeRemainingLabel = [[MarqueeLabel alloc] initWithFrame:CGRectZero];

        self.timeRemainingLabel.text = @"TIME_REMAINING";
        self.timeRemainingLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 14 : 12 weight:UIFontWeightMedium];
        self.timeRemainingLabel.textAlignment = NSTextAlignmentRight;

        // MarqueeLabel specific
        self.timeRemainingLabel.fadeLength = 8.0;
        self.timeRemainingLabel.trailingBuffer = 10.0;

        [self.contentView addSubview:self.timeRemainingLabel];
    }

    // Reset text colours if needed
    self.displayNameLabel.textColor = [UIColor blackColor];
    self.displayNameLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 20 : 16 weight:UIFontWeightBold];
    self.displayNameLabel.textAlignment = NSTextAlignmentLeft;
    self.displayNameLabel.labelize = NO;

    self.identifierLabel.textColor = [UIColor grayColor];
    self.timeRemainingLabel.textColor = [UIColor grayColor];

    // Reset hidden states if needed
    self.identifierLabel.hidden = NO;
    self.timeRemainingLabel.hidden = NO;

    self.contentView.clipsToBounds = YES;
    self.contentView.layer.cornerRadius = 12.5;

    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)configureWithAppID:(RPVAppID*)appID fallbackDisplayName:(NSString*)fallback andExpiryDate:(NSDate*)date {
    [self _setupUIIfNecessary];

    if (!appID) {
        self.expiryDate = nil;
        self.identifier = @"";

        // No application to display
        self.displayNameLabel.textColor = [UIColor darkGrayColor];
        self.displayNameLabel.font = [UIFont systemFontOfSize:IS_IPAD ? 20 : 16 weight:UIFontWeightRegular];
        self.displayNameLabel.textAlignment = NSTextAlignmentCenter;
        self.displayNameLabel.labelize = YES;

        // Set hidden state
        self.identifierLabel.hidden = YES;
        self.timeRemainingLabel.hidden = YES;

        self.noApplicationsInThisSection = YES;

        self.displayNameLabel.text = fallback;
        self.identifierLabel.text = @"";
        self.timeRemainingLabel.text = @"";
    } else {
        self.expiryDate = date;

        self.identifier = [appID identifier];
        self.noApplicationsInThisSection = NO;

        self.displayNameLabel.text = [appID applicationName];
        self.identifierLabel.text = [appID identifier];

        self.timeRemainingLabel.text = [RPVResources getFormattedTimeRemainingForExpirationDate:self.expiryDate];
    }

    // Make sure MarqueeLabel is working as expected at all times.
    [self.displayNameLabel restartLabel];
    [self.identifierLabel restartLabel];
    [self.timeRemainingLabel restartLabel];

    // And relayout if needed.
    [self setNeedsLayout];
}

@end
