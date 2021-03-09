//
//  RPVAccountChecker.m
//  iOS
//
//  Created by Matt Clarke on 07/03/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "RPVAccountChecker.h"
#import "RPVResources.h"
#import "RPVAppID.h"
#import "EEAppleServices.h"
#import "EEBackend.h"

#import <UIKit/UIKit.h>
#import "libMobileGestalt.h"

@implementation RPVAccountChecker

+ (instancetype)sharedInstance {
    static RPVAccountChecker *sharedInstance = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
        sharedInstance = [[RPVAccountChecker alloc] init];
    });
    return sharedInstance;
}

// Returns a failure reason, failure code, or team ID array
- (void)checkUsername:(NSString*)username withPassword:(NSString*)password andCompletionHandler:(void (^)(NSString*, NSString*, NSArray*, NSURLCredential*))completionHandler {

    [[EEAppleServices sharedInstance] signInWithUsername:username password:password andCompletionHandler:^(NSError *error, NSDictionary *plist, NSURLCredential *credentials) {

         if (error) {
             completionHandler(error.localizedDescription, @"err", nil,nil);
             return;
         }

         NSString *resultCode = [plist objectForKey:@"reason"];
         NSString *userString = [plist objectForKey:@"userString"];

         if ((!userString || [userString isEqualToString:@""]) && plist) {
             // Get Team ID array
             [[EEAppleServices sharedInstance] listTeamsWithCompletionHandler:^(NSError *error, NSDictionary *plist) {
                  if (error) {
                      completionHandler(error.localizedDescription, @"err", nil,nil);
                      return;
                  }

                  NSArray *teams = [plist objectForKey:@"teams"];
                  if (teams.count == 0) {
                      completionHandler(@"Please accept the Apple Developer terms at https://developer.apple.com", resultCode, teams,nil);
                  } else {
                      NSString *userString = [plist objectForKey:@"userString"];
                      completionHandler(userString, resultCode, teams, credentials);
                  }
              }];
         } else if (plist) {
             completionHandler(userString, resultCode, nil, credentials);
         } else {
             completionHandler(nil, @"err", nil, credentials);
         }
     }];
}

- (void)requestLoginCodeWithCompletionHandler:(void (^)(NSError *error))completion {
    [[EEAppleServices sharedInstance] requestTwoFactorLoginCodeWithCompletionHandler:completion];
}

- (void)validateLoginCode:(NSString*)code withCompletionHandler:(void (^)(NSString*, NSString*, NSArray*, NSURLCredential*))completionHandler {
    [[EEAppleServices sharedInstance] validateLoginCode:code andCompletionHandler:^(NSError *error, NSDictionary *plist, NSURLCredential *credentials) {

         if (error) {
             completionHandler(error.localizedDescription, @"err", nil,nil);
             return;
         }

         NSString *resultCode = [plist objectForKey:@"reason"];
         NSString *userString = [plist objectForKey:@"userString"];

         if ((!userString || [userString isEqualToString:@""]) && plist) {
             // Get Team ID array
             [[EEAppleServices sharedInstance] listTeamsWithCompletionHandler:^(NSError *error, NSDictionary *plist) {
                  if (error) {
                      completionHandler(error.localizedDescription, @"err", nil,nil);
                      return;
                  }

                  NSArray *teams = [plist objectForKey:@"teams"];
                  if (teams.count == 0) {
                      completionHandler(@"Please accept the Apple Developer terms at https://developer.apple.com", resultCode, teams,nil);
                  } else {
                      NSString *userString = [plist objectForKey:@"userString"];
                      completionHandler(userString, resultCode, teams, credentials);
                  }
              }];
         } else if (plist) {
             completionHandler(userString, resultCode, nil, credentials);
         } else {
             completionHandler(nil, @"err", nil, credentials);
         }
     }];
}

- (void)request2FAFallbackWithCompletionHandler:(void (^)(NSString*, NSString*, NSArray*, NSURLCredential*))completionHandler {
    [[EEAppleServices sharedInstance] fallback2FACodeRequest:^(NSError *error, NSDictionary *plist, NSURLCredential *credentials) {

         if (error) {
             completionHandler(error.localizedDescription, @"err", nil,nil);
             return;
         }

         NSString *resultCode = [plist objectForKey:@"reason"];
         NSString *userString = [plist objectForKey:@"userString"];

         if ((!userString || [userString isEqualToString:@""]) && plist) {
             // Get Team ID array
             [[EEAppleServices sharedInstance] listTeamsWithCompletionHandler:^(NSError *error, NSDictionary *plist) {
                  if (error) {
                      completionHandler(error.localizedDescription, @"err", nil,nil);
                      return;
                  }

                  NSArray *teams = [plist objectForKey:@"teams"];
                  if (teams.count == 0) {
                      completionHandler(@"Please accept the Apple Developer terms at https://developer.apple.com", resultCode, teams,nil);
                  } else {
                      NSString *userString = [plist objectForKey:@"userString"];
                      completionHandler(userString, resultCode, teams, credentials);
                  }
              }];
         } else if (plist) {
             completionHandler(userString, resultCode, nil, credentials);
         } else {
             completionHandler(nil, @"err", nil, credentials);
         }
     }];
}

- (NSString*)nameForCurrentDevice {
    return [[UIDevice currentDevice] name];
}

- (NSString*)UDIDForCurrentDevice {
    CFStringRef udid = (CFStringRef)MGCopyAnswer(kMGUniqueDeviceID);
    return (__bridge NSString*)udid;
}

- (EESystemType)platformTypeForCurrentDevice {
#if TARGET_OS_IOS
    return EESystemTypeiOS;
#elif TARGET_OS_WATCHOS
    return EESystemTypewatchOS;
#elif TARGET_OS_TV
    return EESystemTypetvOS;
#endif
}

- (void)registerCurrentDeviceForTeamID:(NSString*)teamID withIdentity:(NSString*)identity gsToken:(NSString*)gsToken andCompletionHandler:(void (^)(NSError*))completionHandler {

    [EEBackend provisionDevice:[self UDIDForCurrentDevice] name:[self nameForCurrentDevice] identity:identity gsToken:gsToken priorChosenTeamID:teamID systemType:[self platformTypeForCurrentDevice] withCallback:^(NSError *error) {
         completionHandler(error);
     }];
}

- (void)registerCurrentWatchForTeamID:(NSString*)teamID withIdentity:(NSString*)identity gsToken:(NSString*)gsToken andCompletionHandler:(void (^)(NSError*))completionHandler {

    [EEBackend provisionDevice:[RPVResources activePairedWatchUDID] name:[RPVResources activePairedWatchName] identity:identity gsToken:gsToken priorChosenTeamID:teamID systemType:EESystemTypewatchOS withCallback:^(NSError *error) {
         completionHandler(error);
     }];
}

- (void)listAllApplicationsWithCompletionHandler:(void (^)(NSError*, NSArray *))completionHandler {
    if(![RPVResources getUsername] || ![RPVResources getPassword] || ![RPVResources getTeamID]) {
        // username, password or teamID is nil
        completionHandler(nil, nil);
        return;
    }

    [[EEAppleServices sharedInstance] ensureSessionWithIdentity:[RPVResources getUsername] gsToken:[RPVResources getPassword] andCompletionHandler:^(NSError *error, NSDictionary *plist) {
         if(!error && plist) {
             [[EEAppleServices sharedInstance] listAllApplicationsForTeamID:[RPVResources getTeamID] systemType:[self platformTypeForCurrentDevice] withCompletionHandler:^(NSError *error, NSDictionary *dict) {
                  // dictionary -> array of RPVAppID
                  NSMutableArray *appIds = [NSMutableArray array];
                  if(!error && dict) {
                      for (NSDictionary* apps in dict[@"appIds"]) {
                          RPVAppID *appId = [[RPVAppID alloc] initWithDictionary:apps];
                          [appIds addObject:appId];
                      }
                      completionHandler(nil, [appIds copy]);
                  } else completionHandler(error, nil);
              }];
         } else {
             completionHandler(error, nil);
         }
     }];

}

@end
