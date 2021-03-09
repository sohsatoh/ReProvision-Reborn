//
//  RPVAppID.m
//  iOS
//
//  Created by soh on 2021/03/09.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVAppID.h"

@interface RPVAppID ()
@property (nonatomic, strong) NSDictionary *dictionary;
@end

@implementation RPVAppID

- (instancetype)initWithDictionary:(NSDictionary*)dict {
    self = [super init];

    if (self) {
        self.dictionary = dict;
    }

    return self;
}

- (NSString*)identifier {
    return self.dictionary != nil ? self.dictionary[@"identifier"] : @"com.mycompany.example";
}

- (NSString*)applicationName {
    return self.dictionary != nil ? self.dictionary[@"name"] : @"Example";
}

- (NSDate*)applicationExpiryDate {
    if (!self.dictionary) {
        // Date that is 2 days away.
        return [NSDate dateWithTimeIntervalSinceNow:172800];
    }

    return self.dictionary[@"expirationDate"];
}

@end
