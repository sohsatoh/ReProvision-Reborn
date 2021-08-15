//
//  RPVAppIDViewController.h
//  iOS
//
//  Created by soh on 2021/08/16.
//  Copyright © 2021 Matt Clarke. All rights reserved.
//

#import "RPVFullscreenAlertController.h"

@interface RPVAppIDViewController : RPVFullscreenAlertController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) UITableView *appIdsTableView;
@property (nonatomic, strong) NSMutableArray *appIdsDataSource;
@end
