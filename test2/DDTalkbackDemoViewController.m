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

@interface DDTalkbackDemoViewController ()<AVCaptureAudioDataOutputSampleBufferDelegate, DDTalkbackManagerDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DDTalkbackManager *talkbackManager;

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureAudioDataOutput* audioOutput;


@property (nonatomic, copy) goodFriendInviteResultBlock goodFriendInviteation;
@property (nonatomic, copy) channelCallback inviteChannellCallback;
@property (nonatomic, copy) channelCallback acceptChannelCallback;

@property (nonatomic, assign) BOOL isChannel;

@end

@implementation DDTalkbackDemoViewController
- (IBAction)inviteFriendAction:(UIButton *)sender {
    [self.talkbackManager inviteGoodFriendTalkbackFromUser:@"{\"userid\":\"user10058\",\"username\",\"zhangpengfei\"}" toUserID:@"user10100"];
}
- (IBAction)startSendAudioAction:(UIButton *)sender {
    [self startSendAudioType:TalkbackTypeFriend];
}
- (IBAction)endSendAudioAction:(UIButton *)sender {
    [self stopSendAudio];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpSession];
    self.talkbackManager = [DDTalkbackManager sharedInstance];
    self.talkbackManager.delegate = self;
    
}

- (IBAction)joinChannelAction:(UIButton *)sender {
//    GS||
    [[DDTalkbackManager sharedInstance] requestJoinChannelTalkback:@"{\"groupId\":\"10082\",\"groupName\":\"ccccc\"}" andFromUser:@"{\"userid\":\"user10300\",\"username\":\"billie_jean\"}"];
}
- (IBAction)sendAudioToChannel:(UIButton *)sender {
    [self startSendAudioType:TalkbackTypeChannel];
}
- (IBAction)QuiteChannel:(UIButton *)sender {
    [[DDTalkbackManager sharedInstance] quiteCurrentChannelTalkback:@"{\"groupId\":\"10082\",\"groupName\":\"ccccc\"}" andFromUser:@"{\"userid\":\"user10300\",\"username\":\"billie_jean\"}"];
}


- (void)startSendAudioType:(TalkbackType)type
{
    if (type == TalkbackTypeFriend) {
        self.isChannel = NO;
    }else{
        self.isChannel = YES;
    }
    [self.session startRunning];
}

- (void)stopSendAudio
{
    [self.session stopRunning];
    self.isChannel = NO;
}


#pragma mark ddtalkback manager delegate
/**
 *  收到好友对讲邀请后的操作
 *
 *  @param fromUser   好友的json对象
 *  @param callback 待用户选择 接受 或 拒绝 后的回调块
 */
- (void)whetherAcceptFriendInvitation:(NSString *)fromUser completion:(goodFriendInviteResultBlock)callback
{
    [self showMessage:@"收到好友对讲邀请" andparameter:fromUser];
    _goodFriendInviteation = callback;
}

/**
 *  进入频道时,没人对讲,是否邀请频道成员进行对讲回调块
 *
 *  @param result 是否邀请
 *  @param blocksender 发送邀请的对象json
 *  @param bolcKChannel 向哪个频道发送
 */
- (void)whetherInviteOtherChannelMemeberAftercompletion:(channelCallback)callback
{
    [self showMessage:@"进入频道是否向当前频道其他成员发送邀请" andparameter:nil];
    _inviteChannellCallback = callback;
}

/**
 *  收到频道对讲邀请
 *
 *  @param result 是否接受邀请
 *  @param blocksender 发送邀请对象
 *  @param bolcKChannel 向哪个频道发送
 *  @param callback 用户选择回调块{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
 */
- (void)whetherAcceptChannelInvitation:(NSString *)channel completion:(channelCallback)callback
{
    
    [self showMessage:@"是否接受频道的邀请" andparameter:channel];
    _acceptChannelCallback = callback;
}


- (void)showMessage:(NSString *)message andparameter:(NSString *)parameter
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:message message:parameter delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"确定", nil];
        [alert show];
    });
}


#pragma mark uialert view delegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *parameter = alertView.message;
    if (_acceptChannelCallback && 1 == buttonIndex) { // 接受频道邀请
        
        NSArray *array = [parameter componentsSeparatedByString:@"|"];
        
        
        
        _acceptChannelCallback(YES, @"{\"userid\":\"user10058\",\"username\":\"billie_jean\"}",array.lastObject);
    }else if (_goodFriendInviteation && 1 == buttonIndex) { // 接受好友邀请
    
    }else if (_goodFriendInviteation && 0 == buttonIndex) { // 拒绝好友邀请
    
    }else if (_inviteChannellCallback && 1 == buttonIndex) { // 邀请好友进入频道
        _inviteChannellCallback(YES, @"{\"groupId\":\"10060\",\"groupName\":\"飙车俱乐部\"}", @"{\"userid\":\"user10058\",\"username\":\"billie_jean\"}");
    }
    
    _goodFriendInviteation = nil;
    _inviteChannellCallback = nil;
    _acceptChannelCallback = nil;
}

#pragma mark audio data
-(void) setUpSession
{
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
    
    [self.talkbackManager sendAudioData:mutableData andSenderID:@"user10300" withTalkbackType:self.isChannel ? TalkbackTypeChannel :TalkbackTypeFriend];
    
    
}


@end
