//
//  main.m
//  reprovision.postinst
//
//  Created by soh on 2022/10/23.
//  Copyright (c) 2022 Soh Satoh & Matt Clarke. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <spawn.h>

#if TARGET_OS_TV
#define APPLICATION_IDENTIFIER "jp.soh.reprovision.tvos"
#else
#define APPLICATION_IDENTIFIER "jp.soh.reprovision.ios"
#endif

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (void)registerApplicationDictionary:(id)arg1;
- (void)unregisterApplication:(NSURL *)url;
- (void)registerApplication:(NSURL *)url;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;
- (void)openApplicationWithBundleIdentifier:(id)arg1 configuration:(id)arg2 completionHandler:(/*^block*/ id)arg3;
@end

static int run_system(const char *args[]) {
    pid_t pid;
    int stat;
    posix_spawn(&pid, args[0], NULL, NULL, (char **)args, NULL);
    waitpid(pid, &stat, 0);
    return stat;
}

int old_postinst() {
    // Clear Inbox folder
    NSFileManager *manager = [NSFileManager defaultManager];

    NSString *inboxDir = @"/var/mobile/Library/Application Support/Containers/jp.soh.reprovision.ios/Documents/Inbox";
    if ([manager fileExistsAtPath:inboxDir]) {
        [manager removeItemAtPath:inboxDir error:nil];
    }

    // Check if old daemon exists
    if ([manager fileExistsAtPath:@"/usr/bin/reprovisiond"]) {
        printf("Uninstall ReProvision first, and then install ReProvision Reborn from official repo.\n");
        exit(1);
    }

    // Handle the daemon
    printf("(Re)-loading daemon...\n");
    static const char *plist = "/Library/LaunchDaemons/jp.soh.reprovisiond.plist";

    const char *chown[] = { "/usr/sbin/chown", "root", plist, NULL };
    run_system(chown);

    // Unload for an upgrade.
    const char *unload[] = { "/bin/launchctl", "unload", plist, NULL };
    int unload_status = run_system(unload);
    if (unload_status != 0) {
        const char *unload2[] = { "/sbin/launchctl", "unload", plist, NULL };
        run_system(unload2);
    }

    // Load
    const char *load[] = { "/bin/launchctl", "load", plist, NULL };
    int load_status = run_system(load);
    if (load_status != 0) {
        const char *load2[] = { "/sbin/launchctl", "load", plist, NULL };
        run_system(load2);
    }

    // Reload Application Cache
    const char *uicache[] = { "uicache", "-p", "/Applications/ReProvision.app", NULL };
    run_system(uicache);
}

static void updateAppPlistCache(NSMutableDictionary *newInfoDict, NSString *path) {
    printf("Updating the cache for RR...\n");
    LSApplicationWorkspace *workspace = [LSApplicationWorkspace defaultWorkspace];
    if (workspace != nil) {
        [workspace unregisterApplication:[NSURL fileURLWithPath:path]];
        if ([workspace respondsToSelector:@selector(registerApplicationDictionary:)]) {
            [workspace registerApplicationDictionary:newInfoDict];
        } else {
            [workspace registerApplication:[NSURL fileURLWithPath:path]];
        }

        const char *uicache[] = { "uicache", "-p", "/Applications/ReProvision.app", NULL };
        run_system(uicache);
    }
}

static void checkAndUpdateAppPlist() {
    printf("Checking background signing settings...\n");
    CFPreferencesAppSynchronize(CFSTR(APPLICATION_IDENTIFIER));
    CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR(APPLICATION_IDENTIFIER), CFSTR("mobile"), kCFPreferencesAnyHost);
    if (keyList) {
        CFDictionaryRef dictionary = CFPreferencesCopyMultiple(keyList, CFSTR(APPLICATION_IDENTIFIER), CFSTR("mobile"), kCFPreferencesAnyHost);
        NSDictionary *settings = [(__bridge NSDictionary *)dictionary copy];
        if (settings[@"resign"]) {
            BOOL resignEnabled = [settings[@"resign"] boolValue];
            NSString *appPath = @"/Applications/ReProvision.app";
            NSString *appPlistPath = [NSString stringWithFormat:@"%@/Info.plist", appPath];
            NSDictionary *infoDict = [NSDictionary dictionaryWithContentsOfFile:appPlistPath];
            NSError *getAttrErr;
            NSDictionary<NSFileAttributeKey, id> *originalAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:appPlistPath error:&getAttrErr];
            NSMutableDictionary *newInfoDict = [infoDict mutableCopy];


            NSMutableArray *backgroundModes = [@[] mutableCopy];
            if (resignEnabled) {
                backgroundModes = [@[@"continuous", @"unboundedTaskCompletion"] mutableCopy];
            }
            [newInfoDict setObject:backgroundModes forKey:@"UIBackgroundModes"];

            if (![infoDict isEqualToDictionary:[newInfoDict copy]]) {
                BOOL success = [newInfoDict writeToFile:appPlistPath atomically:YES];
                if (success & !getAttrErr) {
                    NSError *setAttrErr;
                    [[NSFileManager defaultManager] setAttributes:originalAttributes ofItemAtPath:appPlistPath error:&setAttrErr];
                    NSString *message = @"could not overwrite Info.plist";
                    if (!setAttrErr) message = @"successfully overwrite Info.plist";
                    const char *c_message = [message UTF8String];
                    printf("%s\n", c_message);
                    updateAppPlistCache(newInfoDict, appPath);
                }
            } else {
                printf("No need to update Info.plist...\n");
            }
        }
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        old_postinst();
        checkAndUpdateAppPlist();
    }
    return 0;
}
