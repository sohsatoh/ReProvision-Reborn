//
//  AppDelegate.m
//  ReProvision
//
//  Created by Matt Clarke on 08/01/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "AppDelegate.h"
#import "RPVBackgroundSigningManager.h"
#import "RPVDaemonProtocol.h"
#import "RPVNotificationManager.h"
#import "RPVResources.h"

#import "RPVApplicationDatabase.h"
#import "RPVApplicationDetailController.h"
#import "RPVIpaBundleApplication.h"

#import <RMessageView.h>
#import "SAMKeychain.h"

#import <dlfcn.h>
#include <notify.h>
#import <objc/runtime.h>

@import Firebase;

@interface PSAppDataUsagePolicyCache : NSObject
+ (id)sharedInstance;
- (bool)setUsagePoliciesForBundle:(id)arg1 cellular:(bool)arg2 wifi:(bool)arg3;
@end

@interface AppWirelessDataUsageManager : NSObject
+ (void)setAppCellularDataEnabled:(id)arg1 forBundleIdentifier:(id)arg2 completionHandler:(/*^block*/ id)arg3;
+ (void)setAppWirelessDataOption:(id)arg1 forBundleIdentifier:(id)arg2 completionHandler:(/*^block*/ id)arg3;
@end

@interface NSXPCConnection (Private)
- (id)initWithMachServiceName:(NSString *)arg1;
@end

@interface AppDelegate ()

@property (nonatomic, strong) NSXPCConnection *daemonConnection;
@property (nonatomic, readwrite) BOOL applicationIsActive;
@property (nonatomic, readwrite) BOOL pendingDaemonConnectionAlert;
@property (nonatomic) UIAlertController *loadingAlertVC;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Enable Firebase Analytics if the plist file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[NSBundle mainBundle] pathForResource:@"GoogleService-Info" ofType:@"plist"]]) [FIRApp configure];

    // Override point for customization after application launch.
    [[RPVApplicationSigning sharedInstance] addSigningUpdatesObserver:self];

    // Register to send notifications
    [[RPVNotificationManager sharedInstance] registerToSendNotifications];

    // Register for background signing notifications.
    [self _setupDameonConnection];

    // Ensure Chinese devices have internet access
    [self setupChinaApplicationNetworkAccess];

    // Setup Keychain accessibility for when locked.
    // (prevents not being able to correctly read the passcode when the device is locked)
    [SAMKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];

    // Tint colour
    [self.window setTintColor:[UIColor colorWithRed:147.0 / 255.0 green:99.0 / 255.0 blue:207.0 / 255.0 alpha:1.0]];

    // Stuff for RMessage (iOS 9 only)
    [[RMessageView appearance] setMessageIcon:[UIImage imageNamed:@"notifIcon"]];
    [[RMessageView appearance] setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.9]];

    NSLog(@"*** [ReProvision] :: applicationDidFinishLaunching, options: %@", launchOptions);


    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // nop
    self.applicationIsActive = NO;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Launched in background by daemon, or when exiting the application.
    NSLog(@"*** [ReProvision] :: applicationDidEnterBackground");
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // nop
    NSLog(@"*** [ReProvision] :: applicationWillEnterForeground");
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // nop
    NSLog(@"*** [ReProvision] :: applicationDidBecomeActive");

    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/jp.soh.reprovision.list"]) exit(1);

    self.applicationIsActive = YES;
    if (self.pendingDaemonConnectionAlert) {
        [self _notifyDaemonFailedToConnect];
        self.pendingDaemonConnectionAlert = NO;
    }
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    [self showLoadingAlert];

    // Guard case
    if (![[[url pathExtension] lowercaseString] isEqualToString:@"ipa"] && ![[url scheme] isEqualToString:@"reprovision"]) {
        [self changeLoadingAlertText:@"Error - Invalid URL" dismissAfterDelay:2];
        return NO;
    }

    // Handle opening from URL scheme
    if ([[url scheme] isEqualToString:@"reprovision"] && [[url host] containsString:@"share"]) {
        // For share extension
        NSString *path = [url path];
        path = [path substringFromIndex:1];  // strip preceeding /

        url = [NSURL fileURLWithPath:path];

        NSLog(@"ReProvision :: trying to load from %@", path);

        // Incoming URL is a fileURL!
        [self _showApplicationDetailControllerFromFileURL:url];

    } else if ([[url scheme] isEqualToString:@"file"]) {
        [self _showApplicationDetailControllerFromFileURL:url];
    } else if ([[url scheme] isEqualToString:@"reprovision"] && [[url host] containsString:@"install"] && [url query]) {
        // For other applications

        // First, check params
        // Ref: https://ez-net.jp/article/7C/tje7tU1I/ip9n8f88grK2/
        NSMutableDictionary *queries = [[NSMutableDictionary alloc] init];
        NSArray *parameters = [[url query] componentsSeparatedByString:@"&"];

        for (NSString *parameter in parameters) {
            if (parameter.length > 0) {
                NSArray *elements = [parameter componentsSeparatedByString:@"="];
                id key = [elements[0] stringByRemovingPercentEncoding];
                id value = (elements.count == 1 ? @YES : [elements[1] stringByRemovingPercentEncoding]);
                [queries setObject:value forKey:key];
            }
        }

        // Next, check whether the same file exist on tmp folder.
        // If exist, delete it.
        if (!queries[@"url"]) {
            [self changeLoadingAlertText:@"Invalid URL" dismissAfterDelay:2];
            return NO;
        }

        NSURL *tmpFolderPath = [NSURL fileURLWithPath:NSTemporaryDirectory()];
        NSString *originalFileName = [queries[@"url"] lastPathComponent];
        NSURL *tmpFilePath = [tmpFolderPath URLByAppendingPathComponent:originalFileName];
        if ([tmpFilePath checkResourceIsReachableAndReturnError:nil]) [[NSFileManager defaultManager] removeItemAtPath:[tmpFilePath path] error:nil];

        NSString *identifier = @"BackgroundSessionConfiguration";
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration
                                                              delegate:self
                                                         delegateQueue:nil];

        NSURL *ipaUrl = [NSURL URLWithString:queries[@"url"]];
        NSURLSessionDownloadTask *task = [session downloadTaskWithURL:ipaUrl];

        [task resume];
    }

    [self dismissLoadingAlert];

    return YES;
}

- (void)_showApplicationDetailControllerFromFileURL:(NSURL *)url {
    dispatch_async(dispatch_get_main_queue(), ^{
        // Create an RPVApplication for this incoming .ipa, and display the installation popup.

        RPVIpaBundleApplication *ipaApplication = [[RPVIpaBundleApplication alloc] initWithIpaURL:url];

        RPVApplicationDetailController *detailController = [[RPVApplicationDetailController alloc] initWithApplication:ipaApplication];

        // Update with current states.
        [detailController setButtonTitle:@"INSTALL"];
        detailController.lockWhenInstalling = YES;

        // Add to the rootViewController of the application, as an effective overlay.
        detailController.view.alpha = 0.0;

        UIViewController *rootController = [UIApplication sharedApplication].keyWindow.rootViewController;
        [rootController addChildViewController:detailController];
        [rootController.view addSubview:detailController.view];

        detailController.view.frame = rootController.view.bounds;

        // Animate in!
        [detailController animateForPresentation];
    });
}

- (void)showLoadingAlert {
    self.loadingAlertVC = [UIAlertController alertControllerWithTitle:nil
                                                              message:@"Loading..."
                                                       preferredStyle:UIAlertControllerStyleAlert];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:self.loadingAlertVC animated:YES completion:nil];
}

- (void)dismissLoadingAlert {
    if (self.loadingAlertVC) {
        [self.loadingAlertVC dismissViewControllerAnimated:YES completion:nil];
        self.loadingAlertVC = nil;
    }
}

- (void)updateLoadingAlertWithProgress:(int)progress {
    if (self.loadingAlertVC) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.loadingAlertVC.message = [NSString stringWithFormat:@"Loading...\n%d%%", progress];
        });
    }
}

- (void)changeLoadingAlertText:(NSString *)text dismissAfterDelay:(int)delay {
    if (self.loadingAlertVC) {
        self.loadingAlertVC.message = text;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self dismissLoadingAlert];
        });
    }
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL succeeded))completionHandler {
    // Start background signing from shortcut menu
    if ([shortcutItem.type isEqualToString:@"resignExpiringNow"]) {
        [self daemonDidRequestNewBackgroundSigning];

        completionHandler(YES);
    }
}

- (void)setupChinaApplicationNetworkAccess {
    // See: https://github.com/pwn20wndstuff/Undecimus/issues/136

    NSOperatingSystemVersion version;
    version.majorVersion = 12;
    version.minorVersion = 0;
    version.patchVersion = 0;

    // it is unable to load SettingsCellular.framework weakly as bitcode is enabled on this project
    // so we have to load it manually if the device is on iOS13+
    void *settingsCellular = dlopen("/System/Library/PrivateFrameworks/SettingsCellular.framework/SettingsCellular", RTLD_LAZY);

    if (objc_getClass("PSAppDataUsagePolicyCache")) {
        // iOS 12+
        PSAppDataUsagePolicyCache *cache = [objc_getClass("PSAppDataUsagePolicyCache") sharedInstance];
        [cache setUsagePoliciesForBundle:[NSBundle mainBundle].bundleIdentifier cellular:YES wifi:YES];
    } else if (objc_getClass("AppWirelessDataUsageManager")) {
        // iOS 10 - 11
        [objc_getClass("AppWirelessDataUsageManager") setAppWirelessDataOption:[NSNumber numberWithInt:3]
                                                           forBundleIdentifier:[NSBundle mainBundle].bundleIdentifier
                                                             completionHandler:nil];
        [objc_getClass("AppWirelessDataUsageManager") setAppCellularDataEnabled:[NSNumber numberWithInt:1]
                                                            forBundleIdentifier:[NSBundle mainBundle].bundleIdentifier
                                                              completionHandler:nil];
    }

    // close SettingsCellular as it is not needed anymore.
    if (settingsCellular) dlclose(settingsCellular);

    // Not required for iOS 9
}

//////////////////////////////////////////////////////////////////////////////////
// Application Signing delegate methods.
//////////////////////////////////////////////////////////////////////////////////

- (void)applicationSigningDidStart {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jp.soh.reprovision/signingInProgress" object:nil];
    NSLog(@"Started signing...");
}

- (void)applicationSigningUpdateProgress:(int)percent forBundleIdentifier:(NSString *)bundleIdentifier {
    NSLog(@"'%@' at %d%%", bundleIdentifier, percent);

    if (!bundleIdentifier) bundleIdentifier = @"";

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:bundleIdentifier forKey:@"bundleIdentifier"];
    [userInfo setObject:[NSNumber numberWithInt:percent] ?: @0 forKey:@"percent"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"jp.soh.reprovision/signingUpdate" object:nil userInfo:userInfo];

    NSString *applicationName = [[[RPVApplicationDatabase sharedInstance] getApplicationContainsBundleIdentifier:bundleIdentifier] applicationName];

    switch (percent) {
        case 100:
            [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"Success" body:[NSString stringWithFormat:@"Signed '%@'", applicationName] isDebugMessage:NO isUrgentMessage:YES andNotificationID:nil];
            break;
        case 10:
            [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"DEBUG" body:[NSString stringWithFormat:@"Started signing routine for '%@'", applicationName] isDebugMessage:YES andNotificationID:nil];
            break;
        case 50:
            [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"DEBUG" body:[NSString stringWithFormat:@"Wrote signatures for bundle '%@'", applicationName] isDebugMessage:YES andNotificationID:nil];
            break;
        case 60:
            [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"DEBUG" body:[NSString stringWithFormat:@"Rebuilt IPA for bundle '%@'", applicationName] isDebugMessage:YES andNotificationID:nil];
            break;
        case 90:
            [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"DEBUG" body:[NSString stringWithFormat:@"Installing IPA for bundle '%@'", applicationName] isDebugMessage:YES andNotificationID:nil];
            break;

        default:
            break;
    }
}

- (void)applicationSigningDidEncounterError:(NSError *)error forBundleIdentifier:(NSString *)bundleIdentifier {
    NSLog(@"'%@' had error: %@", bundleIdentifier, error);

    NSString *applicationName = [[[RPVApplicationDatabase sharedInstance] getApplicationContainsBundleIdentifier:bundleIdentifier] applicationName];
    [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"Error" body:[NSString stringWithFormat:@"For '%@':\n%@", applicationName, error.localizedDescription] isDebugMessage:NO isUrgentMessage:YES andNotificationID:nil];

    // Ensure the UI goes back to when signing was not occuring
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:bundleIdentifier forKey:@"bundleIdentifier"];
    [userInfo setObject:[NSNumber numberWithInt:100] forKey:@"percent"];

    [[NSNotificationCenter defaultCenter] postNotificationName:@"jp.soh.reprovision/signingUpdate" object:nil userInfo:userInfo];
}

- (void)applicationSigningCompleteWithError:(NSError *)error {
    NSLog(@"Completed signing, with error: %@", error);
    [[NSNotificationCenter defaultCenter] postNotificationName:@"jp.soh.reprovision/signingComplete" object:nil];

    // Display any errors if needed.
    if (error) {
        switch (error.code) {
            case RPVErrorNoSigningRequired:
                [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"Success" body:@"No applications require signing at this time" isDebugMessage:NO isUrgentMessage:NO andNotificationID:nil];
                break;
            default:
                [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"Error" body:error.localizedDescription isDebugMessage:NO isUrgentMessage:YES andNotificationID:nil];
                break;
        }
    }
}

//////////////////////////////////////////////////////////////////////////////////
// NSURLSession delegate methods.
//////////////////////////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    // Check file size
    NSNumber *fileSizeValue = nil;
    NSError *fileSizeError = nil;
    [location getResourceValue:&fileSizeValue forKey:NSURLFileSizeKey error:&fileSizeError];

    if (fileSizeError || !fileSizeValue) {
        [self changeLoadingAlertText:@"Error - The file does not exist." dismissAfterDelay:2];
        [session finishTasksAndInvalidate];
        return;
    }

    // Successfully downloaded the file

    // Move ipa file to /tmp directory
    NSURL *tmpFolderPath = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    NSString *originalFileName = downloadTask.originalRequest.URL.lastPathComponent;
    NSURL *tmpFilePath = [tmpFolderPath URLByAppendingPathComponent:originalFileName];
    NSError *error;
    [[NSFileManager defaultManager] copyItemAtURL:location toURL:tmpFilePath error:&error];

    if (error) {
        NSString *errorMessage = [NSString stringWithFormat:@"Error - %@", error.localizedDescription];
        [self changeLoadingAlertText:errorMessage dismissAfterDelay:2];
    } else {
        // And show application detail view
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dismissLoadingAlert];
        });
        [self _showApplicationDetailControllerFromFileURL:tmpFilePath];
    }

    [session finishTasksAndInvalidate];
}


- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        // Could not download the ipa file
        NSString *errorMessage = [NSString stringWithFormat:@"Error - %@", error.localizedDescription];
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];

        if ([[error.userInfo objectForKey:NSURLErrorBackgroundTaskCancelledReasonKey] integerValue] == NSURLErrorCancelledReasonUserForceQuitApplication && resumeData) {
            errorMessage = [errorMessage stringByAppendingString:@"\nThe app seems to have quit while downloading. Would you like to resume?"];

            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:errorMessage
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction *resumeButton = [UIAlertAction actionWithTitle:@"Resume"
                                                                   style:UIAlertActionStyleDefault
                                                                 handler:^(UIAlertAction *action) {
                                                                     NSURLSessionDownloadTask *task = [session downloadTaskWithResumeData:resumeData];
                                                                     [task resume];
                                                                 }];

            UIAlertAction *cancelButton = [UIAlertAction actionWithTitle:@"Cancel"
                                                                   style:UIAlertActionStyleCancel
                                                                 handler:^(UIAlertAction *action) {
                                                                     [task cancel];
                                                                     [session finishTasksAndInvalidate];
                                                                 }];
            [alertController addAction:resumeButton];
            [alertController addAction:cancelButton];
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alertController animated:YES completion:nil];
        } else {
            [self changeLoadingAlertText:errorMessage
                       dismissAfterDelay:2];
            [session finishTasksAndInvalidate];
        }
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    CGFloat progress = (int)round((float)totalBytesWritten / totalBytesExpectedToWrite * 100);
    [self updateLoadingAlertWithProgress:progress];
}

//////////////////////////////////////////////////////////////////////////////
// Automatic application signing
//////////////////////////////////////////////////////////////////////////////

- (void)_setupDameonConnection {
    /*#if TARGET_OS_SIMULATOR
    return;
#endif*/

    if (self.daemonConnection) {
        [self.daemonConnection invalidate];
        self.daemonConnection = nil;
    }

    self.daemonConnection = [[NSXPCConnection alloc] initWithMachServiceName:@"jp.soh.reprovisiond"];
    self.daemonConnection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(RPVDaemonProtocol)];

    self.daemonConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(RPVApplicationProtocol)];
    self.daemonConnection.exportedObject = self;

    [self.daemonConnection resume];

    // Handle connection errors
    __weak AppDelegate *weakSelf = self;
    self.daemonConnection.interruptionHandler = ^{
        NSLog(@"interruption handler called");

        [weakSelf.daemonConnection invalidate];
        weakSelf.daemonConnection = nil;

        // Re-create connection
        [weakSelf _setupDameonConnection];
    };

    self.daemonConnection.invalidationHandler = ^{
        NSLog(@"invalidation handler called");

        [weakSelf.daemonConnection invalidate];
        weakSelf.daemonConnection = nil;

        // Notify of failed connection
        [weakSelf _notifyDaemonFailedToConnect];
    };

    // Notify daemon that we've now launched
    @try {
        [[self.daemonConnection remoteObjectProxyWithErrorHandler:^(NSError *_Nonnull error) {
            NSLog(@"%@", error);

            if (error.code == NSXPCConnectionInvalid) {
                [weakSelf _notifyDaemonFailedToConnect];
            }
        }] applicationDidLaunch];

    } @catch (NSException *e) {
        [self _notifyDaemonFailedToConnect];
        return;
    }

    NSLog(@"*** [ReProvision] :: Setup daemon connection: %@", self.daemonConnection);
}

- (void)_notifyDaemonFailedToConnect {
    if (!self.applicationIsActive) {
        self.pendingDaemonConnectionAlert = YES;
        return;
    }

    // That's not good...
    UIAlertController *av = [UIAlertController alertControllerWithTitle:@"Error" message:@"Could not connect to daemon; automatic background signing is disabled.\n\nPlease reinstall ReProvision, or reboot your device." preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action){
    }];
    [av addAction:action];

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.window.rootViewController presentViewController:av animated:YES completion:nil];
    });

    NSLog(@"*** [ReProvision] :: ERROR :: Failed to setup daemon connection: %@", self.daemonConnection);
}

- (void)_notifyDaemonOfMessageHandled {
    // Let the daemon know to release the background assertion.
    @try {
        [[self.daemonConnection remoteObjectProxy] applicationDidFinishTask];
    } @catch (NSException *e) {
        // Error previous shown
    }
}

- (void)daemonDidRequestNewBackgroundSigning {
    NSLog(@"*** [ReProvision] :: daemonDidRequestNewBackgroundSigning");

    // Start a background sign
    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier __block bgTask = [application beginBackgroundTaskWithName:@"ReProvision Background Signing" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;

        [self performSelector:@selector(_notifyDaemonOfMessageHandled) withObject:nil afterDelay:5];
    }];

    [[RPVBackgroundSigningManager sharedInstance] attemptBackgroundSigningIfNecessary:^{
        // Ask to remove our process assertion 5 seconds later, so that we can assume any notifications
        // have been scheduled.

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self _notifyDaemonOfMessageHandled];

            // Done, so stop this background task.
            [application endBackgroundTask:bgTask];
            bgTask = UIBackgroundTaskInvalid;
        });
    }];
}

- (void)daemonDidRequestCredentialsCheck {
    NSLog(@"*** [ReProvision] :: daemonDidRequestCredentialsCheck");

    // Check that user credentials exist, notify if not
    if (![RPVResources getUsername] ||
        [[RPVResources getUsername] isEqualToString:@""] ||
        ![RPVResources getPassword] ||
        [[RPVResources getPassword] isEqualToString:@""] ||
        ![[RPVResources getCredentialsVersion] isEqualToString:CURRENT_CREDENTIALS_VERSION]) {
        [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:@"Login Required" body:@"Tap to login to ReProvision. This is needed to re-sign applications." isDebugMessage:NO isUrgentMessage:YES andNotificationID:@"login"];

        // Ask to remove our process assertion 5 seconds later, so that we can assume any notifications
        // have been scheduled.
        [self performSelector:@selector(_notifyDaemonOfMessageHandled) withObject:nil afterDelay:5];
    } else {
        // Nothing to do, just notify that we're done.
        [self _notifyDaemonOfMessageHandled];
    }
}

- (void)daemonDidRequestQueuedNotification {
    NSLog(@"*** [ReProvision] :: daemonDidRequestQueuedNotification");

    // Check if any applications need resigning. If they do, show notifications as appropriate.

    if ([[RPVBackgroundSigningManager sharedInstance] anyApplicationsNeedingResigning]) {
        [self _sendBackgroundedNotificationWithTitle:@"Re-signing Queued" body:@"Unlock your device to resign applications." isDebug:NO isUrgent:YES withNotificationID:@"resignQueued"];
    } else {
        [self _sendBackgroundedNotificationWithTitle:@"DEBUG" body:@"Background check has been queued for next unlock." isDebug:YES isUrgent:NO withNotificationID:nil];
    }

    [self _notifyDaemonOfMessageHandled];
}

- (void)requestDebuggingBackgroundSigning {
    @try {
        [[self.daemonConnection remoteObjectProxy] applicationRequestsDebuggingBackgroundSigning];
    } @catch (NSException *e) {
        // Error previous shown
    }
}

- (void)requestPreferencesUpdate {
    @try {
        [[self.daemonConnection remoteObjectProxy] applicationRequestsPreferencesUpdate];
    } @catch (NSException *e) {
        // Error previous shown
    }
}

- (void)_sendBackgroundedNotificationWithTitle:(NSString *)title body:(NSString *)body isDebug:(BOOL)isDebug isUrgent:(BOOL)isUrgent withNotificationID:(NSString *)notifID {
    // We start a background task to ensure the notification is posted when expected.
    UIApplication *application = [UIApplication sharedApplication];
    UIBackgroundTaskIdentifier __block bgTask = [application beginBackgroundTaskWithName:@"ReProvision Background Notification" expirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;

        [self performSelector:@selector(_notifyDaemonOfMessageHandled) withObject:nil afterDelay:5];
    }];

    // Post the notification.
    [[RPVNotificationManager sharedInstance] sendNotificationWithTitle:title body:body isDebugMessage:isDebug isUrgentMessage:isUrgent andNotificationID:notifID];

    // Done, so stop this background task.
    [application endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;

    // Ask to remove our process assertion 5 seconds later, so that we can assume any notifications
    // have been scheduled.
    [self performSelector:@selector(_notifyDaemonOfMessageHandled) withObject:nil afterDelay:5];
}

@end
