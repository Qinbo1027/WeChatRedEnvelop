//
//  WBToast.h
//  test
//
//  Created by 刘雨轩 on 2017/8/28.
//  Copyright © 2017年 tencent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WBToast : NSObject

+ (void)toast:(NSString *)msg;
+ (void)toast:(NSString *)msg delay:(NSTimeInterval)duration;

@end
