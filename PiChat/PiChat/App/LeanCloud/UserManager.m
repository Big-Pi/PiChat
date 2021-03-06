//
//  UserManager.m
//  PiChat
//
//  Created by pi on 16/2/18.
//  Copyright © 2016年 pi. All rights reserved.
//

#import "UserManager.h"
#import <AVOSCloud.h>
#import "CommenUtil.h"
#import "StoryBoardHelper.h"
#import <JSQMessagesAvatarImageFactory.h>
#import <JSQMessagesCollectionViewFlowLayout.h>
#import "PiAutoPurgeCache.h"
#import "NSNotification+UserUpdate.h"
#import "FabricManager.h"
#import "ImageCacheManager.h"


@interface UserManager ()
@property (strong,nonatomic) PiAutoPurgeCache *userCache;
@property (strong,nonatomic) NSMutableSet *fetchingUserIDs;
@end

@implementation UserManager
+(instancetype)sharedUserManager{
    static id userManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userManager=[UserManager new];
    });
    return userManager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(userUpdateNotification:) name:kUserUpdateNotification object:nil];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Getter Setter
-(User*)currentUser{
    return [User currentUser];
}

-(PiAutoPurgeCache*)userCache{
    if(!_userCache){
        _userCache=[PiAutoPurgeCache new];
    }
    return _userCache;
}

-(NSMutableSet *)fetchingUserIDs{
    if(!_fetchingUserIDs){
        _fetchingUserIDs=[NSMutableSet set];
    }
    return _fetchingUserIDs;
}

#pragma mark - Register 
-(void)signUpWithUserName:(NSString *)email pwd:(NSString *)pwd callback:(BooleanResultBlock)callback{
    User *u= [User user];
    u.username=email;
    u.password=pwd;
    u.avatarPath=@"http://7xqpoa.com1.z0.glb.clouddn.com/_doggy.jpg"; //default avatar
    u.fetchWhenSave=YES;
    
    [u signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        [self.userCache setObject:u forKey:u.objectId];
        [FabricManager setUserInfo];
        callback(succeeded,error);
    }];
}

#pragma mark - Login
-(void)logInWithUserName:(NSString*)email pwd:(NSString*)pwd callback:(BooleanResultBlock)callback{
    [User logInWithUsernameInBackground:email password:pwd block:^(AVUser *user, NSError *error) {
        [self.userCache setObject:user forKey:user.objectId];
        [FabricManager setUserInfo];
        callback([User currentUser] !=nil,error); //currentUser not null => login success
    }];
}

+(void)logOut {
    [User logOut];
    [StoryBoardHelper switchToLoginVC];
}

#pragma mark - Friends

-(void)isMyFriend:(User*)user callback:(BooleanResultBlock)callback{
    [self fetchFriendsWithCallback:^(NSArray *friends, NSError *error) {
        __block BOOL isMyFriend=NO;
        [friends enumerateObjectsUsingBlock:^(User *friend, NSUInteger idx, BOOL * _Nonnull stop) {
            if([friend.objectId isEqualToString:user.objectId]){
                isMyFriend=YES;
                *stop=YES;
            }
        }];
        if(callback){
            callback(isMyFriend,nil);
        }
    }];
}

-(void)postAddFriendRequestTo:(User*)userToAdd verifyMessage:(NSString*)verifyMsg callBack:(BooleanResultBlock)callback{
    [[AddFriendRequest requestWithUserToAdd:userToAdd verifyMsg:verifyMsg] saveInBackgroundWithBlock:callback];
}

-(void)findAddFriendRequestAboutUser:(User*)u callback:(ArrayResultBlock)callback{
    AVQuery *q=[AddFriendRequest query];
    q.cachePolicy=kAVCachePolicyNetworkOnly;
    [q whereKey:kToUserKey equalTo:u];
    [q orderByDescending:kUpdatedAt];
    
    [q includeKey:kFromUserKey];
    [q includeKey:kToUserKey];
    [q includeKey:kIsReadKey];
    [q includeKey:kStatusKey];
    [q includeKey:kVerifyMessageKey];
    [q findObjectsInBackgroundWithBlock:callback];
}

- (void)findUsersByPartname:(NSString *)partName withBlock:(AVArrayResultBlock)block {
    AVQuery *q = [User query];
    [q setCachePolicy:kAVCachePolicyNetworkOnly];
    [q whereKey:kUsernameKey containsString:partName];
    [q whereKey:kObjectIdKey notEqualTo:[User currentUser].objectId];
    [q orderByDescending:kUpdatedAt];
    [q findObjectsInBackgroundWithBlock:block];
}

/**
 *  先从缓存中找用户,找不到就下载.立即返回 nil
 *
 *  @param objectID
 *
 *  @return
 */
-(User *)findUserFromCacheElseNetworkByObjectID:(NSString*)objectID{
    User *u= [self findUserFromCacheByObjectID:objectID];
    if(!u){
        [self findUserFromNetworkByObjectID:objectID callback:nil];
    }
    return u;
}

/**
 *  内存缓存
 *
 *  @param clientID
 *
 *  @return
 */
-(User*)findUserFromCacheByObjectID:(NSString*)objectID{
    User *u=[self.userCache objectForKey:objectID];
//    if(u){
//        return u;
//    }else{
//        AVQuery *q=[User query];
//        q.cachePolicy=kAVCachePolicyCacheOnly;
////        [q whereKey:kObjectIdKey equalTo:objectID];
//        NSError *error;
//        u=(User*)[q getObjectWithId:objectID error:&error];
////        u=(User*)[q getFirstObject:&error];
//        if(u){
//            [self.userCache setObject:u forKey:u.objectId];
//        }
//    }
    return u;
}

-(void)findUserByObjectID:(NSString*)objectID callback:(UserResultBlock)callback {
    //先查询内存缓存是否有用户
    User *u= [self findUserFromCacheByObjectID:objectID];
    if(u){
        callback(u,nil);
        return;
    }
    //没有就从网络 fetch 
    [self findUserFromNetworkByObjectID:objectID callback:callback];
}

/**
 *  从网络查询 User
 *
 *  @param clientID
 *  @param callback
 */
-(void)findUserFromNetworkByObjectID:(NSString *)objectID callback:(UserResultBlock)callback{
    if([self.fetchingUserIDs containsObject:objectID]){
        return;
    }
    [self.fetchingUserIDs addObject:objectID];
    AVQuery *q=[User query];
    [q whereKey:kObjectIdKey equalTo:objectID];
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        User *u=[objects firstObject];
        [self.userCache setObject:u forKey:u.objectId];
        [self.fetchingUserIDs removeObject:objectID];
        [NSNotification postUserUpdateNotification:self user:u];
        if(callback){
            callback(u,error);
        }
    }];
}

-(void)addFriend:(User*)user callback:(BooleanResultBlock)callback{
    [[User currentUser]follow:user.objectId andCallback:callback];
}

-(void)removeFriend:(User*)user callback:(BooleanResultBlock)callback{
    [[User currentUser]unfollow:user.objectId andCallback:callback];
}

-(void)fetchFriendsWithCallback:(ArrayResultBlock)callback {
    User *user = [User currentUser];
    if(!user){
        return;
    }
    AVQuery *q = [user followeeQuery];
    q.cachePolicy=kAVCachePolicyCacheThenNetwork;
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        callback(objects ,error);
    }];
}

#pragma mark - Avatar
-(JSQMessagesAvatarImage *)avatarForObjectID:(NSString *)objectID {
    return [self avatarForObjectID:objectID size:CGSizeZero];
}

-(JSQMessagesAvatarImage *)avatarForObjectID:(NSString *)objectID size:(CGSize)size{
    __block UIImage *avatar;
    User *u= [self findUserFromCacheByObjectID:objectID];
    
    if(u.avatarPath){
        if([[ImageCacheManager sharedImageCacheManager]imageExistsForEntity:u withFormatName:kUserAvatarRoundFormatName]){
            [[ImageCacheManager sharedImageCacheManager]syncRetrieveImageForEntity:u withFormatName:kUserAvatarRoundFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
                avatar=image;
            }];
        }else{
            avatar=[UIImage new];
        }
    }else{
        avatar=[UIImage new];
        if(u){
            [[ImageCacheManager sharedImageCacheManager]retrieveImageForEntity:u withFormatName:kUserAvatarBlurFormatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
            }];
        }
    }
    
    return [JSQMessagesAvatarImage avatarWithImage:avatar];
}

#pragma mark - 用户更新完毕,加入到缓存中
-(void)userUpdateNotification:(NSNotification*)noti{
    User *u= noti.user;
    [self.userCache setObject:u forKey:u.objectId];
}
@end
