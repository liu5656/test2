//
//  DDTalkbackDemoViewController.m
//  test2
//
//  Created by 刘健 on 16/7/11.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "DDTalkbackDemoViewController.h"

#import "DDTalkbackManager.h"

#import <AVFoundation/AVFoundation.h>

@interface DDTalkbackDemoViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) DDTalkbackManager *talkbackManager;

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureAudioDataOutput* audioOutput;

@end

@implementation DDTalkbackDemoViewController
- (IBAction)inviteFriendAction:(UIButton *)sender {
    [self.talkbackManager inviteGoodFriendTalkbackFromUser:@"{\"userid\":\"user10058\",\"username\",\"zhangpengfei\"}" toUserID:@"user10100"];
}
- (IBAction)startSendAudioAction:(UIButton *)sender {
    [self.session startRunning];
}
- (IBAction)endSendAudioAction:(UIButton *)sender {
    [self.session stopRunning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpSession];
    self.talkbackManager = [DDTalkbackManager sharedInstance];
//    self.talkbackManager = [[DDTalkbackManager alloc] init];
    
    
    AVAudioSession *avSession = [AVAudioSession sharedInstance];
    
    if ([avSession respondsToSelector:@selector(requestRecordPermission:)]) {
        
        [avSession requestRecordPermission:^(BOOL available) {
            
            if (available) {
                //completionHandler
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[[UIAlertView alloc] initWithTitle:@"无法录音" message:@"请在“设置-隐私-麦克风”选项中允许xx访问你的麦克风" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil] show];
                });
            }
        }];
        
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark audio data
-(void) setUpSession
{
    _session = [[AVCaptureSession alloc] init];
    
    AVCaptureDevice * audioDevice1 = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    AVCaptureDeviceInput *audioInput1 = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice1 error:nil];
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    
    dispatch_queue_t queue = dispatch_queue_create("MyQueue", NULL);
    [_audioOutput setSampleBufferDelegate:self queue:queue];
    
    [_session beginConfiguration];
    if (audioInput1) {
        [_session addInput:audioInput1];
    }
    
    [_session addOutput:_audioOutput];
    
    [_session commitConfiguration];
    
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    
    CMBlockBufferRef blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer);
    size_t length = CMBlockBufferGetDataLength(blockBufferRef);
    Byte buffer[length];
    CMBlockBufferCopyDataBytes(blockBufferRef, 0, length, buffer);
    NSData *data = [NSData dataWithBytes:buffer length:length];
    
    
    NSMutableData *mutableData = [NSMutableData data];
    
    NSData *smData = [@"SM" dataUsingEncoding:NSUTF8StringEncoding];
    
    
    NSUInteger a = data.length;
    Byte b[4];
    
    b[3] =  (a & 0xff);
    b[2] = (a >> 8 & 0xff);
    b[1] = (a >> 16 & 0xff);
    b[0] = (a >> 24 & 0xff);
    
    NSData *lengthData = [[NSData alloc] initWithBytes:b length:4];
    NSData *useridData = [@"user10100\n" dataUsingEncoding:NSUTF8StringEncoding];
    
    [mutableData appendData:smData];
    [mutableData appendData:lengthData];
    [mutableData appendData:data];
    [mutableData appendData:useridData];
    
    NSLog(@"send data length:%ld",mutableData.length);
    
    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.clientSocket writeData:mutableData withTimeout:-1 tag:0];
        [self.talkbackManager sendAudioData:mutableData toUserID:@"user10100"];
        
    });
    
}


@end
