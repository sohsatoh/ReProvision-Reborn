//
//  RPVFullscreenAlertController.m
//  iOS
//
//  Created by Matt Clarke on 16/01/2020.
//  Copyright © 2020 Matt Clarke. All rights reserved.
//

#import "RPVFullscreenAlertController.h"
#import "RPVResources.h"
#import "RPVAppIdsTableViewCell.h"
#import "RPVAccountChecker.h"

#define TABLE_VIEWS_INSET 20

@interface RPVFullscreenAlertController ()
@property (nonatomic, strong) UIView *topBackgroundView;
@property (nonatomic, strong) CAGradientLayer *topBackgroundGradientLayer;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyLabel;
@property (nonatomic, strong) UITableView *appIdsTableView;
@property (nonatomic, strong) UIButton *dismissButton;

@property (nonatomic, strong) NSMutableArray *appIdsDataSource;

@property (nonatomic, assign) BOOL loaded;
@end

@implementation RPVFullscreenAlertController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self.appIdsTableView registerClass:[RPVAppIdsTableViewCell class] forCellReuseIdentifier:@"appIds.cell"];

    [self _reloadDataSources];
}

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];

    self.topBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.topBackgroundView];

    self.topBackgroundGradientLayer = [CAGradientLayer layer];
    self.topBackgroundGradientLayer.frame = CGRectZero;

    UIColor *startColor = [UIColor colorWithRed:147.0/255.0 green:99.0/255.0 blue:207.0/255.0 alpha:1.0];
    UIColor *endColor = [UIColor colorWithRed:116.0/255.0 green:158.0/255.0 blue:201.0/255.0 alpha:1.0];
    self.topBackgroundGradientLayer.colors = @[(id)startColor.CGColor, (id)endColor.CGColor];
    self.topBackgroundGradientLayer.startPoint = CGPointMake(0.75, 0.75);
    self.topBackgroundGradientLayer.endPoint = CGPointMake(0.25, 0.25);

    [self.topBackgroundView.layer insertSublayer:self.topBackgroundGradientLayer atIndex:0];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.text = @"What's App ID?";
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont systemFontOfSize:34];

    [self.topBackgroundView addSubview:self.titleLabel];

    self.bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bodyLabel.text = @"App ID is the ID for each sideloaded application, issued by Apple's servers.\nWith a free account, you can only register up to 10 per week.\nThis limit is on a per-account basis.\nAfter a week, it will automatically expire and you can install a new app.";
    self.bodyLabel.textAlignment = NSTextAlignmentCenter;
    self.bodyLabel.numberOfLines = 0;

    [self.view addSubview:self.bodyLabel];

    self.appIdsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.appIdsTableView.delegate = self;
    self.appIdsTableView.dataSource = self;
    self.appIdsTableView.scrollEnabled = YES;
    self.appIdsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.appIdsTableView.backgroundColor = [UIColor clearColor];
    self.appIdsTableView.allowsSelection = NO;
    [self.view addSubview:self.appIdsTableView];

    self.dismissButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
    [self.dismissButton addTarget:self action:@selector(onDismiss:) forControlEvents:UIControlEventTouchUpInside];
    [self.dismissButton sizeToFit];

    [self.view addSubview:self.dismissButton];

    self.view.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.titleLabel.textColor = [UIColor whiteColor];
    self.bodyLabel.textColor = [UIColor blackColor];

    [self _layoutWithSize:[UIScreen mainScreen].bounds.size];
}

- (void)_layoutWithSize:(CGSize)size {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];

    self.topBackgroundView.frame = CGRectMake(0, 0, self.view.bounds.size.width, (statusBarFrame.size.height + 30) * 2);
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.topBackgroundGradientLayer.frame = self.topBackgroundView.bounds;
    [CATransaction commit];

    self.titleLabel.frame = CGRectMake(size.width * 0.1, statusBarFrame.size.height + 30, size.width * 0.8, 60);

    CGRect rect = [RPVResources boundedRectForFont:self.bodyLabel.font andText:self.bodyLabel.text width:size.width * 0.8];

    self.bodyLabel.frame = CGRectMake(size.width * 0.1, statusBarFrame.size.height + 120, size.width * 0.8, rect.size.height);

    CGFloat scale = (size.width * 0.8) / 950;

    self.appIdsTableView.frame = CGRectMake(size.width * 0.1, statusBarFrame.size.height + 120 + rect.size.height + 30, size.width * 0.8, (535 * scale) * 2);
    CGFloat appIdsHeight = [self tableView:self.appIdsTableView numberOfRowsInSection:0] * [self _tableViewCellHeight];
    self.appIdsTableView.contentSize = CGSizeMake(self.appIdsTableView.frame.size.width, appIdsHeight);

    CGFloat safeAreaBottomInset = 34;

    self.dismissButton.frame = CGRectMake(size.width * 0.1, self.view.frame.size.height - self.dismissButton.frame.size.height - safeAreaBottomInset, size.width * 0.8, self.dismissButton.frame.size.height);
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self _layoutWithSize:size];
}

- (void)onDismiss:(id)sender {
    self.onDismiss();
}

- (CGFloat)_tableViewCellHeight {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 95 : 75;
}

//////////////////////////////////////////////////////////////////////////////////
// Data sources.
//////////////////////////////////////////////////////////////////////////////////

- (void)_reloadDataSources {
    [[RPVAccountChecker sharedInstance] listAllApplicationsWithCompletionHandler:^(NSError *error, NSArray *appIds) {
         if([appIds count] != 0) {
             self.appIdsDataSource = [appIds mutableCopy];
             NSSortDescriptor* sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"applicationExpiryDate" ascending:YES];
             [self.appIdsDataSource sortUsingDescriptors:@[sortByDate]];

             dispatch_async(dispatch_get_main_queue(), ^{
                                [self.appIdsTableView reloadData];
                                [self.view setNeedsLayout];
                            });

         }
     }];
}
//////////////////////////////////////////////////////////////////////////////////
// Table View delegate methods.
//////////////////////////////////////////////////////////////////////////////////

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.appIdsDataSource.count > 0 ? self.appIdsDataSource.count : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RPVAppIdsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"appIds.cell"];

    if (!cell) {
        cell = [[RPVAppIdsTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"appIds.cell"];
    }

    RPVAppID *appID;
    NSString *fallbackString = @"";

    if (self.appIdsDataSource.count > 0) {
        appID = [self.appIdsDataSource objectAtIndex:indexPath.row];
    } else {
        if(!self.loaded) {
            fallbackString = @"Loading...";
            self.loaded = YES;
        }
        else {
            fallbackString = @"No App ID found";
        }
    }

    [cell configureWithAppID:appID fallbackDisplayName:fallbackString andExpiryDate:[appID applicationExpiryDate]];

    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self _tableViewCellHeight];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)arg2 {
    return NO;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

@end
