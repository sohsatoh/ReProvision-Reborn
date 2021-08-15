//
//  RPVEntitlementsViewController.h
//  iOS
//
//  Created by soh on 2021/08/16.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVFullscreenAlertController.h"

@interface RPVEntitlementsViewController : RPVFullscreenAlertController
@property (nonatomic, strong) UITextView *entitlementsView;
- (void)updateEntitlementsViewForBinaryAtLocation:(NSString *)location;
@end