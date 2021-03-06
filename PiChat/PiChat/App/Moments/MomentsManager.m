//
//  MomentsManager.m
//  PiChat
//
//  Created by pi on 16/3/21.
//  Copyright © 2016年 pi. All rights reserved.
//

#import "MomentsManager.h"
#import "Moment.h"
#import <AVOSCloud.h>
#import "User.h"
#import "UserManager.h"
#import "UIImage+Resizing.h"

@interface MomentsManager ()
@property (strong,nonatomic) NSMutableArray *momentImageFile;
@property (strong,nonatomic) NSOperationQueue *uploadImageFileQueue;
@end

@implementation MomentsManager

-(NSMutableArray *)momentImageFile{
    if(!_momentImageFile){
        _momentImageFile=[NSMutableArray array];
    }
    return _momentImageFile;
}

-(NSOperationQueue *)uploadImageFileQueue{
    if(!_uploadImageFileQueue){
        _uploadImageFileQueue=[[NSOperationQueue alloc]init];
    }
    return _uploadImageFileQueue;
}
#pragma mark -

-(void)postMomentWithContent:(NSString*)content images:(NSArray*)images{
    NSAssert(content!=nil, @"发送朋友圈内容不能为空");
    NSAssert(content.length>0, @"发送朋友圈内容不能为空");
    
    [self.momentImageFile removeAllObjects];
    [self.uploadImageFileQueue cancelAllOperations];
    
    //纯文字朋友圈
    if(!images || images.count == 0){
        Moment *m= [self newMoment:content images:nil];
        [m saveOrUpdateInBackground:^(BOOL succeeded, NSError *error) {
            if(error){
                [NSNotification postPostMomentFailedNotification:self error:error];
            }else{
                [NSNotification postPostMomentCompleteNotification:self moment:m];
            }
        }];
        return;
    }
    
    //有图片的朋友圈,先上传图片
    NSInteger uploadImageCount=images.count;
    CGSize screenSize=CGSizeApplyAffineTransform([UIScreen mainScreen].nativeBounds.size, CGAffineTransformMakeScale(0.5, 0.5)); //屏幕像素的一半
    
    [images enumerateObjectsUsingBlock:^(NSURL *imgUrl, NSUInteger idx, BOOL * _Nonnull stop) {
        
        [self.uploadImageFileQueue addOperationWithBlock:^{
            
            UIImage *image= [UIImage imageWithData:[NSData dataWithContentsOfURL:imgUrl]];
            //图片太大就缩放一下... 屏幕像素的一半
            if(image.size.width > screenSize.width || image.size.height > screenSize.height){
                image=[image scaleToFitSize:screenSize];
            }
            AVFile *imageFile=[AVFile fileWithData:UIImagePNGRepresentation(image)];
            
            [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(error){
                    [NSNotification postPostMomentFailedNotification:self error:error];
                    [self.uploadImageFileQueue cancelAllOperations];
                    return ;
                }
                [self.momentImageFile addObject:imageFile];
                //全部上传完毕
                if(self.momentImageFile.count==uploadImageCount){
                    Moment *m= [self newMoment:content images:self.momentImageFile];
                    [m saveOrUpdateInBackground:^(BOOL succeeded, NSError *error) {
                        [NSNotification postPostMomentCompleteNotification:self moment:m];
                    }];
                }
            } progressBlock:^(NSInteger percentDone) {
                [NSNotification postPostMomentProgressNotification:self progress:percentDone];
            }];
            
        }];
        
    }];
    
}

/**
 *  为某个朋友圈发送新评论
 */
+(void)postNewCommentForMoment:(Moment*)m commentContent:(NSString*)reply replyTo:(User*)replyTo{
    
    executeAsyncInGlobalQueue(^{
        Comment *newComment= [Comment commentWithCommentUser:[User currentUser] commentContent:reply replayTo:replyTo];
        [newComment saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            [m addNewComment:newComment];
            [m saveOrUpdateInBackground:^(BOOL succeeded, NSError *error) {
                
            }];
        }];
    });
}


-(Moment*)newMoment:(NSString*)content images:(NSArray*)images{
    Moment *m=[Moment object];
    [m addUniqueObjectsFromArray:images forKey:kPostImages];
    if(images){
        m.images =self.momentImageFile;
    }
    m.texts=content;
    m.postUser=[User currentUser];
    return m;
}

+(void)getCurrentUserMoments:(ArrayResultBlock)callback{
    [[UserManager sharedUserManager]fetchFriendsWithCallback:^(NSArray *friends, NSError *error) {
        if(!friends){
            return ;
        }
        //查找我发送的或者我的好友发送的朋友圈
        AVQuery *myMomentQuery= [AVQuery queryWithClassName:NSStringFromClass([Moment class])];
        [myMomentQuery whereKey:kPostUser equalTo:[User currentUser]];
        
        AVQuery *friendsMomentQuery= [AVQuery queryWithClassName:NSStringFromClass([Moment class])];
        [friendsMomentQuery whereKey:kPostUser containedIn:friends];
        
        AVQuery *query=[AVQuery orQueryWithSubqueries:@[myMomentQuery,friendsMomentQuery]];
        [query orderByDescending:kCreatedAt];
        [query includeKey:kPostImages];
        [query includeKey:kFavourUsers];
        [query includeKey:kComments];
        [query includeKey:kPostUser];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
//            [objects enumerateObjectsUsingBlock:^(Moment *m, NSUInteger idx, BOOL * _Nonnull stop) {
//                [AVObject fetchAll:m.favourUsers];
//                [AVObject fetchAll:m.comments];
//                [m.postUser fetch];
//            }];
            //上面再请求一次 moment 的favourUsers,comments 数据的操作效率很低,但 Leancloud 只支持一层的请求数据 ,
//            https://forum.leancloud.cn/t/app-leancloud/1888
            //现在这个问题解决了,Leancloud 支持了 666 ,感人 :)
            callback(objects,error);
        }];
    }];
}

+(void)getMomentWithID:(NSString*)momentID callback:(MomentResultBlock)callback{
    AVQuery *momentQuery= [AVQuery queryWithClassName:NSStringFromClass([Moment class])];
    [momentQuery whereKey:kObjectIdKey equalTo:momentID];
    [momentQuery includeKey:kPostImages];
    [momentQuery includeKey:kFavourUsers];
    [momentQuery includeKey:kComments];
    [momentQuery getFirstObjectInBackgroundWithBlock:^(AVObject *object, NSError *error) {
        callback((Moment*)object,error);
    }];
}
@end
