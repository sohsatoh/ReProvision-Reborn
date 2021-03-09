//
//  RPVAppID.h
//  iOS
//
//  Created by soh on 2021/03/09.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RPVAppID : NSObject

// Don't call this yourself.
- (instancetype)initWithDictionary:(NSDictionary*)dict;

- (NSString*)identifier;
- (NSString*)applicationName;

- (NSDate*)applicationExpiryDate;
@end
