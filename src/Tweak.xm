#import "WeChatRedEnvelop.h"
#import "WeChatRedEnvelopParam.h"
#import "WBSettingViewController.h"
#import "WBReceiveRedEnvelopOperation.h"
#import "WBRedEnvelopTaskManager.h"
#import "WBRedEnvelopConfig.h"
#import "WBRedEnvelopParamQueue.h"
#import "KeepRunningManager.h"

%hook MicroMessengerAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  		
  	//CContactMgr *contactMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(CContactMgr)];
	//CContact *contact = [contactMgr getContactForSearchByName:@"gh_6e8bddcdfca3"];
	//[contactMgr addLocalContact:contact listType:2];
	//[contactMgr getContactsFromServer:@[contact]];
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"WeChatTweakAutoRedEnvelopesKeepRunningKey"] == nil) {
		[[NSUserDefaults standardUserDefaults] setBool:true forKey:@"WeChatTweakAutoRedEnvelopesKeepRunningKey"];
	}
	if([[NSUserDefaults standardUserDefaults] objectForKey:@"WBRevokeEnable"] == nil) {
		[[NSUserDefaults standardUserDefaults] setBool:true forKey:@"WBRevokeEnable"];
	}
	return %orig;
}

- (void)applicationWillResignActive:(id)arg1 {
    %orig;
    BOOL isAutoRedEnvelopesKeepRunning = [[NSUserDefaults standardUserDefaults] boolForKey:@"WeChatTweakAutoRedEnvelopesKeepRunningKey"];
    if (isAutoRedEnvelopesKeepRunning) {
        [[%c(KeepRunningManager) sharedInstance] startKeepRunning];
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    }
}

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    if ([KeepRunningManager sharedInstance].playing) {
        [[%c(KeepRunningManager) sharedInstance] stopKeepRunning];
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    }
}

%end

%hook WCRedEnvelopesLogicMgr

- (void)OnWCToHongbaoCommonResponse:(HongBaoRes *)arg1 Request:(HongBaoReq *)arg2 {

	%orig;

	// 非参数查询请求
	if (arg1.cgiCmdid != 3) { return; }

	NSString *(^parseRequestSign)() = ^NSString *() {
		NSString *requestString = [[NSString alloc] initWithData:arg2.reqText.buffer encoding:NSUTF8StringEncoding];
		NSDictionary *requestDictionary = [%c(WCBizUtil) dictionaryWithDecodedComponets:requestString separator:@"&"];
		NSString *nativeUrl = [[requestDictionary stringForKey:@"nativeUrl"] stringByRemovingPercentEncoding];
		NSDictionary *nativeUrlDict = [%c(WCBizUtil) dictionaryWithDecodedComponets:nativeUrl separator:@"&"];

		return [nativeUrlDict stringForKey:@"sign"];
	};

	NSDictionary *responseDict = [[[NSString alloc] initWithData:arg1.retText.buffer encoding:NSUTF8StringEncoding] JSONDictionary];

	WeChatRedEnvelopParam *mgrParams = [[WBRedEnvelopParamQueue sharedQueue] dequeue];

	BOOL (^shouldReceiveRedEnvelop)() = ^BOOL() {

		// 手动抢红包
		if (!mgrParams) { return NO; }

		// 自己已经抢过
		if ([responseDict[@"receiveStatus"] integerValue] == 2) { return NO; }

		// 红包被抢完
		if ([responseDict[@"hbStatus"] integerValue] == 4) { return NO; }		

		// 没有这个字段会被判定为使用外挂
		if (!responseDict[@"timingIdentifier"]) { return NO; }		

		if (mgrParams.isGroupSender) { // 自己发红包的时候没有 sign 字段
			return [WBRedEnvelopConfig sharedConfig].autoReceiveEnable;
		} else {
			return [parseRequestSign() isEqualToString:mgrParams.sign] && [WBRedEnvelopConfig sharedConfig].autoReceiveEnable;
		}
	};

	if (shouldReceiveRedEnvelop()) {
		mgrParams.timingIdentifier = responseDict[@"timingIdentifier"];

		unsigned int delaySeconds = [self calculateDelaySeconds];
		WBReceiveRedEnvelopOperation *operation = [[WBReceiveRedEnvelopOperation alloc] initWithRedEnvelopParam:mgrParams delay:delaySeconds];

		if ([WBRedEnvelopConfig sharedConfig].serialReceive) {
			[[WBRedEnvelopTaskManager sharedManager] addSerialTask:operation];
		} else {
			[[WBRedEnvelopTaskManager sharedManager] addNormalTask:operation];
		}
	}
}

%new
- (unsigned int)calculateDelaySeconds {
	NSInteger configDelaySeconds = [WBRedEnvelopConfig sharedConfig].delaySeconds;

	if ([WBRedEnvelopConfig sharedConfig].serialReceive) {
		unsigned int serialDelaySeconds;
		if ([WBRedEnvelopTaskManager sharedManager].serialQueueIsEmpty) {
			serialDelaySeconds = configDelaySeconds;
		} else {
			serialDelaySeconds = 15;
		}

		return serialDelaySeconds;
	} else {
		return (unsigned int)configDelaySeconds;
	}
}

%end

%hook CMessageMgr
- (void)MessageReturn:(unsigned int)arg1 MessageInfo:(NSDictionary *)info Event:(unsigned int)arg3 {
    %orig;
    CMessageWrap *wrap = [info objectForKey:@"18"];
    
    if (arg1 == 227) {
        NSDate *now = [NSDate date];
        NSTimeInterval nowSecond = now.timeIntervalSince1970;
        if (nowSecond - wrap.m_uiCreateTime > 60) {      // 若是1分钟前的消息，则不进行处理。
            return;
        }
        if(wrap.m_uiMessageType == 1) {                                         // 收到文本消息
            CContactMgr *contactMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CContactMgr")];
            CContact *contact = [contactMgr getContactByName:wrap.m_nsFromUsr];
            if (![contact isChatroom]) {                                        // 是否为群聊
                [self autoReplyWithMessageWrap:wrap];                           // 自动回复个人消息
            } else {
                [self removeMemberWithMessageWrap:wrap];                        // 自动踢人
                [self autoReplyChatRoomWithMessageWrap:wrap];                   // 自动回复群消息
            }
        } else if(wrap.m_uiMessageType == 10000) {                              // 收到群通知，eg:群邀请了好友；删除了好友。
            [self welcomeJoinChatRoomWithMessageWrap:wrap];
        }
    }
    
    if (arg1 == 332) {                                                          // 收到添加好友消息
        [self addAutoVerifyWithMessageInfo:info];
    }
}

- (id)GetHelloUsers:(id)arg1 Limit:(unsigned int)arg2 OnlyUnread:(_Bool)arg3 {
    id userNameArray = %orig;
    if ([arg1 isEqualToString:@"fmessage"] && arg2 == 0 && arg3 == 0) {
        [self addAutoVerifyWithArray:userNameArray arrayType:WBArrayTpyeMsgUserName];
    }
    
    return userNameArray;
}

- (void)AsyncOnAddMsg:(NSString *)msg MsgWrap:(CMessageWrap *)wrap {
	%orig;
	
	switch(wrap.m_uiMessageType) {
	case 49: { // AppNode

		/** 是否为红包消息 */
		BOOL (^isRedEnvelopMessage)() = ^BOOL() {
			return [wrap.m_nsContent rangeOfString:@"wxpay://"].location != NSNotFound;
		};
		
		if (isRedEnvelopMessage()) { // 红包
			CContactMgr *contactManager = [[%c(MMServiceCenter) defaultCenter] getService:[%c(CContactMgr) class]];
			CContact *selfContact = [contactManager getSelfContact];

			BOOL (^isSender)() = ^BOOL() {
				return [wrap.m_nsFromUsr isEqualToString:selfContact.m_nsUsrName];
			};

			/** 是否别人在群聊中发消息 */
			BOOL (^isGroupReceiver)() = ^BOOL() {
				return [wrap.m_nsFromUsr rangeOfString:@"@chatroom"].location != NSNotFound;
			};

			/** 是否自己在群聊中发消息 */
			BOOL (^isGroupSender)() = ^BOOL() {
				return isSender() && [wrap.m_nsToUsr rangeOfString:@"chatroom"].location != NSNotFound;
			};

			/** 是否抢自己发的红包 */
			BOOL (^isReceiveSelfRedEnvelop)() = ^BOOL() {
				return [WBRedEnvelopConfig sharedConfig].receiveSelfRedEnvelop;
			};

			/** 是否在黑名单中 */
			BOOL (^isGroupInBlackList)() = ^BOOL() {
				return [[WBRedEnvelopConfig sharedConfig].blackList containsObject:wrap.m_nsFromUsr];
			};

			/** 是否自动抢红包 */
			BOOL (^shouldReceiveRedEnvelop)() = ^BOOL() {
				if (![WBRedEnvelopConfig sharedConfig].autoReceiveEnable) { return NO; }
				if (isGroupInBlackList()) { return NO; }

				return isGroupReceiver() || (isGroupSender() && isReceiveSelfRedEnvelop());
			};

			NSDictionary *(^parseNativeUrl)(NSString *nativeUrl) = ^(NSString *nativeUrl) {
				nativeUrl = [nativeUrl substringFromIndex:[@"wxpay://c2cbizmessagehandler/hongbao/receivehongbao?" length]];
				return [%c(WCBizUtil) dictionaryWithDecodedComponets:nativeUrl separator:@"&"];
			};

			/** 获取服务端验证参数 */
			void (^queryRedEnvelopesReqeust)(NSDictionary *nativeUrlDict) = ^(NSDictionary *nativeUrlDict) {
				NSMutableDictionary *params = [@{} mutableCopy];
				params[@"agreeDuty"] = @"0";
				params[@"channelId"] = [nativeUrlDict stringForKey:@"channelid"];
				params[@"inWay"] = @"0";
				params[@"msgType"] = [nativeUrlDict stringForKey:@"msgtype"];
				params[@"nativeUrl"] = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];
				params[@"sendId"] = [nativeUrlDict stringForKey:@"sendid"];

				WCRedEnvelopesLogicMgr *logicMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:[objc_getClass("WCRedEnvelopesLogicMgr") class]];
				[logicMgr ReceiverQueryRedEnvelopesRequest:params];
			};

			/** 储存参数 */
			void (^enqueueParam)(NSDictionary *nativeUrlDict) = ^(NSDictionary *nativeUrlDict) {
					WeChatRedEnvelopParam *mgrParams = [[WeChatRedEnvelopParam alloc] init];
					mgrParams.msgType = [nativeUrlDict stringForKey:@"msgtype"];
					mgrParams.sendId = [nativeUrlDict stringForKey:@"sendid"];
					mgrParams.channelId = [nativeUrlDict stringForKey:@"channelid"];
					mgrParams.nickName = [selfContact getContactDisplayName];
					mgrParams.headImg = [selfContact m_nsHeadImgUrl];
					mgrParams.nativeUrl = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];
					mgrParams.sessionUserName = isGroupSender() ? wrap.m_nsToUsr : wrap.m_nsFromUsr;
					mgrParams.sign = [nativeUrlDict stringForKey:@"sign"];

					mgrParams.isGroupSender = isGroupSender();

					[[WBRedEnvelopParamQueue sharedQueue] enqueue:mgrParams];
			};

			if (shouldReceiveRedEnvelop()) {
				NSString *nativeUrl = [[wrap m_oWCPayInfoItem] m_c2cNativeUrl];			
				NSDictionary *nativeUrlDict = parseNativeUrl(nativeUrl);

				queryRedEnvelopesReqeust(nativeUrlDict);
				enqueueParam(nativeUrlDict);
			}
		}	
		break;
	}
	default:
		break;
	}
	
}

- (void)onRevokeMsg:(CMessageWrap *)arg1 {

	if (![WBRedEnvelopConfig sharedConfig].revokeEnable) {
		%orig;
	} else {
		if ([arg1.m_nsContent rangeOfString:@"<session>"].location == NSNotFound) { return; }
		if ([arg1.m_nsContent rangeOfString:@"<replacemsg>"].location == NSNotFound) { return; }

		NSString *(^parseSession)() = ^NSString *() {
			NSUInteger startIndex = [arg1.m_nsContent rangeOfString:@"<session>"].location + @"<session>".length;
			NSUInteger endIndex = [arg1.m_nsContent rangeOfString:@"</session>"].location;
			NSRange range = NSMakeRange(startIndex, endIndex - startIndex);
			return [arg1.m_nsContent substringWithRange:range];
		};

		NSString *(^parseSenderName)() = ^NSString *() {
		    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<!\\[CDATA\\[(.*?)撤回了一条消息\\]\\]>" options:NSRegularExpressionCaseInsensitive error:nil];

		    NSRange range = NSMakeRange(0, arg1.m_nsContent.length);
		    NSTextCheckingResult *result = [regex matchesInString:arg1.m_nsContent options:0 range:range].firstObject;
		    if (result.numberOfRanges < 2) { return nil; }

		    return [arg1.m_nsContent substringWithRange:[result rangeAtIndex:1]];
		};

		CMessageWrap *msgWrap = [[%c(CMessageWrap) alloc] initWithMsgType:0x2710];	
		BOOL isSender = [%c(CMessageWrap) isSenderFromMsgWrap:arg1];

		NSString *sendContent;
		if (isSender) {
			[msgWrap setM_nsFromUsr:arg1.m_nsToUsr];
			[msgWrap setM_nsToUsr:arg1.m_nsFromUsr];
			sendContent = @"你撤回一条消息";
		} else {
			[msgWrap setM_nsToUsr:arg1.m_nsToUsr];
			[msgWrap setM_nsFromUsr:arg1.m_nsFromUsr];

			NSString *name = parseSenderName();
			sendContent = [NSString stringWithFormat:@"拦截 %@ 的一条撤回消息", name ? name : arg1.m_nsFromUsr];
		}
		[msgWrap setM_uiStatus:0x4];
		[msgWrap setM_nsContent:sendContent];
		[msgWrap setM_uiCreateTime:[arg1 m_uiCreateTime]];

		[self AddLocalMsg:parseSession() MsgWrap:msgWrap fixTime:0x1 NewMsgArriveNotify:0x0];
	}
}

%new
- (void)autoReplyWithMessageWrap:(CMessageWrap *)wrap {
    BOOL autoReplyEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyEnable];
    if (!autoReplyEnable) {                                                     // 是否开启自动回复
        return;
    }
    
    NSString * content = MSHookIvar<id>(wrap, "m_nsLastDisplayContent");
    NSString *needAutoReplyMsg = [[WBRedEnvelopConfig sharedConfig] autoReplyKeyword];
    if([content isEqualToString:needAutoReplyMsg]) {
        NSString *autoReplyContent = [[WBRedEnvelopConfig sharedConfig] autoReplyText];
        [self sendMsg:autoReplyContent toContactUsrName:wrap.m_nsFromUsr];
    }
}

%new
- (void)removeMemberWithMessageWrap:(CMessageWrap *)wrap {
    BOOL chatRoomSensitiveEnable = [[WBRedEnvelopConfig sharedConfig] chatRoomSensitiveEnable];
    if (!chatRoomSensitiveEnable) {
        return;
    }
    
    CGroupMgr *groupMgr = [[objc_getClass("MMServiceCenter") defaultCenter] getService:objc_getClass("CGroupMgr")];
    NSString *content = MSHookIvar<id>(wrap, "m_nsLastDisplayContent");
    NSMutableArray *array = [[WBRedEnvelopConfig sharedConfig] chatRoomSensitiveArray];
    [array enumerateObjectsUsingBlock:^(NSString *text, NSUInteger idx, BOOL * _Nonnull stop) {
        if([content isEqualToString:text]) {
            [groupMgr DeleteGroupMember:wrap.m_nsFromUsr withMemberList:@[wrap.m_nsRealChatUsr] scene:3074516140857229312];
        }
    }];
}

%new
- (void)autoReplyChatRoomWithMessageWrap:(CMessageWrap *)wrap {
    BOOL autoReplyChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomEnable];
    if (!autoReplyChatRoomEnable) {                                                     // 是否开启自动回复
        return;
    }
    
    NSString * content = MSHookIvar<id>(wrap, "m_nsLastDisplayContent");
    NSString *needAutoReplyChatRoomMsg = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomKeyword];
    if([content isEqualToString:needAutoReplyChatRoomMsg]) {
        NSString *autoReplyChatRoomContent = [[WBRedEnvelopConfig sharedConfig] autoReplyChatRoomText];
        [self sendMsg:autoReplyChatRoomContent toContactUsrName:wrap.m_nsFromUsr];
    }
}

%new
- (void)welcomeJoinChatRoomWithMessageWrap:(CMessageWrap *)wrap {
    BOOL welcomeJoinChatRoomEnable = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomEnable];
    if (!welcomeJoinChatRoomEnable)                                             // 是否开启入群欢迎语
        return;
    
    NSString * content = MSHookIvar<id>(wrap, "m_nsLastDisplayContent");
    NSRange rangeFrom = [content rangeOfString:@"邀请\""];
    NSRange rangeTo = [content rangeOfString:@"\"加入了群聊"];
    NSRange nameRange;
    if (rangeFrom.length > 0 && rangeTo.length > 0) {                           // 通过别人邀请进群
        NSInteger nameLocation = rangeFrom.location + rangeFrom.length;
        nameRange = NSMakeRange(nameLocation, rangeTo.location - nameLocation);
    } else {
        NSRange range = [content rangeOfString:@"\"通过扫描\""];
        if (range.length > 0) {                                                 // 通过二维码扫描进群
            nameRange = NSMakeRange(2, range.location - 2);
        } else {
            return;
        }
    }
    
    NSString *welcomeJoinChatRoomText = [[WBRedEnvelopConfig sharedConfig] welcomeJoinChatRoomText];
    [self sendMsg:welcomeJoinChatRoomText toContactUsrName:wrap.m_nsFromUsr];
}

%new
- (void)addAutoVerifyWithMessageInfo:(NSDictionary *)info {
    BOOL autoVerifyEnable = [[WBRedEnvelopConfig sharedConfig] autoVerifyEnable];
    
    if (!autoVerifyEnable)
        return;
    
    NSString *keyStr = [info objectForKey:@"5"];
    if ([keyStr isEqualToString:@"fmessage"]) {
        NSArray *wrapArray = [info objectForKey:@"27"];
        [self addAutoVerifyWithArray:wrapArray arrayType:WBArrayTpyeMsgWrap];
    }
}

%new        // 自动通过好友请求
- (void)addAutoVerifyWithArray:(NSArray *)ary arrayType:(WBArrayTpye)type {
    NSMutableArray *arrHellos = [NSMutableArray array];
    [ary enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (type == WBArrayTpyeMsgWrap) {
            CPushContact *contact = [%c(SayHelloDataLogic) getContactFrom:obj];
            [arrHellos addObject:contact];
        } else if (type == WBArrayTpyeMsgUserName) {
            FriendAsistSessionMgr *asistSessionMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(FriendAsistSessionMgr)];
            CMessageWrap *wrap = [asistSessionMgr GetLastMessage:@"fmessage" HelloUser:obj OnlyTo:NO];
            CPushContact *contact = [%c(SayHelloDataLogic) getContactFrom:wrap];
            [arrHellos addObject:contact];
        }
    }];
    
    NSString *autoVerifyKeyword = [[WBRedEnvelopConfig sharedConfig] autoVerifyKeyword];
    for (int idx = 0;idx < arrHellos.count;idx++) {
        CPushContact *contact = arrHellos[idx];
        if (![contact isMyContact] && [contact.m_nsDes isEqualToString:autoVerifyKeyword]) {
            CContactVerifyLogic *verifyLogic = [[%c(CContactVerifyLogic) alloc] init];
            CVerifyContactWrap *wrap = [[%c(CVerifyContactWrap) alloc] init];
            [wrap setM_nsUsrName:contact.m_nsEncodeUserName];
            [wrap setM_uiScene:contact.m_uiFriendScene];
            [wrap setM_nsTicket:contact.m_nsTicket];
            [wrap setM_nsChatRoomUserName:contact.m_nsChatRoomUserName];
            wrap.m_oVerifyContact = contact;
            
            AutoSetRemarkMgr *mgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(AutoSetRemarkMgr)];
            id attr = [mgr GetStrangerAttribute:contact AttributeName:1001];
            
            if([attr boolValue]) {
                [wrap setM_uiWCFlag:(wrap.m_uiWCFlag | 1)];
            }
            [verifyLogic startWithVerifyContactWrap:[NSArray arrayWithObject:wrap] opCode:3 parentView:[UIView new] fromChatRoom:NO];
            
            // 发送欢迎语
            BOOL autoWelcomeEnable = [[WBRedEnvelopConfig sharedConfig] autoWelcomeEnable];
            NSString *autoWelcomeText = [[WBRedEnvelopConfig sharedConfig] autoWelcomeText];
            if (autoWelcomeEnable && autoWelcomeText != nil) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self sendMsg:autoWelcomeText toContactUsrName:contact.m_nsUsrName];
                });
            }
        }
    }
}

%new        // 发送消息
- (void)sendMsg:(NSString *)msg toContactUsrName:(NSString *)userName {
    CMessageWrap *wrap = [[%c(CMessageWrap) alloc] initWithMsgType:1];
    id usrName = [%c(SettingUtil) getLocalUsrName:0];
    [wrap setM_nsFromUsr:usrName];
    [wrap setM_nsContent:msg];
    [wrap setM_nsToUsr:userName];
    MMNewSessionMgr *sessionMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(MMNewSessionMgr)];
    [wrap setM_uiCreateTime:[sessionMgr GenSendMsgTime]];
    [wrap setM_uiStatus:YES];
    
    CMessageMgr *chatMgr = [[%c(MMServiceCenter) defaultCenter] getService:%c(CMessageMgr)];
    [chatMgr AddMsg:userName MsgWrap:wrap];
}

%end

%hook NewSettingViewController

- (void)reloadTableData {
	%orig;

	MMTableViewInfo *tableViewInfo = MSHookIvar<id>(self, "m_tableViewInfo");

	MMTableViewSectionInfo *sectionInfo = [%c(MMTableViewSectionInfo) sectionInfoDefaut];

	MMTableViewCellInfo *settingCell = [%c(MMTableViewCellInfo) normalCellForSel:@selector(setting) target:self title:@"微信小助手" accessoryType:1];
	[sectionInfo addCell:settingCell];

	[tableViewInfo insertSection:sectionInfo At:0];

	MMTableView *tableView = [tableViewInfo getTableView];
	[tableView reloadData];
}

%new
- (void)setting {
	WBSettingViewController *settingViewController = [WBSettingViewController new];
	[self.navigationController PushViewController:settingViewController animated:YES];
}

%end

// %hook MicroMessengerAppDelegate
// - (_Bool)application:(id)arg1 didFinishLaunchingWithOptions:(id)arg2 {
//     BOOL finish = %orig;
//
//     static dispatch_once_t onceToken;
//     dispatch_once(&onceToken, ^{
//         Method originalBundleIdentifierMethod = class_getInstanceMethod([NSBundle class], @selector(bundleIdentifier));
//         Method swizzledBundleIdentifierMethod = class_getInstanceMethod([NSBundle class], @selector(tk_bundleIdentifier));
//         if(originalBundleIdentifierMethod && swizzledBundleIdentifierMethod) {
//             method_exchangeImplementations(originalBundleIdentifierMethod, swizzledBundleIdentifierMethod);
//         }
//
//         Method originalInfoDictionaryMethod = class_getInstanceMethod([NSBundle class], @selector(infoDictionary));
//         Method swizzledInfoDictionaryMethod = class_getInstanceMethod([NSBundle class], @selector(tk_infoDictionary));
//         if(originalInfoDictionaryMethod && swizzledInfoDictionaryMethod) {
//             method_exchangeImplementations(originalInfoDictionaryMethod, swizzledInfoDictionaryMethod);
//         }
//
//     });
//     return finish;
// }
// %end
