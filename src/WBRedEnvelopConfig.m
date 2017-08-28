//
//  WBRedEnvelopConfig.m
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import "WBRedEnvelopConfig.h"
#import "WeChatRedEnvelop.h"

static NSString * const kDelaySecondsKey = @"XGDelaySecondsKey";
static NSString * const kAutoReceiveRedEnvelopKey = @"XGWeChatRedEnvelopSwitchKey";
static NSString * const kReceiveSelfRedEnvelopKey = @"WBReceiveSelfRedEnvelopKey";
static NSString * const kSerialReceiveKey = @"WBSerialReceiveKey";
static NSString * const kBlackListKey = @"WBBlackListKey";
static NSString * const kRevokeEnablekey = @"WBRevokeEnable";

static NSString * const KTKPreventRevokeEnableKey = @"KTKPreventRevokeEnableKey";
static NSString * const KTKChangeStepEnableKey = @"KTKChangeStepEnableKey";
static NSString * const kTKDeviceStepKey = @"kTKDeviceStepKey";
static NSString * const KTKAutoVerifyEnableKey = @"kTKAutoVerifyEnableKey";
static NSString * const kTKAutoVerifyKeywordKey = @"kTKAutoVerifyKeywordKey";
static NSString * const KTKAutoWelcomeEnableKey = @"KTKAutoWelcomeEnableKey";
static NSString * const kTKAutoWelcomeTextKey = @"kTKAutoWelcomeTextKey";
static NSString * const kTKAutoReplyEnableKey = @"kTKAutoReplyEnableKey";
static NSString * const kTKAutoReplyKeywordKey = @"kTKAutoReplyKeywordKey";
static NSString * const kTKAutoReplyTextKey = @"kTKAutoReplyTextKey";
static NSString * const kTKAutoReplyChatRoomEnableKey = @"kTKAutoReplyChatRoomEnableKey";
static NSString * const kTKAutoReplyChatRoomKeywordKey = @"kTKAutoReplyChatRoomKeywordKey";
static NSString * const kTKAutoReplyChatRoomTextKey = @"kTKAutoReplyChatRoomTextKey";
static NSString * const kTKWelcomeJoinChatRoomEnableKey = @"kTKWelcomeJoinChatRoomEnableKey";
static NSString * const kTKWelcomeJoinChatRoomTextKey = @"kTKWelcomeJoinChatRoomTextKey";
static NSString * const kTKAllChatRoomDescTextKey = @"kTKAllChatRoomDescTextKey";
static NSString * const kTKChatRoomSensitiveEnableKey = @"kTKChatRoomSensitiveEnableKey";
static NSString * const kTKChatRoomSensitiveArrayKey = @"kTKChatRoomSensitiveArrayKey";

@interface WBRedEnvelopConfig ()

@end

@implementation WBRedEnvelopConfig

+ (instancetype)sharedConfig {
    static WBRedEnvelopConfig *config = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        config = [WBRedEnvelopConfig new];
    });
    return config;
}

- (instancetype)init {
    if (self = [super init]) {
        _delaySeconds = [[NSUserDefaults standardUserDefaults] integerForKey:kDelaySecondsKey];
        _autoReceiveEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kAutoReceiveRedEnvelopKey];
        _serialReceive = [[NSUserDefaults standardUserDefaults] boolForKey:kSerialReceiveKey];
        _blackList = [[NSUserDefaults standardUserDefaults] objectForKey:kBlackListKey];
        _receiveSelfRedEnvelop = [[NSUserDefaults standardUserDefaults] boolForKey:kReceiveSelfRedEnvelopKey];
        _revokeEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kRevokeEnablekey];
        
        _preventRevokeEnable = [[NSUserDefaults standardUserDefaults] boolForKey:KTKPreventRevokeEnableKey];
        _changeStepEnable = [[NSUserDefaults standardUserDefaults] boolForKey:KTKChangeStepEnableKey];
        _deviceStep = [[[NSUserDefaults standardUserDefaults] objectForKey:kTKDeviceStepKey] intValue];
        _autoVerifyEnable = [[NSUserDefaults standardUserDefaults] boolForKey:KTKAutoVerifyEnableKey];
        _autoVerifyKeyword = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoVerifyKeywordKey];
        _autoWelcomeEnable = [[NSUserDefaults standardUserDefaults] boolForKey:KTKAutoWelcomeEnableKey];
        _autoWelcomeText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoWelcomeTextKey];
        _autoReplyEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKAutoReplyEnableKey];
        _autoReplyKeyword = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyKeywordKey];
        _autoReplyText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyTextKey];
        _autoReplyChatRoomEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKAutoReplyChatRoomEnableKey];
        _autoReplyChatRoomKeyword = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyChatRoomKeywordKey];
        _autoReplyChatRoomText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAutoReplyChatRoomTextKey];
        _welcomeJoinChatRoomEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKWelcomeJoinChatRoomEnableKey];
        _welcomeJoinChatRoomText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKWelcomeJoinChatRoomTextKey];
        _allChatRoomDescText = [[NSUserDefaults standardUserDefaults] objectForKey:kTKAllChatRoomDescTextKey];
        _chatRoomSensitiveEnable = [[NSUserDefaults standardUserDefaults] boolForKey:kTKChatRoomSensitiveEnableKey];
        _chatRoomSensitiveArray = [[NSUserDefaults standardUserDefaults] objectForKey:kTKChatRoomSensitiveArrayKey];
    }
    return self;
}

- (void)setDelaySeconds:(NSInteger)delaySeconds {
    _delaySeconds = delaySeconds;
    
    [[NSUserDefaults standardUserDefaults] setInteger:delaySeconds forKey:kDelaySecondsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReceiveEnable:(BOOL)autoReceiveEnable {
    _autoReceiveEnable = autoReceiveEnable;
    
    [[NSUserDefaults standardUserDefaults] setBool:autoReceiveEnable forKey:kAutoReceiveRedEnvelopKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setReceiveSelfRedEnvelop:(BOOL)receiveSelfRedEnvelop {
    _receiveSelfRedEnvelop = receiveSelfRedEnvelop;
    
    [[NSUserDefaults standardUserDefaults] setBool:receiveSelfRedEnvelop forKey:kReceiveSelfRedEnvelopKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setSerialReceive:(BOOL)serialReceive {
    _serialReceive = serialReceive;
    
    [[NSUserDefaults standardUserDefaults] setBool:serialReceive forKey:kSerialReceiveKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setBlackList:(NSArray *)blackList {
    _blackList = blackList;
    
    [[NSUserDefaults standardUserDefaults] setObject:blackList forKey:kBlackListKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setRevokeEnable:(BOOL)revokeEnable {
    _revokeEnable = revokeEnable;
    
    [[NSUserDefaults standardUserDefaults] setBool:revokeEnable forKey:kRevokeEnablekey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setPreventRevokeEnable:(BOOL)preventRevokeEnable {
    _preventRevokeEnable = preventRevokeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:preventRevokeEnable forKey:KTKPreventRevokeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setChangeStepEnable:(BOOL)changeStepEnable {
    _changeStepEnable = changeStepEnable;
    [[NSUserDefaults standardUserDefaults] setBool:changeStepEnable forKey:KTKChangeStepEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setDeviceStep:(NSInteger)deviceStep {
    _deviceStep = deviceStep;
    [[NSUserDefaults standardUserDefaults] setObject:@(deviceStep) forKey:kTKDeviceStepKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoVerifyEnable:(BOOL)autoVerifyEnable {
    _autoVerifyEnable = autoVerifyEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoVerifyEnable forKey:KTKAutoVerifyEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoVerifyKeyword:(NSString *)autoVerifyKeyword {
    _autoVerifyKeyword = autoVerifyKeyword;
    [[NSUserDefaults standardUserDefaults] setObject:autoVerifyKeyword forKey:kTKAutoVerifyKeywordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoWelcomeEnable:(BOOL)autoWelcomeEnable {
    _autoWelcomeEnable = autoWelcomeEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoWelcomeEnable forKey:KTKAutoWelcomeEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoWelcomeText:(NSString *)autoWelcomeText {
    _autoWelcomeText = autoWelcomeText;
    [[NSUserDefaults standardUserDefaults] setObject:autoWelcomeText forKey:kTKAutoWelcomeTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyEnable:(BOOL)autoReplyEnable {
    _autoReplyEnable = autoReplyEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoReplyEnable forKey:kTKAutoReplyEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyKeyword:(NSString *)autoReplyKeyword {
    _autoReplyKeyword = autoReplyKeyword;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyKeyword forKey:kTKAutoReplyKeywordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyText:(NSString *)autoReplyText {
    _autoReplyText = autoReplyText;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyText forKey:kTKAutoReplyTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyChatRoomEnable:(BOOL)autoReplyChatRoomEnable {
    _autoReplyChatRoomEnable = autoReplyChatRoomEnable;
    [[NSUserDefaults standardUserDefaults] setBool:autoReplyChatRoomEnable forKey:kTKAutoReplyChatRoomEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyChatRoomKeyword:(NSString *)autoReplyChatRoomKeyword {
    _autoReplyChatRoomKeyword = autoReplyChatRoomKeyword;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyChatRoomKeyword forKey:kTKAutoReplyChatRoomKeywordKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAutoReplyChatRoomText:(NSString *)autoReplyChatRoomText {
    _autoReplyChatRoomText = autoReplyChatRoomText;
    [[NSUserDefaults standardUserDefaults] setObject:autoReplyChatRoomText forKey:kTKAutoReplyChatRoomTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setWelcomeJoinChatRoomEnable:(BOOL)welcomeJoinChatRoomEnable {
    _welcomeJoinChatRoomEnable = welcomeJoinChatRoomEnable;
    [[NSUserDefaults standardUserDefaults] setBool:welcomeJoinChatRoomEnable forKey:kTKWelcomeJoinChatRoomEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setWelcomeJoinChatRoomText:(NSString *)welcomeJoinChatRoomText {
    _welcomeJoinChatRoomText = welcomeJoinChatRoomText;
    [[NSUserDefaults standardUserDefaults] setObject:welcomeJoinChatRoomText forKey:kTKWelcomeJoinChatRoomTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setAllChatRoomDescText:(NSString *)allChatRoomDescText {
    _allChatRoomDescText = [allChatRoomDescText copy];
    [[NSUserDefaults standardUserDefaults] setObject:_allChatRoomDescText forKey:kTKAllChatRoomDescTextKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setChatRoomSensitiveEnable:(BOOL)chatRoomSensitiveEnable {
    _chatRoomSensitiveEnable = chatRoomSensitiveEnable;
    [[NSUserDefaults standardUserDefaults] setBool:chatRoomSensitiveEnable forKey:kTKChatRoomSensitiveEnableKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)setChatRoomSensitiveArray:(NSMutableArray *)chatRoomSensitiveArray {
    _chatRoomSensitiveArray = chatRoomSensitiveArray;
    [[NSUserDefaults standardUserDefaults] setObject:chatRoomSensitiveArray forKey:kTKChatRoomSensitiveArrayKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
