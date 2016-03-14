//
//  NSNotification+UploadMedia.h
//  PiChat
//
//  Created by pi on 16/3/14.
//  Copyright © 2016年 pi. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AVFile;

static NSString *const kUploadMediaNotification=@"kUploadMediaNotification";

typedef enum : NSUInteger {
    UploadStateComplete,
    UploadStateProgress,
    UploadStateFailed,
} UploadState;

typedef enum : NSUInteger {
    UploadedMediaTypePhoto,
    UploadedMediaTypeVideo,
    UploadedMediaTypeAduio,
    UploadedMediaTypeFile,
} UploadedMediaType;

@interface NSNotification (UploadMedia)
@property (assign,nonatomic,readonly) UploadState uploadState;
@property (strong,nonatomic,readonly) AVFile *uploadedFile;
@property (assign,nonatomic,readonly) float progress;
@property (assign,nonatomic,readonly) UploadedMediaType mediaType;
@property (strong,nonatomic,readonly) NSError *error;

+(void)postUploadMediaProgressNotification:(id)object percentDone:(NSInteger)percentDone;

+(void)postUploadMediaCompleteNotification:(id)object media:(AVFile*)media type:(UploadedMediaType)mediaType;

+(void)postUploadMediaFailedNotification:(id)object error:(NSError *)error;
@end
