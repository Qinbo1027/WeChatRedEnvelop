//
//  WBRedEnvelopConfig.h
//  WeChatRedEnvelop
//
//  Created by 杨志超 on 2017/2/22.
//  Copyright © 2017年 swiftyper. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CContact;
@interface WBRedEnvelopConfig : NSObject

+ (instancetype)sharedConfig;

@property (assign, nonatomic) BOOL autoReceiveEnable;
@property (assign, nonatomic) NSInteger delaySeconds;

/** Pro */
@property (assign, nonatomic) BOOL receiveSelfRedEnvelop;
@property (assign, nonatomic) BOOL serialReceive;
@property (strong, nonatomic) NSArray *blackList;
@property (assign, nonatomic) BOOL revokeEnable;

/**  微信撤回 */
@property (nonatomic, assign) BOOL preventRevokeEnable;

/**  步数设置 */
@property (nonatomic, assign) BOOL changeStepEnable;
@property (nonatomic, assign) NSInteger deviceStep;            /**<    步数设置  */

/**  自动确认好友请求 */
@property (nonatomic, assign) BOOL autoVerifyEnable;
@property (nonatomic, copy) NSString *autoVerifyKeyword;            /**<    自动验证关键字  */

/**  确认好友请求以后，自动发送欢迎语 */
@property (nonatomic, assign) BOOL autoWelcomeEnable;
@property (nonatomic, copy) NSString *autoWelcomeText;                   /**<    好友通过欢迎语  */

/**  特定消息自动回复 */
@property (nonatomic, assign) BOOL autoReplyEnable;
@property (nonatomic, copy) NSString *autoReplyKeyword;             /**<    自动回复关键字  */
@property (nonatomic, copy) NSString *autoReplyText;                /**<    自动回复的内容  */

/**  群特定消息自动回复 */
@property (nonatomic, assign) BOOL autoReplyChatRoomEnable;
@property (nonatomic, copy) NSString *autoReplyChatRoomKeyword;     /**<    群自动回复关键字  */
@property (nonatomic, copy) NSString *autoReplyChatRoomText;        /**<    群自动回复的内容  */

/**  入群欢迎语 */
@property (nonatomic, assign) BOOL welcomeJoinChatRoomEnable;
@property (nonatomic, copy) NSString *welcomeJoinChatRoomText;      /**<    入群欢迎语     */

/**  设置群公告 */
@property (nonatomic, copy) NSString *allChatRoomDescText;          /**<    所有的群公告    */

/**  设置敏感词 */
@property (nonatomic, assign) BOOL chatRoomSensitiveEnable;
@property (nonatomic, strong) NSMutableArray *chatRoomSensitiveArray;        /**<    群聊敏感词    */

@end
