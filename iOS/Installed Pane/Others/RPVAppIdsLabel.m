//
//  RPVAppIdsLabel.m
//  iOS
//
//  Created by soh on 2021/03/08.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

//#import <Foundation/Foundation.h>
#import "RPVAppIdsLabel.h"

#import "RPVAccountChecker.h"
#import "RPVResources.h"

#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad


@implementation RPVAppIdsLabel
- (instancetype)init
{
    return [self initWithFrame:CGRectZero];
}
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLabel];
    }
    return self;
}

-(void)setupLabel {
    self.textColor = [UIColor blackColor];
    self.font = [UIFont systemFontOfSize:IS_IPAD ? 20 : 16 weight:UIFontWeightRegular];
    self.textAlignment = NSTextAlignmentCenter;
    
    self.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(labelTapped)];
    [self addGestureRecognizer:tapGesture];
    
    [self updateText];
}

-(void)updateText {
    self.updating = YES;
    
    [[RPVAccountChecker sharedInstance] listAllApplicationsWithCompletionHandler:^(NSError *error, NSDictionary *plist) {
        if(plist) {
            NSString *text = [NSString stringWithFormat:@"%lu AppIDs found", (unsigned long)[plist[@"appIds"] count]];
            dispatch_async(dispatch_get_main_queue(), ^{
                // update text on main thread
                self.text = text;
            });
        } else {
            self.text = @"AppIDs could not be retrieved";
        }
        self.updating = NO;
    }];
}

-(void)labelTapped {
    //TODO: Show alert to describe what the app id is.
//    if(!self.isUpdating) [self updateText];
}

@end
