//
//  AVIMTypedMessage+ToJsqMessage.m
//  PiChat
//
//  Created by pi on 16/2/20.
//  Copyright © 2016年 pi. All rights reserved.
//

#import "AVIMTypedMessage+ToJsqMessage.h"
#import <JSQMessages.h>
#import <AVOSCloud.h>
#import "UserManager.h"
#import <AVOSCloudIM.h>
#import "JSQAudioMediaItem.h"
#import "JSQMessage+MessageID.h"
#import "CommenUtil.h"
#import "JSQVideoMediaItem+Thumbnail.h"


@implementation AVIMTypedMessage (ToJsqMessage)

/**
 *  接收到的Media Message 转为 JSQMessage 显示
 *  同步方法,保证消息的顺序不乱
 *
 *  @param callback 
 */
-(void)toJsqMessageWithCallback:(JsqMsgBlock)callback{
    
    AVIMMessageMediaType msgType = self.mediaType;
    JSQMessage *message;
    NSDate* timestamp=[NSDate dateWithTimeIntervalSince1970:self.sendTimestamp/1000];
    NSString *senderId=self.clientId;
    NSString *senderDisplayName=self.clientId;
    
    BOOL outgoing=[[UserManager sharedUserManager].currentUser.clientID isEqualToString:self.clientId];
    switch (msgType) {
        case kAVIMMessageMediaTypeText: {
            AVIMTextMessage *receiveTextMessage = (AVIMTextMessage *)self;
            message=[[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp text:receiveTextMessage.text];
            
            break;
        }
        case kAVIMMessageMediaTypeImage: {
            AVIMImageMessage *imageMessage = (AVIMImageMessage *)self;
            NSError *error;
            NSData *data=[imageMessage.file getData:&error];
            UIImage *image=[UIImage imageWithData:data];
            JSQPhotoMediaItem *photoItem=[[JSQPhotoMediaItem alloc] initWithImage:image];
            photoItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message=[[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:photoItem];
            break;
        }
        case kAVIMMessageMediaTypeVideo:{
            AVIMVideoMessage* videoMessage=(AVIMVideoMessage*)self;
            NSString *videoFormat=videoMessage.attributes[kVideoFormat];
            NSString *cachePath= [self fileCacheUrlForFileName:[NSString stringWithFormat:@"%@.%@",self.messageId,videoFormat]];
            if(![[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
                [self fetchDataOfMessageFile:videoMessage.file toDirctory:cachePath error:nil];
            }
            
            NSURL *videoURL = [NSURL fileURLWithPath:cachePath];
            JSQVideoMediaItem *videoItem = [[JSQVideoMediaItem alloc] initWithFileURL:videoURL isReadyToPlay:YES];
            videoItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message = [[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:videoItem];
            break;
        }
        case kAVIMMessageMediaTypeLocation:{
            AVIMLocationMessage *locationMessage=(AVIMLocationMessage*)self;
            CLLocation *location = [[CLLocation alloc] initWithLatitude:locationMessage.location.latitude longitude:locationMessage.location.longitude];
            JSQLocationMediaItem *locationItem = [[JSQLocationMediaItem alloc] init];
            [locationItem setLocation:location withCompletionHandler:^{
                [[NSNotificationCenter defaultCenter]postNotificationName:kLocationCellNeedUpdateNotification object:self];
            }];
            locationItem.appliesMediaViewMaskAsOutgoing=outgoing;
            message=[[JSQMessage alloc] initWithSenderId:senderId senderDisplayName:senderDisplayName date:timestamp media:locationItem];
        }
        case kAVIMMessageMediaTypeAudio:{
            AVIMAudioMessage *audioMsg=(AVIMAudioMessage*)self;
            NSString *cachePath= [self fileCacheUrlForFileName:[NSString stringWithFormat:@"%@.%@",self.messageId,audioMsg.format]];
            if(![[NSFileManager defaultManager]fileExistsAtPath:cachePath]){
                [self fetchDataOfMessageFile:audioMsg.file toDirctory:cachePath error:nil];
            }
           
            JSQAudioMediaItem *audioItem=[[JSQAudioMediaItem alloc]initWithURL:[NSURL URLWithString:cachePath] isReadyToPlay:YES];
            message=[JSQMessage messageWithSenderId:senderId displayName:senderDisplayName media:audioItem];
            
        }
            break;
    }
    message.timeStamp=self.sendTimestamp;
    message.messageID=self.messageId;
    callback(message);
}


//-(void)decorateVideoItemThumbnail:(JSQVideoMediaItem*)videoItem thubmnailImg:(UIImage*)thumbnailImg{
//    UIImageView *cachedVideoImageView= [videoItem valueForKey:@"cachedVideoImageView"];
//    CGSize thumbnailSize= cachedVideoImageView.frame.size;
//    UIImageView *newThumbnailView;
//    
//    UIImage *playIcon = [[UIImage jsq_defaultPlayImage] jsq_imageMaskedWithColor:[UIColor lightGrayColor]];
//    UIImageView * iconView = [[UIImageView alloc] initWithImage:playIcon];
//    iconView.backgroundColor = [UIColor clearColor];
//    iconView.frame = CGRectMake(0.0f, 0.0f, thumbnailSize.width, thumbnailSize.height);
//    iconView.contentMode = UIViewContentModeCenter;
//    iconView.clipsToBounds = YES;
//    
//    newThumbnailView = [[UIImageView alloc] initWithImage:thumbnailImg];
//    [newThumbnailView addSubview:iconView];
//    
//    newThumbnailView.backgroundColor = [UIColor blackColor];
//    newThumbnailView.frame = CGRectMake(0.0f, 0.0f, thumbnailSize.width, thumbnailSize.height);
//    newThumbnailView.contentMode = UIViewContentModeCenter;
//    newThumbnailView.clipsToBounds = YES;
//    [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:newThumbnailView isOutgoing:videoItem.appliesMediaViewMaskAsOutgoing];
//    
//    [videoItem setValue:newThumbnailView forKey:@"cachedVideoImageView"];
//}

-(NSString*)fileCacheUrlForFileName:(NSString *)fileName{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:fileName];
}

//把接收到的 媒体文件存到文件夹中
-(NSString*)fetchDataOfMessageFile:(AVFile*)file toDirctory:(NSString*)cachePath error:(NSError**)error{
    NSData  *data=[file getData:error];
    if(error==nil){
        [data writeToFile:cachePath atomically:YES];
    }
    return cachePath;
}
@end
