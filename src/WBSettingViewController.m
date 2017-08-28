//
//  WBSettingViewController.m
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import "WBSettingViewController.h"
#import "WeChatRedEnvelop.h"
#import "WBRedEnvelopConfig.h"
#import <objc/objc-runtime.h>
#import "WBMultiSelectContactsViewController.h"
#import "WBMultiSelectGroupsViewController.h"
#import "WBChatRoomSensitiveViewController.h"
#import "WBToast.h"

@interface WBSettingViewController () <MultiSelectGroupsViewControllerDelegate>

@property (nonatomic, strong) MMTableViewInfo *tableViewInfo;

@end

@implementation WBSettingViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        _tableViewInfo = [[objc_getClass("MMTableViewInfo") alloc] initWithFrame:[UIScreen mainScreen].bounds style:UITableViewStyleGrouped];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initTitle];
    [self reloadTableData];
    
    MMTableView *tableView = [self.tableViewInfo getTableView];
    [self.view addSubview:tableView];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [self stopLoading];
}

- (void)initTitle {
    self.title = @"微信小助手";
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0]}];
}

- (void)reloadTableData {
    [self.tableViewInfo clearAllSection];
    
    [self addBasicSettingSection];    
    [self addAdvanceSettingSection];
	[self addOtherSection];
    
//    [self addNiubilitySection];
    [self addContactVerifySection];
    [self addAutoReplySection];
    [self addGroupSettingSection];
    
    MMTableView *tableView = [self.tableViewInfo getTableView];
    [tableView reloadData];
}

#pragma mark - BasicSetting

- (void)addBasicSettingSection {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoDefaut];
    
    [sectionInfo addCell:[self createAutoReceiveRedEnvelopCell]];
    [sectionInfo addCell:[self createDelaySettingCell]];
    
    [self.tableViewInfo addSection:sectionInfo];
}


- (MMTableViewCellInfo *)createAutoReceiveRedEnvelopCell {
    return [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(switchRedEnvelop:) target:self title:@"自动抢红包" on:[WBRedEnvelopConfig sharedConfig].autoReceiveEnable];
}

- (MMTableViewCellInfo *)createDelaySettingCell {
    NSInteger delaySeconds = [WBRedEnvelopConfig sharedConfig].delaySeconds;
    NSString *delayString = delaySeconds == 0 ? @"不延迟" : [NSString stringWithFormat:@"%ld 秒", (long)delaySeconds];
    
    MMTableViewCellInfo *cellInfo;
    if ([WBRedEnvelopConfig sharedConfig].autoReceiveEnable) {
        cellInfo = [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(settingDelay) target:self title:@"延迟抢红包" rightValue: delayString accessoryType:1];
    } else {
        cellInfo = [objc_getClass("MMTableViewCellInfo") normalCellForTitle:@"延迟抢红包" rightValue: @"抢红包已关闭"];
    }
    return cellInfo;
}

- (void)switchRedEnvelop:(UISwitch *)envelopSwitch {
    [WBRedEnvelopConfig sharedConfig].autoReceiveEnable = envelopSwitch.on;
    
    [self reloadTableData];
}

- (void)settingDelay {
    UIAlertView *alert = [UIAlertView new];
    alert.title = @"延迟抢红包(秒)";
    
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.delegate = self;
    [alert addButtonWithTitle:@"取消"];
    [alert addButtonWithTitle:@"确定"];
    
    [alert textFieldAtIndex:0].placeholder = @"延迟时长";
    [alert textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 3) {
		if (buttonIndex == 1) {
			NSUInteger customStepCount = [[alertView textFieldAtIndex:0].text integerValue];
			[[NSUserDefaults standardUserDefaults] setInteger:customStepCount forKey:@"WeChatTweakCustomStepCountKey"];
			[self reloadTableData];
		}
		return;
	}
    if (buttonIndex == 1) {
        NSString *delaySecondsString = [alertView textFieldAtIndex:0].text;
        NSInteger delaySeconds = [delaySecondsString integerValue];
        
        [WBRedEnvelopConfig sharedConfig].delaySeconds = delaySeconds;
        
        [self reloadTableData];
    }
}

#pragma mark - ProSetting
- (void)addAdvanceSettingSection {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"高级功能"];
    
    [sectionInfo addCell:[self createReceiveSelfRedEnvelopCell]];
    [sectionInfo addCell:[self createQueueCell]];
    [sectionInfo addCell:[self createBlackListCell]];
    [sectionInfo addCell:[self createAbortRemokeMessageCell]];
    //[sectionInfo addCell:[self createKeywordFilterCell]];
    
    [self.tableViewInfo addSection:sectionInfo];
}

- (MMTableViewCellInfo *)createReceiveSelfRedEnvelopCell {
    return [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingReceiveSelfRedEnvelop:) target:self title:@"抢自己发的红包" on:[WBRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop];
}

- (MMTableViewCellInfo *)createQueueCell {
    return [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingReceiveByQueue:) target:self title:@"防止同时抢多个红包" on:[WBRedEnvelopConfig sharedConfig].serialReceive];
}

- (MMTableViewCellInfo *)createBlackListCell {
    
    if ([WBRedEnvelopConfig sharedConfig].blackList.count == 0) {
        return [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(showBlackList) target:self title:@"群聊过滤" rightValue:@"已关闭" accessoryType:1];
    } else {
        NSString *blackListCountStr = [NSString stringWithFormat:@"已选 %lu 个群", (unsigned long)[WBRedEnvelopConfig sharedConfig].blackList.count];
        return [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(showBlackList) target:self title:@"群聊过滤" rightValue:blackListCountStr accessoryType:1];
    }
    
}

- (MMTableViewSectionInfo *)createAbortRemokeMessageCell {
    return [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingMessageRevoke:) target:self title:@"消息防撤回" on:[WBRedEnvelopConfig sharedConfig].revokeEnable];
}

- (MMTableViewSectionInfo *)createKeywordFilterCell {
    return [objc_getClass("MMTableViewCellInfo") normalCellForTitle:@"关键词过滤" rightValue:@"开发中..."];
}

- (void)settingReceiveSelfRedEnvelop:(UISwitch *)receiveSwitch {
    [WBRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop = receiveSwitch.on;
}

- (void)settingReceiveByQueue:(UISwitch *)queueSwitch {
    [WBRedEnvelopConfig sharedConfig].serialReceive = queueSwitch.on;
}

- (void)showBlackList {
    WBMultiSelectGroupsViewController *contactsViewController = [[WBMultiSelectGroupsViewController alloc] initWithBlackList:[WBRedEnvelopConfig sharedConfig].blackList];
    contactsViewController.delegate = self;
    
    MMUINavigationController *navigationController = [[objc_getClass("MMUINavigationController") alloc] initWithRootViewController:contactsViewController];
    
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)settingMessageRevoke:(UISwitch *)revokeSwitch {
    [WBRedEnvelopConfig sharedConfig].revokeEnable = revokeSwitch.on;
}

#pragma mark - Other
- (void)addOtherSection {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"其它设置"];
    
    [sectionInfo addCell:[self addCustomStepCount]];
    [sectionInfo addCell:[self addBackground]];
    
    [self.tableViewInfo addSection:sectionInfo];
}

- (MMTableViewCellInfo *)addCustomStepCount {
	NSUInteger customStepCount = [[NSUserDefaults standardUserDefaults] integerForKey:@"WeChatTweakCustomStepCountKey"];
	NSString *customStepCountString = customStepCount == 0 ? @"不设置" : [NSString stringWithFormat:@"%@ 步", @(customStepCount)];
    return [objc_getClass("MMTableViewCellInfo") normalCellForSel:@selector(setCustomStepCount) target:self title:@"自定义步数" rightValue:customStepCountString accessoryType:1];
}

- (void)setCustomStepCount {
	UIAlertView *alertView = [[UIAlertView alloc] init];
	alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
	alertView.delegate = self;
	alertView.title = @"设置步数";
	alertView.tag = 3;
	[alertView addButtonWithTitle:@"取消"];
	[alertView addButtonWithTitle:@"确定"];
	[alertView textFieldAtIndex:0].placeholder = @"输入自定义步数";
	[alertView textFieldAtIndex:0].keyboardType = UIKeyboardTypeNumberPad;
	[alertView show];
}

- (MMTableViewCellInfo *)addBackground {
	BOOL isAutoRedEnvelopesKeepRunning = [[NSUserDefaults standardUserDefaults] boolForKey:@"WeChatTweakAutoRedEnvelopesKeepRunningKey"];
	return [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(switchAutoRedEnvelopesKeepRunning:) target:self title:@"后台运行以获取消息或红包" on:isAutoRedEnvelopesKeepRunning];
}

- (void)switchAutoRedEnvelopesKeepRunning:(UISwitch *)sender {
	[[NSUserDefaults standardUserDefaults] setBool:sender.on forKey:@"WeChatTweakAutoRedEnvelopesKeepRunningKey"];
	[self reloadTableData];
}

#pragma mark - MultiSelectGroupsViewControllerDelegate
- (void)onMultiSelectGroupCancel {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (void)onMultiSelectGroupReturn:(NSArray *)arg1 {
    [WBRedEnvelopConfig sharedConfig].blackList = arg1;
    
    [self reloadTableData];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TKkk
/*
- (void)addNiubilitySection {
    MMTableViewSectionInfo *sectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"装逼必备" Footer:nil];
    [sectionInfo addCell:[self createStepSwitchCell]];
    
    BOOL changeStepEnable = [[WBRedEnvelopConfig sharedConfig] changeStepEnable];
    if (changeStepEnable) {
        [sectionInfo addCell:[self createStepCountCell]];
    }
    [sectionInfo addCell:[self createRevokeSwitchCell]];
    
    [self.tableViewInfo addSection:sectionInfo];
}
*/
- (void)addContactVerifySection {
    MMTableViewSectionInfo *verifySectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"过滤好友请求设置" Footer:nil];
    [verifySectionInfo addCell:[self createVerifySwitchCell]];
    
    BOOL autoVerifyEnable = [[WBRedEnvelopConfig sharedConfig] autoVerifyEnable];
    if (autoVerifyEnable) {
        [verifySectionInfo addCell:[self createAutoVerifyCell]];
        
        BOOL autoWelcomeEnable = [[WBRedEnvelopConfig sharedConfig] autoWelcomeEnable];
        [verifySectionInfo addCell:[self createWelcomeSwitchCell]];
        if (autoWelcomeEnable) {
            [verifySectionInfo addCell:[self createWelcomeCell]];
        }
    }
    [self.tableViewInfo addSection:verifySectionInfo];
}

- (void)addAutoReplySection {
    MMTableViewSectionInfo *autoReplySectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"自动回复设置" Footer:nil];
    [autoReplySectionInfo addCell:[self createAutoReplySwitchCell]];
    
    BOOL autoReplyEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyEnable];
    if (autoReplyEnable) {
        [autoReplySectionInfo addCell:[self createAutoReplyKeywordCell]];
        [autoReplySectionInfo addCell:[self createAutoReplyTextCell]];
    }
    [self.tableViewInfo addSection:autoReplySectionInfo];
}

- (void)addGroupSettingSection {
    MMTableViewSectionInfo *groupSectionInfo = [objc_getClass("MMTableViewSectionInfo") sectionInfoHeader:@"群设置" Footer:nil];
    [groupSectionInfo addCell:[self createSetChatRoomDescCell]];
    [groupSectionInfo addCell:[self createAutoDeleteMemberCell]];
    [groupSectionInfo addCell:[self createWelcomeJoinChatRoomSwitchCell]];
    
    BOOL welcomeJoinChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomEnable];
    if (welcomeJoinChatRoomEnable) {
        [groupSectionInfo addCell:[self createWelcomeJoinChatRoomCell]];
    }
    [groupSectionInfo addCell:[self createAutoReplyChatRoomSwitchCell]];
    
    BOOL autoReplyChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomEnable];
    if (autoReplyChatRoomEnable) {
        [groupSectionInfo addCell:[self createAutoReplyChatRoomKeywordCell]];
        [groupSectionInfo addCell:[self createAutoReplyChatRoomTextCell]];
    }
    
    [self.tableViewInfo addSection:groupSectionInfo];
}
/*
#pragma mark - 装逼必备
- (MMTableViewCellInfo *)createStepSwitchCell {
    BOOL changeStepEnable = [[WBRedEnvelopConfig sharedConfig] changeStepEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingStepSwitch:) target:self title:@"是否修改微信步数" on:changeStepEnable];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createStepCountCell {
    NSInteger deviceStep = [[WBRedEnvelopConfig sharedConfig] deviceStep];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingStepCount) target:self title:@"微信运动步数" rightValue:[NSString stringWithFormat:@"%ld", (long)deviceStep] accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createRevokeSwitchCell {
    BOOL preventRevokeEnable = [[WBRedEnvelopConfig sharedConfig] preventRevokeEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingRevokeSwitch:) target:self title:@"拦截撤回消息" on:preventRevokeEnable];
    
    return cellInfo;
}
*/
#pragma mark - 添加好友设置
- (MMTableViewCellInfo *)createVerifySwitchCell {
    BOOL autoVerifyEnable = [[WBRedEnvelopConfig sharedConfig] autoVerifyEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingVerifySwitch:) target:self title:@"开启自动添加好友" on:autoVerifyEnable];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoVerifyCell {
    NSString *verifyText = [[WBRedEnvelopConfig sharedConfig] autoVerifyKeyword];
    verifyText = verifyText.length == 0 ? @"请填写" : verifyText;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingVerify) target:self title:@"自动通过关键词" rightValue:verifyText accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createWelcomeSwitchCell {
    BOOL autoVerifyEnable = [[WBRedEnvelopConfig sharedConfig] autoWelcomeEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingWelcomeSwitch:) target:self title:@"开启欢迎语" on:autoVerifyEnable];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createWelcomeCell {
    NSString *welcomeText = [[WBRedEnvelopConfig sharedConfig] autoWelcomeText];
    welcomeText = welcomeText.length == 0 ? @"请填写" : welcomeText;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingWelcome) target:self title:@"欢迎语内容" rightValue:welcomeText accessoryType:1];
    
    return cellInfo;
}

#pragma mark - 自动回复设置
- (MMTableViewCellInfo *)createAutoReplySwitchCell {
    BOOL autoReplyEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingAutoReplySwitch:)target:self title:@"开启个人消息自动回复" on:autoReplyEnable];;
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoReplyKeywordCell {
    NSString *autoReplyKeyword = [[WBRedEnvelopConfig sharedConfig] autoReplyKeyword];
    autoReplyKeyword = autoReplyKeyword.length == 0 ? @"请填写" : autoReplyKeyword;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingAutoReplyKeyword) target:self title:@"特定消息" rightValue:autoReplyKeyword accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoReplyTextCell {
    NSString *autoReply = [[WBRedEnvelopConfig sharedConfig] autoReplyText];
    autoReply = autoReply.length == 0 ? @"请填写" : autoReply;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingAutoReply) target:self title:@"自动回复内容" rightValue:autoReply accessoryType:1];
    
    return cellInfo;
}

#pragma mark - 群相关设置

- (MMTableViewCellInfo *)createSetChatRoomDescCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingChatRoomDesc) target:self title:@"群公告设置" rightValue:nil accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoDeleteMemberCell {
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingAutoDeleteMember) target:self title:@"自动踢人设置" rightValue:nil accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createWelcomeJoinChatRoomSwitchCell {
    BOOL welcomeJoinChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingWelcomeJoinChatRoomSwitch:)target:self title:@"开启入群欢迎语" on:welcomeJoinChatRoomEnable];;
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createWelcomeJoinChatRoomCell {
    NSString *welcomeJoinChatRoomText = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomText];
    welcomeJoinChatRoomText = welcomeJoinChatRoomText.length == 0 ? @"请填写" : welcomeJoinChatRoomText;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingWelcomeJoinChatRoom) target:self title:@"入群欢迎语" rightValue:welcomeJoinChatRoomText accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoReplyChatRoomSwitchCell {
    BOOL autoReplyChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomEnable];
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo") switchCellForSel:@selector(settingAutoReplyChatRoomSwitch:)target:self title:@"开启群消息自动回复" on:autoReplyChatRoomEnable];;
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoReplyChatRoomKeywordCell {
    NSString *autoReplyChatRoomKeyword = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomKeyword];
    autoReplyChatRoomKeyword = autoReplyChatRoomKeyword.length == 0 ? @"请填写" : autoReplyChatRoomKeyword;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingAutoReplyChatRoomKeyword) target:self title:@"特定消息" rightValue:autoReplyChatRoomKeyword accessoryType:1];
    
    return cellInfo;
}

- (MMTableViewCellInfo *)createAutoReplyChatRoomTextCell {
    NSString *autoReplyChatRoomText = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomText];
    autoReplyChatRoomText = autoReplyChatRoomText.length == 0 ? @"请填写" : autoReplyChatRoomText;
    MMTableViewCellInfo *cellInfo = [objc_getClass("MMTableViewCellInfo")  normalCellForSel:@selector(settingAutoReplyChatRoom) target:self title:@"自动回复内容" rightValue:autoReplyChatRoomText accessoryType:1];
    
    return cellInfo;
}

#pragma mark - 设置cell相应的方法
/*
- (void)settingStepSwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setChangeStepEnable:arg.on];
    [self reloadTableData];
}

- (void)settingStepCount {
    NSInteger deviceStep = [[WBRedEnvelopConfig sharedConfig] deviceStep];
    [self alertControllerWithTitle:@"微信运动设置"
                           message:@"步数需比之前设置的步数大才能生效，最大值为98800"
                           content:[NSString stringWithFormat:@"%ld", (long)deviceStep]
                       placeholder:@"请输入步数"
                      keyboardType:UIKeyboardTypeNumberPad
                               blk:^(UITextField *textField) {
                                   [[WBRedEnvelopConfig sharedConfig] setDeviceStep:textField.text.integerValue];
                                   [self reloadTableData];
                               }];
}

- (void)settingRevokeSwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setPreventRevokeEnable:arg.on];
    [self reloadTableData];
}
*/
- (void)settingVerifySwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setAutoVerifyEnable:arg.on];
    [self reloadTableData];
}

- (void)settingVerify {
    NSString *verifyText = [[WBRedEnvelopConfig sharedConfig] autoVerifyKeyword];
    [self alertControllerWithTitle:@"自动通过设置"
                           message:@"新的好友发送的验证内容与该关键字一致时，则自动通过"
                           content:verifyText
                       placeholder:@"请输入好友请求关键字"
                               blk:^(UITextField *textField) {
                                   [[WBRedEnvelopConfig sharedConfig] setAutoVerifyKeyword:textField.text];
                                   [self reloadTableData];
                                   CMessageMgr *mgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CMessageMgr")];
                                   [mgr GetHelloUsers:@"fmessage" Limit:0 OnlyUnread:0];
                               }];
}


- (void)settingWelcomeSwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setAutoWelcomeEnable:arg.on];
    [self reloadTableData];
}

- (void)settingWelcome {
    WBEditViewController *editVC = [[WBEditViewController alloc] init];
    editVC.text = [[WBRedEnvelopConfig sharedConfig] autoWelcomeText];
    [editVC setEndEditing:^(NSString *text) {
        [[WBRedEnvelopConfig sharedConfig] setAutoWelcomeText:text];
        [self reloadTableData];
    }];
    editVC.title = @"请输入欢迎语内容";
    editVC.placeholder = @"当自动通过好友请求时，则自动发送欢迎语；\n若手动通过，则不发送";
    [self.navigationController PushViewController:editVC animated:YES];
}

- (void)settingAutoReplySwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setAutoReplyEnable:arg.on];
    [self reloadTableData];
}

- (void)settingAutoReplyKeyword {
    NSString *autoReplyKeyword = [[WBRedEnvelopConfig sharedConfig] autoReplyKeyword];
    [self alertControllerWithTitle:@"个人消息自动回复"
                           content:autoReplyKeyword
                       placeholder:@"请输入消息关键字"
                               blk:^(UITextField *textField) {
                                   [[WBRedEnvelopConfig sharedConfig] setAutoReplyKeyword:textField.text];
                                   [self reloadTableData];
                               }];
}

- (void)settingAutoReply {
    WBEditViewController *editViewController = [[WBEditViewController alloc] init];
    editViewController.text = [[WBRedEnvelopConfig sharedConfig] autoReplyText];
    [editViewController setEndEditing:^(NSString *text) {
        [[WBRedEnvelopConfig sharedConfig] setAutoReplyText:text];
        [self reloadTableData];
    }];
    editViewController.title = @"请输入自动回复的内容";
    [self.navigationController PushViewController:editViewController animated:YES];
}

- (void)settingAutoReplyChatRoomSwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setAutoReplyChatRoomEnable:arg.on];
    [self reloadTableData];
}

- (void)settingAutoReplyChatRoomKeyword {
    NSString *autoReplyChatRoomKeyword = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomKeyword];
    [self alertControllerWithTitle:@"群消息自动回复"
                           content:autoReplyChatRoomKeyword
                       placeholder:@"请输入消息关键字"
                               blk:^(UITextField *textField) {
                                   [[WBRedEnvelopConfig sharedConfig] setAutoReplyChatRoomKeyword:textField.text];
                                   [self reloadTableData];
                               }];
}

- (void)settingAutoReplyChatRoom {
    WBEditViewController *editViewController = [[WBEditViewController alloc] init];
    editViewController.text = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomText];
    [editViewController setEndEditing:^(NSString *text) {
        [[WBRedEnvelopConfig sharedConfig] setAutoReplyChatRoomText:text];
        [self reloadTableData];
    }];
    editViewController.title = @"请输入自动回复的内容";
    [self.navigationController PushViewController:editViewController animated:YES];
}

- (void)settingWelcomeJoinChatRoomSwitch:(UISwitch *)arg {
    [[WBRedEnvelopConfig sharedConfig] setWelcomeJoinChatRoomEnable:arg.on];
    [self reloadTableData];
}

- (void)settingWelcomeJoinChatRoom {
    WBEditViewController *editVC = [[WBEditViewController alloc] init];
    editVC.text = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomText];
    editVC.title = @"请输入入群欢迎语";
    [editVC setEndEditing:^(NSString *text) {
        [[WBRedEnvelopConfig sharedConfig] setWelcomeJoinChatRoomText:text];
        [self reloadTableData];
    }];
    [self.navigationController PushViewController:editVC animated:YES];
}

- (void)settingChatRoomDesc {
    WBMultiSelectContactsViewController *selectVC = [[WBMultiSelectContactsViewController alloc] init];
    selectVC.title = @"我创建的群聊";
    [self.navigationController PushViewController:selectVC animated:YES];
}

- (void)settingAutoDeleteMember {
    WBChatRoomSensitiveViewController *vc = [[WBChatRoomSensitiveViewController alloc] init];
    vc.title = @"设置敏感词";
    [self.navigationController PushViewController:vc animated:YES];
}

// - (void)settingAutoCreateGroup {
//     [self alertControllerWithTitle:@"选择联系人"
//                            message:nil
//                        placeholder:@"请输入联系人过滤条件"
//                                blk:^(UITextField *textField) {
//                                    CContactMgr *contactMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CContactMgr")];
//
//                                    NSArray *contactArray = [contactMgr getContactList:1 contactType:0];
//                                    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((m_nsNickName CONTAINS %@) OR (m_nsRemark CONTAINS %@)) AND isChatroom = 0 AND m_isPlugin == 0 AND m_uiFriendScene != 0", textField.text, textField.text];
//                                    NSArray *filteredArray = [contactArray filteredArrayUsingPredicate:predicate];
//                                    NSMutableArray *memberList = [[NSMutableArray alloc] init];
//                                    [filteredArray enumerateObjectsUsingBlock:^(CContact *contact, NSUInteger idx, BOOL * _Nonnull stop) {
//                                          GroupMember *member = [[objc_getClass("GroupMember") alloc] init];
//                                          member.m_nsMemberName = contact.m_nsUsrName;
//                                          member.m_uiMemberStatus = 0;
//                                          member.m_nsNickName = contact.m_nsNickName;
//                                          [memberList addObject:member];
//                                     }];
//
//                                     [self alertControllerWithTitle:@"群名称"
//                                                            message:nil
//                                                        placeholder:@"请输入群名称"
//                                                                blk:^(UITextField *textField) {
//                                         CGroupMgr *groupMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CGroupMgr")];
//                                         [groupMgr CreateGroup:textField.text withMemberList:memberList];
//
//                                         [WBToast toast:@"建群成功，请在会话列表中查看..."];
//                                     }];
//                                }];
// }

- (void)alertControllerWithTitle:(NSString *)title content:(NSString *)content placeholder:(NSString *)placeholder blk:(void (^)(UITextField *))blk {
    [self alertControllerWithTitle:title message:nil content:content placeholder:placeholder blk:blk];
}

- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message content:(NSString *)content placeholder:(NSString *)placeholder blk:(void (^)(UITextField *))blk {
    [self alertControllerWithTitle:title message:message content:content placeholder:placeholder keyboardType:UIKeyboardTypeDefault blk:blk];
}

- (void)alertControllerWithTitle:(NSString *)title message:(NSString *)message content:(NSString *)content placeholder:(NSString *)placeholder keyboardType:(UIKeyboardType)keyboardType blk:(void (^)(UITextField *))blk  {
    UIAlertController *alertController = ({
        UIAlertController *alert = [UIAlertController
                                    alertControllerWithTitle:title
                                    message:message
                                    preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消"
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定"
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    if (blk) {
                                                        blk(alert.textFields.firstObject);
                                                    }
                                                }]];
        
        [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = placeholder;
            textField.text = content;
            textField.keyboardType = keyboardType;
        }];
        
        alert;
    });
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end
