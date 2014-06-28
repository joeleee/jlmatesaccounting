//
//  MAAccountDetailViewController.m
//  MatesAccounting
//
//  Created by Lee on 13-12-1.
//  Copyright (c) 2013年 Lee. All rights reserved.
//

#import "MAAccountDetailViewController.h"

#import "MAAccountDetailFeeCell.h"
#import "MAAccountDetailDateCell.h"
#import "MAAccountDetailPayersCell.h"
#import "MAAccountDetailConsumersCell.h"
#import "MAAccountDetailLocationCell.h"
#import "MAAccountDetailConsumerDetailCell.h"
#import "MAAccountDetailDescriptionCell.h"
#import "MAAccountDetailSectionHeader.h"
#import "MAccount+expand.h"
#import "UIViewController+MAAddition.h"
#import "MPlace.h"
#import "MAAccountManager.h"

typedef enum {
    FeeSectionType = 0,
    AccountDetailSectionType = 1,
    MembersSectionType = 2,
    AccountDescriptionSectionType = 3
} AccountDetailTableViewSectionType;

typedef enum {
    DetailDateType = 0,
    DetailPayerType = 1,
    DetailConsumerType = 2,
    DetailLocationType = 3
} AccountDetailTableViewRowType;

NSString *const kSegueAccountDetailToMemberList = @"kSegueAccountDetailToMemberList";

NSUInteger const kAccountDetailNumberOfSections = 4;
NSString *const  kAccountDetailRowCount = @"kAccountDetailRowCount";
NSString *const  kAccountDetailCellIdentifier = @"kAccountDetailCellIdentifier";
NSString *const  kAccountDetailCellHeight = @"kAccountDetailCellHeight";
NSString *const  kAccountDetailHeaderTitle = @"kAccountDetailHeaderTitle";

@interface MAAccountDetailViewController () <UITableViewDataSource, UITableViewDelegate, MACellActionDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIBarButtonItem    *cancelBarItem;

@property (nonatomic, assign) BOOL     isShowDateCellPicker;
@property (nonatomic, strong) MAccount *account;
@property (nonatomic, strong) MGroup   *group;
@property (nonatomic, strong) NSArray  *payers;
@property (nonatomic, strong) NSArray  *consumers;
@property (nonatomic, copy) NSString   *placeName;
@property (nonatomic, assign) CLLocationDegrees  latitude;
@property (nonatomic, assign) CLLocationDegrees  longitude;

@property (nonatomic, strong) NSIndexPath *registKeyboardIndexPath;
@property (nonatomic, assign) CGFloat tableViewHeightBeforeInput;

@property (nonatomic, assign) CGFloat  editingTotalFee;
@property (nonatomic, strong) NSDate   *editingDate;
@property (nonatomic, copy) NSString   *editingPlaceName;
@property (nonatomic, assign) CLLocationDegrees  editingLatitude;
@property (nonatomic, assign) CLLocationDegrees  editingLongitude;
@property (nonatomic, copy) NSString   *editingDetail;
@property (nonatomic, strong) NSArray  *editingPayers;
@property (nonatomic, strong) NSArray  *editingConsumers;

@end

@implementation MAAccountDetailViewController

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.isShowDateCellPicker = NO;
        self.tableViewHeightBeforeInput = 0.0f;
    }

    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShowNotification:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForSelectedRows] withRowAnimation:UITableViewRowAnimationFade];

    if (!self.group) {
        [MBProgressHUD showTextHUDOnView:[[UIApplication sharedApplication].delegate window]
                                    text:@"无效的小组，无法创建账目~"
                         completionBlock:^{
                             [self disappear:YES];
                         }
                                animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    MA_HIDE_KEYBOARD;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.navigationItem setRightBarButtonItem:self.editButtonItem animated:YES];
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;
    self.tableView.clipsToBounds = NO;

    if (self.account) {
        [self setEditing:NO animated:NO];
        self.title = @"账目详情";
    } else {
        [self setEditing:YES animated:NO];
        self.title = @"创建账目";
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kSegueAccountDetailToMemberList]) {
    } else {
        MA_QUICK_ASSERT(NO, @"Unknow segue - MAAccountDetailViewController");
    }
}

- (void)loadData
{
    if (self.isEditing) {
        self.payers = self.editingPayers;
        self.consumers = self.editingConsumers;
        self.placeName = self.editingPlaceName;
        self.latitude = self.editingLatitude;
        self.longitude = self.editingLongitude;
    } else {
        self.payers = [AccountManager feeOfMembersForAccount:self.account isPayers:YES];
        self.consumers = [AccountManager feeOfMembersForAccount:self.account isPayers:YES];
        self.placeName = self.account.place.placeName;
        self.latitude = [self.account.place.latitude doubleValue];
        self.longitude = [self.account.place.longitude doubleValue];
    }

    NSRange range;
    range.location = 0;
    range.length = kAccountDetailNumberOfSections;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:range] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)clearEditingData
{
    self.editingTotalFee = 0.0f;
    self.editingDate = nil;
    self.editingPlaceName = nil;
    self.editingLatitude = 0.0f;
    self.editingLongitude = 0.0f;
    self.editingDetail = nil;
    self.editingPayers = nil;
    self.editingConsumers = nil;
}

- (void)refreshEditingData
{
    self.editingTotalFee = [self.account.totalFee doubleValue];
    self.editingDate = self.account.accountDate;
    self.editingPlaceName = self.account.place.placeName;
    self.editingLatitude = [self.account.place.latitude doubleValue];
    self.editingLongitude = [self.account.place.longitude doubleValue];
    self.editingDetail = self.account.detail;
    self.editingPayers = [AccountManager feeOfMembersForAccount:self.account isPayers:YES];
    self.editingConsumers = [AccountManager feeOfMembersForAccount:self.account isPayers:YES];
}

- (NSDictionary *)tableView:(UITableView *)tableView infoOfSection:(NSInteger)section row:(NSInteger)row
{
    NSInteger rowCount = 0;
    NSString  *cellIdentifier = @"";
    CGFloat   cellHeight = 0.0f;
    NSString  *headerTitle = @"";

    switch (section) {
    case FeeSectionType:
        {
            headerTitle = @"消费金额";
            rowCount = 1;
            cellIdentifier = [MAAccountDetailFeeCell reuseIdentifier];
            cellHeight = [MAAccountDetailFeeCell cellHeight:@(self.editing)];
            break;
        }

    case AccountDetailSectionType:
        {
            headerTitle = @"消费信息";
            rowCount = 4;

            switch (row) {
            case DetailDateType:
                {
                    cellIdentifier = [MAAccountDetailDateCell reuseIdentifier];
                    cellHeight = [MAAccountDetailDateCell cellHeight:@(self.isShowDateCellPicker)];
                    break;
                }

            case DetailPayerType:
                {
                    cellIdentifier = [MAAccountDetailPayersCell reuseIdentifier];
                    cellHeight = [MAAccountDetailPayersCell cellHeight:@(self.editing)];
                    break;
                }

            case DetailConsumerType:
                {
                    cellIdentifier = [MAAccountDetailConsumersCell reuseIdentifier];
                    cellHeight = [MAAccountDetailConsumersCell cellHeight:@(self.editing)];
                    break;
                }

            case DetailLocationType:
                {
                    cellIdentifier = [MAAccountDetailLocationCell reuseIdentifier];
                    cellHeight = [MAAccountDetailLocationCell cellHeight:@(self.editing)];
                    break;
                }

            default:
                MA_QUICK_ASSERT(NO, @"Unknow row - MAAccountDetailViewController");
            }
            break;
        }

    case MembersSectionType:
        {
            headerTitle = @"消费伙伴";
            rowCount = self.payers.count + self.consumers.count;

            if (0 >= rowCount) {
                rowCount = 1;
            }

            cellIdentifier = [MAAccountDetailConsumerDetailCell reuseIdentifier];
            cellHeight = [MAAccountDetailConsumerDetailCell cellHeight:nil];
            break;
        }

    case AccountDescriptionSectionType:
        {
            headerTitle = @"消费描述";
            rowCount = 1;
            cellIdentifier = [MAAccountDetailDescriptionCell reuseIdentifier];
            cellHeight = [MAAccountDetailDescriptionCell cellHeight:nil];
            break;
        }

    default:
        MA_QUICK_ASSERT(NO, @"Unknow section - MAAccountDetailViewController");
    }

    NSDictionary *info = @{kAccountDetailRowCount : @(rowCount),
                           kAccountDetailCellIdentifier : cellIdentifier,
                           kAccountDetailCellHeight : @(cellHeight),
                           kAccountDetailHeaderTitle : headerTitle};
    return info;
}

#pragma mark - notification actions

- (void)keyboardDidShowNotification:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    CGRect keyboardFrame = [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (0 >= self.tableViewHeightBeforeInput) {
        self.tableViewHeightBeforeInput = self.tableView.height;
        self.tableView.height -= keyboardFrame.size.height;
    } else {
        self.tableView.height = self.tableViewHeightBeforeInput - keyboardFrame.size.height;
    }

    if (self.registKeyboardIndexPath) {
        [self.tableView scrollToRowAtIndexPath:self.registKeyboardIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }
}

- (void)keyboardWillHideNotification:(NSNotification *)notification
{
    if (0 < self.tableViewHeightBeforeInput) {
        self.tableView.height = self.tableViewHeightBeforeInput;
    }
    self.tableViewHeightBeforeInput = 0.0f;
    self.registKeyboardIndexPath = nil;
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *rowInfo = [self tableView:tableView infoOfSection:indexPath.section row:indexPath.row];
    NSString     *cellIdentifier = [rowInfo objectForKey:kAccountDetailCellIdentifier];
    id           cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    switch (indexPath.section) {
    case FeeSectionType:
        {
            MAAccountDetailFeeCell *detailCell = cell;
            detailCell.status = self.isEditing;
            [detailCell reuseCellWithData:[self.account.totalFee stringValue]];
            detailCell.actionDelegate = self;
            break;
        }

    case AccountDetailSectionType:
        {
            switch (indexPath.row) {
            case DetailDateType:
                {
                    MAAccountDetailDateCell *detailCell = cell;
                    detailCell.status = self.isEditing;
                    detailCell.isDatePickerHidden = !self.isShowDateCellPicker;
                    [detailCell reuseCellWithData:self.account.accountDate];
                    break;
                }

            case DetailPayerType:
                {
                    MAAccountDetailPayersCell *detailCell = cell;
                    detailCell.status = self.isEditing;
                    [detailCell reuseCellWithData:@"1000ren"];
                    break;
                }

            case DetailConsumerType:
                {
                    MAAccountDetailConsumersCell *detailCell = cell;
                    detailCell.status = self.isEditing;
                    [detailCell reuseCellWithData:@"1000ren"];
                    break;
                }

            case DetailLocationType:
                {
                    MAAccountDetailLocationCell *detailCell = cell;
                    detailCell.status = self.isEditing;
                    [detailCell reuseCellWithData:self.placeName];
                    break;
                }

            default:
                MA_QUICK_ASSERT(NO, @"Unknow row - MAAccountDetailViewController");
            }
            break;
        }

    case MembersSectionType:
        {
            MAAccountDetailConsumerDetailCell *detailCell = cell;
            detailCell.status = self.isEditing;
            detailCell.actionDelegate = self;
            NSUInteger index = indexPath.row;
            MAFeeOfMember *data = nil;
            if (index < self.payers.count) {
                data = self.payers[index];
            } else if ((index - self.payers.count) < self.consumers.count) {
                data = self.consumers[index];
            }
            [detailCell reuseCellWithData:data];
            break;
        }

    case AccountDescriptionSectionType:
        {
            MAAccountDetailDescriptionCell *detailCell = cell;
            detailCell.status = self.isEditing;
            detailCell.actionDelegate = self;
            [detailCell reuseCellWithData:self.account.detail];
            break;
        }

    default:
        MA_QUICK_ASSERT(NO, @"Unknow section - MAAccountDetailViewController");
    }

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSDictionary *sectionInfo = [self tableView:tableView infoOfSection:section row:0];
    NSInteger    rowCount = [[sectionInfo objectForKey:kAccountDetailRowCount] integerValue];

    return rowCount;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kAccountDetailNumberOfSections;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionInfo = [self tableView:tableView infoOfSection:indexPath.section row:indexPath.row];
    CGFloat      rowHeight = [[sectionInfo objectForKey:kAccountDetailCellHeight] floatValue];

    return rowHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kAccountDetailSectionHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    MAAccountDetailSectionHeader *headerView = [[MAAccountDetailSectionHeader alloc] initWithHeaderTitle:@"未知错误"];

    NSDictionary *sectionInfo = [self tableView:tableView infoOfSection:section row:0];

    [headerView setHeaderTitle:[sectionInfo objectForKey:kAccountDetailHeaderTitle]];

    return headerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MA_HIDE_KEYBOARD;

    if (!self.editing) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

    if ((AccountDetailSectionType == indexPath.section) &&
        ((DetailPayerType == indexPath.row) || (DetailConsumerType == indexPath.row))) {
        [self performSegueWithIdentifier:kSegueAccountDetailToMemberList sender:nil];
    } else if ((AccountDetailSectionType == indexPath.section) &&
        (DetailDateType == indexPath.row)) {
        self.isShowDateCellPicker = !self.isShowDateCellPicker;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - MACellActionDelegate

- (BOOL)actionWithData:(id)data cell:(UITableViewCell *)cell type:(NSInteger)type
{
    self.registKeyboardIndexPath = [self.tableView indexPathForCell:cell];

    if (self.tableViewHeightBeforeInput > 0.0f) {
        [self.tableView scrollToRowAtIndexPath:self.registKeyboardIndexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    }

    return YES;
}

#pragma mark property method

- (UIBarButtonItem *)cancelBarItem
{
    if (_cancelBarItem) {
        return _cancelBarItem;
    }

    _cancelBarItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didCancelButtonTaped:)];
    return _cancelBarItem;
}

#pragma mark UI action

- (void)didEditButtonTaped:(UIBarButtonItem *)sender
{
    [self setEditing:YES animated:YES];
}

- (void)didSaveButtonTaped:(UIBarButtonItem *)sender
{
    MA_HIDE_KEYBOARD;

    if (self.account) {
        // not create mode
        NSMutableSet *memberSet = [NSMutableSet setWithArray:self.editingPayers];
        [memberSet addObjectsFromArray:self.editingConsumers];
        // check total fee
        if (0.0f != [AccountManager totalFeeOfMambers:memberSet memberToAccounts:self.account.relationshipToMember]) {
            [MBProgressHUD showTextHUDOnView:[UIApplication sharedApplication].delegate.window
                                        text:@"总支出和总付款不一样哦~"
                             completionBlock:nil
                                    animated:YES];
            return;
        }
        BOOL updated = [AccountManager updateAccount:self.account
                                                date:self.editingDate
                                           placeName:self.editingPlaceName
                                            latitude:self.editingLatitude
                                           longitude:self.editingLongitude
                                              detail:self.editingDetail
                                        feeOfMembers:memberSet];

        if (updated) {
            [self setEditing:NO animated:YES];
        } else {
            [MBProgressHUD showTextHUDOnView:[UIApplication sharedApplication].delegate.window
                                        text:@"更新失败"
                             completionBlock:nil
                                    animated:YES];
        }
    } else {
        // create mode
        NSMutableSet *memberSet = [NSMutableSet setWithArray:self.editingPayers];
        [memberSet addObjectsFromArray:self.editingConsumers];
        // check total fee
        if (0.0f != [AccountManager totalFeeOfMambers:memberSet memberToAccounts:self.account.relationshipToMember]) {
            [MBProgressHUD showTextHUDOnView:[UIApplication sharedApplication].delegate.window
                                        text:@"总支出和总付款不一样哦~"
                             completionBlock:nil
                                    animated:YES];
            return;
        }
        self.account = [AccountManager createAccountWithGroup:self.group
                                                         date:self.editingDate
                                                    placeName:self.editingPlaceName
                                                     latitude:self.editingLatitude
                                                    longitude:self.editingLongitude
                                                       detail:self.editingDetail
                                                 feeOfMembers:memberSet];

        if (self.account) {
            [MBProgressHUD showTextHUDOnView:[UIApplication sharedApplication].delegate.window
                                        text:@"创建成功"
                             completionBlock:^{
                [self setEditing:NO animated:YES];
                [self disappear:YES];
            }

                                    animated:YES];
        } else {
            [MBProgressHUD showTextHUDOnView:[UIApplication sharedApplication].delegate.window
                                        text:@"创建失败"
                             completionBlock:nil
                                    animated:YES];
        }
    }
}

- (void)didCancelButtonTaped:(UIBarButtonItem *)sender
{
    if (self.editing) {
        MAAlertView *alert = nil;
        if (self.account) {
            alert = [MAAlertView alertWithTitle:@"确认放弃更改么？"
                                        message:nil
                                   buttonTitle1:@"点错了~"
                                   buttonBlock1:nil
                                   buttonTitle2:@"放弃更改"
                                   buttonBlock2:^{
                                       [self clearEditingData];
                                       [self setEditing:NO animated:YES];
                                   }];
        } else {
            alert = [MAAlertView alertWithTitle:@"确认放弃创建么？"
                                        message:nil
                                   buttonTitle1:@"点错了~"
                                   buttonBlock1:nil
                                   buttonTitle2:@"放弃创建"
                                   buttonBlock2:^{
                                       [self clearEditingData];
                                       [self disappear:YES];
                                   }];
        }

        [alert show];
    } else {
        MA_QUICK_ASSERT(NO, @"Wrong state, (didCancelButtonTaped:)");
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];

    if (editing) {
        [self.navigationItem setHidesBackButton:YES animated:YES];
        [self.navigationItem setLeftBarButtonItem:self.cancelBarItem animated:YES];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(didSaveButtonTaped:)] animated:YES];
        [self refreshEditingData];
    } else {
        self.isShowDateCellPicker = NO;
        [self.navigationItem setHidesBackButton:NO animated:YES];
        [self.navigationItem setLeftBarButtonItem:nil animated:YES];
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(didEditButtonTaped:)] animated:YES];
        [self clearEditingData];
    }

    [self loadData];
}

- (IBAction)didTappingHideKeyboardButton:(id)sender
{
    MA_HIDE_KEYBOARD;
}

#pragma mark - Public Method

- (void)setGroup:(MGroup *)group account:(MAccount *)account
{
    self.group = group;
    self.account = account;
}

@end