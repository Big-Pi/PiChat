//
//  AddFriendRequest.h
//  PiChat
//
//  Created by pi on 16/5/11.
//  Copyright © 2016年 pi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVOSCloud.h>
#import "User.h"

//等待验证,接受,拒绝
typedef enum : NSUInteger {
    AddFriendRequestStatusWait,
    AddFriendRequestStatusAccept,
    AddFriendRequestStatusDeny
} AddFriendRequestStatus;

FOUNDATION_EXPORT NSString *const kFromUserKey;
FOUNDATION_EXPORT NSString *const kToUserKey;
FOUNDATION_EXPORT NSString *const kIsReadKey;
FOUNDATION_EXPORT NSString *const kStatusKey;
FOUNDATION_EXPORT NSString *const kVerifyMessageKey;

@interface AddFriendRequest : AVObject<AVSubclassing>
@property (strong,nonatomic) User *fromUser;
@property (strong,nonatomic) User *toUser;
@property (assign,nonatomic) BOOL isRead; //没读过就显示红点, bedge
@property (copy,nonatomic) NSString *verifyMessage; //验证消息, 我是你的 XXX

@property (assign,nonatomic) AddFriendRequestStatus status;

+(instancetype)requestWithUserToAdd:(User*)userToAdd;

/**
 *  创建对某人的添加好友请求
 *
 *  @param userToAdd
 *  @param verifyMsg
 *
 *  @return 
 */
+(instancetype)requestWithUserToAdd:(User*)userToAdd verifyMsg:(NSString*)verifyMsg;
@end
