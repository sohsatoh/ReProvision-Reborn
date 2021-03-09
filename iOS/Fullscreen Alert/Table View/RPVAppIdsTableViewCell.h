//
//  RPVAppIdsTableViewCell.h
//  iOS
//
//  Created by soh on 2021/03/09.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RPVAppID.h"

@interface RPVAppIdsTableViewCell : UITableViewCell

- (void)configureWithAppID:(id)appID fallbackDisplayName:(NSString*)fallback andExpiryDate:(NSDate*)date;

@end
