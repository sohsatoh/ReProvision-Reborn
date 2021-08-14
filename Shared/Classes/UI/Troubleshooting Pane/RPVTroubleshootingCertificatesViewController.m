
//
//  RPVTroubleshootingCertificatesViewController.m
//  iOS
//
//  Created by Matt Clarke on 04/07/2018.
//  Copyright © 2018 Matt Clarke. All rights reserved.
//

#import "RPVTroubleshootingCertificatesViewController.h"
#import "EEAppleServices.h"
#import "RPVResources.h"

#if !TARGET_OS_TV
#import <TORoundedTableView/TORoundedTableView.h>
#import <TORoundedTableView/TORoundedTableViewCapCell.h>
#import <TORoundedTableView/TORoundedTableViewCell.h>
#endif

@interface RPVTroubleshootingCertificatesViewController ()
@property (nonatomic, strong) NSMutableArray *dataSource;

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UILabel *label;

@property (nonatomic, assign) BOOL showingAllCerts;
@end

@implementation RPVTroubleshootingCertificatesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    ///////////////////////////////////////////////////////////////////////////
    // Setup spinner.
    ///////////////////////////////////////////////////////////////////////////

    self.overlayView = [[UIView alloc] initWithFrame:CGRectZero];
#if TARGET_OS_TV
    self.overlayView.backgroundColor = [UIColor whiteColor];
#else
    self.overlayView.backgroundColor = [UIColor groupTableViewBackgroundColor];
#endif
    self.overlayView.hidden = YES;
    [self.view addSubview:self.overlayView];

    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];

    if (@available(iOS 13.0, *)) {
        self.spinner.color = [UIColor labelColor];
    } else {
        self.spinner.tintColor = [UIColor darkTextColor];
    }

    [self.overlayView addSubview:self.spinner];

    self.label = [[UILabel alloc] initWithFrame:CGRectZero];
    self.label.text = @"Loading";
    self.label.textAlignment = NSTextAlignmentCenter;

    if (@available(iOS 13.0, *)) {
        self.label.textColor = [UIColor labelColor];
    } else {
        self.label.textColor = [UIColor darkTextColor];
    }

#if TARGET_OS_TV
    self.label.font = [UIFont systemFontOfSize:28 weight:UIFontWeightRegular];
#else
    self.label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
#endif
    [self.overlayView addSubview:self.label];

    ///////////////////////////////////////////////////////////////////////////

    [[self navigationItem] setTitle:@"Certificates"];

    // Pull down registered certs from Apple's servers.
    [self _requestAllDevelopmentCodesigningCertificates];

    [self.tableView setEditing:YES animated:NO];

#if !TARGET_OS_TV
    if (@available(iOS 11.0, *)) {
        self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;
    }
#endif
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    self.tableView.frame = self.view.bounds;
    self.overlayView.frame = self.view.bounds;
    self.spinner.frame = CGRectMake(self.overlayView.frame.size.width / 2 - 25, self.overlayView.frame.size.height / 2 - 50, 50, 50);

#if TARGET_OS_TV
    self.label.frame = CGRectMake(10, self.overlayView.frame.size.height / 2 + 30, self.overlayView.frame.size.width - 20, 30);
#else
    self.label.frame = CGRectMake(10, self.overlayView.frame.size.height / 2 + 10, self.overlayView.frame.size.width - 20, 20);
#endif
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:CGRectZero];

#if TARGET_OS_TV
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
#else
    // Styling on iPad.
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.tableView = [[TORoundedTableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        self.tableView.separatorColor = self.tableView.backgroundColor;
    } else {
        self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    }
#endif

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsSelectionDuringEditing = YES;

    [self.view addSubview:self.tableView];
}

- (void)_requestAllDevelopmentCodesigningCertificates {
    // Hide the tableView, show a spinner.
    [self.spinner startAnimating];
    self.overlayView.hidden = NO;

    [[EEAppleServices sharedInstance] ensureSessionWithIdentity:[RPVResources getUsername] gsToken:[RPVResources getPassword] andCompletionHandler:^(NSError *error, NSDictionary *plist) {
        if (!error) {
            [[EEAppleServices sharedInstance] listAllDevelopmentCertificatesWithFiltering:!self.showingAllCerts teamID:[RPVResources getTeamID] systemType:EESystemTypeiOS withCompletionHandler:^(NSError *error, NSDictionary *dict) {
                self.dataSource = [[dict objectForKey:@"data"] mutableCopy];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.tableView setEditing:self.dataSource.count > 0 animated:NO];

                    // Show table, stop spinner.
                    [UIView animateWithDuration:0.3 animations:^{
                        self.overlayView.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        self.overlayView.hidden = YES;
                        [self.spinner stopAnimating];
                    }];
                });
            }];
        }
    }];
}

- (void)_revokeCertificate:(NSDictionary *)certificate withCompletion:(void (^)(NSError *error))completionHandler {
    [[EEAppleServices sharedInstance] ensureSessionWithIdentity:[RPVResources getUsername] gsToken:[RPVResources getPassword] andCompletionHandler:^(NSError *error, NSDictionary *plist) {
        if (!error) {
            [[EEAppleServices sharedInstance] revokeCertificateForIdentifier:[certificate objectForKey:@"id"] andTeamID:[RPVResources getTeamID] systemType:EESystemTypeiOS withCompletionHandler:^(NSError *error, NSDictionary *dictionary) {
                completionHandler(error);
            }];
        }
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.dataSource.count > 0 ? self.dataSource.count : 1;
    } else {
        return 2;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;

    static NSString *cellIdentifier = @"certificate.cell";

#if TARGET_OS_TV
    cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
#else
    // Fancy cell styling on iPad
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        cell = [self tableView:(TORoundedTableView *)tableView _ipadCellForIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }
    }
#endif

    if (indexPath.section == 0) {
        if (self.dataSource.count == 0) {
            cell.textLabel.text = @"No certificates";

            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor secondaryLabelColor];
            } else {
                cell.textLabel.textColor = [UIColor grayColor];
            }

            cell.textLabel.textAlignment = NSTextAlignmentNatural;

            cell.detailTextLabel.text = @"";
        } else {
            // Fill from data source
            NSDictionary *dictionary = [self.dataSource objectAtIndex:indexPath.row][@"attributes"];

            NSString *machineName = [dictionary objectForKey:@"machineName"] ? [dictionary objectForKey:@"machineName"] : @"Unknown";
            NSString *applicationName = @"Unknown";

            machineName = [machineName stringByReplacingOccurrencesOfString:@"RPV- " withString:@""];

            if ([(NSString *)[dictionary objectForKey:@"machineName"] containsString:@"RPV"])
                applicationName = @"ReProvision";
            else if ([(NSString *)[dictionary objectForKey:@"machineName"] isEqualToString:@"AltStore"])
                applicationName = @"AltStore";
            else if ([(NSString *)[dictionary objectForKey:@"machineName"] containsString:@"Cydia"])
                applicationName = @"Cydia Impactor or Extender";
            else
                applicationName = @"Xcode";

            cell.textLabel.text = [NSString stringWithFormat:@"Device: %@", machineName];

            if (@available(iOS 13.0, *)) {
                cell.textLabel.textColor = [UIColor labelColor];
            } else {
                cell.textLabel.textColor = [UIColor darkTextColor];
            }

            cell.textLabel.textAlignment = NSTextAlignmentNatural;

            cell.detailTextLabel.text = [NSString stringWithFormat:@"Application: %@", applicationName];
        }
    } else {
        if (indexPath.row == 0) {
            cell.textLabel.text = self.showingAllCerts ? @"Hide Unrelated Certificates" : @"Show All Certificates";
            cell.textLabel.textColor = [UIApplication sharedApplication].delegate.window.tintColor;
        } else {
            cell.textLabel.text = @"Revoke All Certificates";
            cell.textLabel.textColor = self.dataSource.count > 0 ? [UIColor redColor] : [UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.5];
        }
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.detailTextLabel.text = @"";
    }

    return cell;
}

#if !TARGET_OS_TV
- (UITableViewCell *)tableView:(TORoundedTableView *)tableView _ipadCellForIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    static NSString *capCellIdentifier = @"CapCell";

    // Work out if this cell needs the top or bottom corners rounded (Or if the section only has 1 row, both!)
    BOOL isTop = (indexPath.row == 0);
    BOOL isBottom = indexPath.row == ([tableView numberOfRowsInSection:indexPath.section] - 1);

    // Create a common table cell instance we can configure
    UITableViewCell *cell = nil;

    // If it's a non-cap cell, dequeue one with the regular identifier
    if (!isTop && !isBottom) {
        TORoundedTableViewCell *normalCell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        if (normalCell == nil) {
            normalCell = [[TORoundedTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        }

        cell = normalCell;
    } else {
        // If the cell is indeed one that needs rounded corners, dequeue from the pool of cap cells
        TORoundedTableViewCapCell *capCell = [tableView dequeueReusableCellWithIdentifier:capCellIdentifier];
        if (capCell == nil) {
            capCell = [[TORoundedTableViewCapCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:capCellIdentifier];
        }

        // Configure the cell to set the appropriate corners as rounded
        capCell.topCornersRounded = isTop;
        capCell.bottomCornersRounded = isBottom;
        cell = capCell;
    }

    if (@available(iOS 13.0, *)) {
        cell.textLabel.backgroundColor = [UIColor secondarySystemGroupedBackgroundColor];
    } else {
        cell.textLabel.backgroundColor = [UIColor whiteColor];
    }

    cell.textLabel.opaque = YES;

    return cell;
}
#endif

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? YES : NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.section == 0 ? 55.0 : UITableViewAutomaticDimension;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == 0) {
        return @"By default, only the certificates required to sign the app are shown.\nBy tapping the 'Show All Certificates' button, you can show other certificates such as Xcode.";
    } else {
        return @"Free accounts are limited to two active certificates.";
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 1) {
        if (indexPath.row == 1 && self.dataSource.count > 0) {
            // Hit the revoke all button!

            // First, start the spinner off...
            [self.spinner startAnimating];
            self.overlayView.hidden = NO;
            self.overlayView.alpha = 0.0;

            [UIView animateWithDuration:0.3 animations:^{
                self.overlayView.alpha = 1.0;
            }];

            [self _revokeAllCertificatesWithCallback:^(BOOL success) {
                // Done, restore UI.
                [self.dataSource removeAllObjects];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    [self.tableView setEditing:self.dataSource.count > 0 animated:NO];

                    // Show table, stop spinner.
                    [UIView animateWithDuration:0.3 animations:^{
                        self.overlayView.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        self.overlayView.hidden = YES;
                        [self.spinner stopAnimating];
                    }];
                });
            }];
        } else {
            // Show or hide certificates
            [self.spinner startAnimating];
            self.overlayView.hidden = NO;
            self.overlayView.alpha = 0.0;

            [UIView animateWithDuration:0.3 animations:^{
                self.overlayView.alpha = 1.0;
            }];

            self.showingAllCerts = !self.showingAllCerts;
            [self _requestAllDevelopmentCodesigningCertificates];
        }
    }
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Actually delete this certificate from Apple's servers!

        // First, start the spinner off...
        [self.spinner startAnimating];
        self.overlayView.hidden = NO;
        self.overlayView.alpha = 0.0;

        [UIView animateWithDuration:0.3 animations:^{
            self.overlayView.alpha = 1.0;
        }];

        [self _revokeCertificate:[self.dataSource objectAtIndex:indexPath.row] withCompletion:^(NSError *error) {
            if (!error) {
                // Delete the row from the data source
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (self.dataSource.count == 1) {
                        [self.dataSource removeObjectAtIndex:indexPath.row];
                        [self.tableView reloadData];
                    } else {
                        [self.dataSource removeObjectAtIndex:indexPath.row];
                        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                    }

                    [self.tableView setEditing:self.dataSource.count > 0 animated:NO];

                    // Stop spinner
                    [UIView animateWithDuration:0.3 animations:^{
                        self.overlayView.alpha = 0.0;
                    } completion:^(BOOL finished) {
                        self.overlayView.hidden = YES;
                        [self.spinner stopAnimating];
                    }];
                });
            }
        }];
    }
}

////////////////////////////////////////////////////////////////////////////
// Revoke all certificates
////////////////////////////////////////////////////////////////////////////

- (void)_revokeAllCertificatesWithCallback:(void (^)(BOOL))completionHandler {
    UIAlertController *controller = [UIAlertController alertControllerWithTitle:@"Revoke All Certificates" message:@"Revoking all certificates will require applications to be re-signed.\n\nAre you sure you wish to continue?" preferredStyle:UIAlertControllerStyleAlert];

    UIAlertAction *attempt = [UIAlertAction actionWithTitle:@"Revoke" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // Alright, user is sure...
        [self _actuallyRevokeCertificatesWithCallback:completionHandler];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        [controller dismissViewControllerAnimated:YES completion:nil];
        completionHandler(NO);
    }];

    [controller addAction:cancel];
    [controller addAction:attempt];

    [self presentViewController:controller animated:YES completion:nil];
}

- (void)_actuallyRevokeCertificatesWithCallback:(void (^)(BOOL))completionHandler {
    // To revoke a certificate, we need its identifier.
    NSMutableArray *identifiers = [NSMutableArray array];
    for (NSDictionary *cert in self.dataSource) {
        NSString *identifier = [cert objectForKey:@"id"];
        [identifiers addObject:identifier];
    }

    // Make sure we're signed in.
    [[EEAppleServices sharedInstance] ensureSessionWithIdentity:[RPVResources getUsername] gsToken:[RPVResources getPassword] andCompletionHandler:^(NSError *error, NSDictionary *dict) {
        if (error) {
            completionHandler(NO);
            return;
        }

        [self _revokeIdentifiers:identifiers withTeamID:[RPVResources getTeamID] andCompletionHandler:^(NSError *error) {
            if (error) {
                completionHandler(NO);
                return;
            }

            // Done revoking!
            completionHandler(YES);
        }];
    }];
}

- (void)_revokeIdentifiers:(NSArray *)identifiers withTeamID:(NSString *)teamId andCompletionHandler:(void (^)(NSError *))completionHandler {
    // guard.
    if (identifiers.count == 0) {
        completionHandler(nil);
        return;
    }

    NSString *identifier = [identifiers firstObject];
    [[EEAppleServices sharedInstance] revokeCertificateForIdentifier:identifier andTeamID:teamId systemType:EESystemTypeiOS withCompletionHandler:^(NSError *error, NSDictionary *plist) {
        if (error) {
            completionHandler(error);
            return;
        }

        // Pop current serial off array and recurse.
        NSMutableArray *array = [identifiers mutableCopy];
        [array removeObject:identifier];

        [self _revokeIdentifiers:array withTeamID:teamId andCompletionHandler:completionHandler];
    }];
}


@end
