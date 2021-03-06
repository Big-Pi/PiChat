//
//  AudioRecorderController.m
//  PiChat
//
//  Created by pi on 16/3/8.
//  Copyright © 2016年 pi. All rights reserved.
//

#import "AudioRecorderController.h"
#import "CommenUtil.h"

@import AVFoundation;

@interface AudioRecorderController ()<AVAudioRecorderDelegate>
@property (strong,nonatomic) AVAudioRecorder *recorder;
@property (strong,nonatomic) AVAudioPlayer *player;
@property (strong,nonatomic) NSTimer *timer;
@end

@implementation AudioRecorderController
-(AVAudioRecorder *)recorder{
    if(!_recorder){
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        [dic setObject:@(kAudioFormatLinearPCM) forKey:AVFormatIDKey];  //设置录音格式
        [dic setObject:@(8000) forKey:AVSampleRateKey];                 //设置采样率
        [dic setObject:@(1) forKey:AVNumberOfChannelsKey];              //设置通道，这里采用单声道
        [dic setObject:@(8) forKey:AVLinearPCMBitDepthKey];             //每个采样点位数，分为8，16，24，32
        [dic setObject:@(YES) forKey:AVLinearPCMIsFloatKey];
        _recorder=[[AVAudioRecorder alloc]initWithURL:[self cacheFileUrl] settings:dic error:nil];
        _recorder.meteringEnabled=YES;
        _recorder.delegate=self;
    }
    return _recorder;
}

-(NSTimer *)timer{
    if(!_timer){
        //0.03 = 30帧/ s
        _timer=[NSTimer timerWithTimeInterval:0.02 target:self selector:@selector(updateMetersView:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop]addTimer:_timer forMode:NSRunLoopCommonModes];
    }
    return _timer;
}

-(NSURL*)cacheFileUrl{
    
    NSString *cacheDir=[CommenUtil cacheDirectoryStr];
    NSString *identifier = [CommenUtil randomFileName];
    NSURL *cacheFile= [NSURL fileURLWithPath:[cacheDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.caf",identifier]]];
    
    return cacheFile;
}

#pragma mark - AVAudioRecorderDelegate
-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)success{
    if(success){
        [self.delegate audioRecorder:self didEndRecord:recorder.url];
    }else{
        [self.delegate audioRecorder:self didEndRecord:nil];
    }
}


-(void)updateMetersView:(NSTimer*)timer{
    [self.recorder updateMeters];
    CGFloat power= [self.recorder averagePowerForChannel:0];
    [self.delegate audioRecorder:self updateSoundLevel:power];
}


#pragma mark - Record
- (void)startRecord {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    [audioSession setActive:YES error:&error];
    if(error){
        NSLog(@"%@",error);
        return;
    }
    self.timer.fireDate=[NSDate distantPast];
    [self.recorder record];
}

- (void)endRecord {
    self.timer.fireDate=[NSDate distantFuture];
    [self.recorder stop];
}

+(NSTimeInterval)durationForAudioFile:(NSURL*)audioUrl{
    AVURLAsset* audioAsset = [AVURLAsset URLAssetWithURL:audioUrl options:nil];
    CMTime audioDuration = audioAsset.duration;
    float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
    return audioDurationSeconds;

}

@end