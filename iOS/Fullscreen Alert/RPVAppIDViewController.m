//
//  RPVAppIDViewController.m
//  iOS
//
//  Created by soh on 2021/08/16.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVAppIDViewController.h"
#import "RPVAccountChecker.h"
#import "RPVAppIdsTableViewCell.h"
#import "RPVResources.h"

#define TABLE_VIEWS_INSET 20

@interface RPVAppIDViewController ()
@property (nonatomic, strong) UILabel *bodyLabel;
@end

@implementation RPVAppIDViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.appIdsTableView registerClass:[RPVAppIdsTableViewCell class] forCellReuseIdentifier:@"appIds.cell"];
}

- (void)loadView {
    [super loadView];

    self.titleLabel.text = @"What's App ID?";

    self.bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bodyLabel.text = @"App ID is the ID for each sideloaded application, issued by Apple's servers.\nWith a free account, you can only register up to 10 per 7 days.\nThis limit is on a per-account basis.\nAfter a week, it will automatically expire and you can install a new app.";
    self.bodyLabel.textAlignment = NSTextAlignmentCenter;
    self.bodyLabel.numberOfLines = 0;
    self.bodyLabel.textColor = [UIColor blackColor];
    [self.bodyContainerView addSubview:self.bodyLabel];

    self.appIdsTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.appIdsTableView.delegate = self;
    self.appIdsTableView.dataSource = self;
    self.appIdsTableView.scrollEnabled = YES;
    self.appIdsTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.appIdsTableView.backgroundColor = [UIColor clearColor];
    self.appIdsTableView.allowsSelection = NO;
    [self.bodyContainerView addSubview:self.appIdsTableView];

    [self layoutWithSize:[UIScreen mainScreen].bounds.size];
}

- (void)layoutWithSize:(CGSize)size {
    [super layoutWithSize:size];

    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];

    CGRect rect = [RPVResources boundedRectForFont:self.bodyLabel.font andText:self.bodyLabel.text width:self.bodyContainerView.frame.size.width];

    self.bodyLabel.frame = CGRectMake(0, 0, self.bodyContainerView.frame.size.width, rect.size.height);

    CGFloat scale = (size.width * 0.8) / 950;

    CGFloat tableViewHeight = 610 * scale * 2;
    CGFloat cellHeight = [self _tableViewCellHeight];
    tableViewHeight = cellHeight * floor((tableViewHeight / cellHeight));

    self.appIdsTableView.frame = CGRectMake(0, self.bodyLabel.frame.size.height + (statusBarFrame.size.height / 2), self.bodyContainerView.frame.size.width, tableViewHeight);
    CGFloat appIdsHeight = [self tableView:self.appIdsTableView numberOfRowsInSection:0] * cellHeight;
    self.appIdsTableView.contentSize = CGSizeMake(self.appIdsTableView.frame.size.width, appIdsHeight);
}


//////////////////////////////////////////////////////////////////////////////////
// Table View delegate methods.
//////////////////////////////////////////////////////////////////////////////////

- (CGFloat)_tableViewCellHeight {
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 95 : 75;
}


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
        fallbackString = @"No App ID found";
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
