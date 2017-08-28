//
//  WBEditViewController.h
//  test
//
//  Created by 刘雨轩 on 2017/8/28.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeChatRedEnvelop.h"

@interface WBEditViewController : UIViewController

@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) NSString *placeholder;
@property (nonatomic, copy) void (^endEditing)(NSString *text);

@end
