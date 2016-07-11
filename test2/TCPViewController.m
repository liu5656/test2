//
//  TCPViewController.m
//  test2
//
//  Created by lj on 16/7/8.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "TCPViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AsyncSocket.h"

@interface TCPViewController ()<AsyncSocketDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
@property (weak, nonatomic) IBOutlet UITextView *consoleTextView;
@property (nonatomic, strong) AsyncSocket *clientSocket;

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureAudioDataOutput* audioOutput;
@end

@implementation TCPViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self setUpSession];
    
    self.clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    [self.clientSocket connectToHost:@"192.168.77.107" onPort:10000 error:&error];
}




- (IBAction)sendAudioData:(UIButton *)sender {
    [self.session startRunning];
}
- (IBAction)stopSendAudioData:(UIButton *)sender {
    [self.session stopRunning];
}


- (IBAction)inviteFriendAction:(UIButton *)sender {
    NSString *dataStr = @"FS|{\"userid\":\"user10058\",\"username\",\"zhangpengfei\"}|user10100\n";
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket  writeData:data withTimeout:-1 tag:0];
}
- (IBAction)sendACData:(UIButton *)sender {
    NSString *str = @"AC|\n";
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:0];

}

- (IBAction)ldaction:(UIButton *)sender {

    NSString *dataStr = @"LD|user10058\n";
    NSData *data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket  writeData:data withTimeout:-1 tag:0];
}

- (void)ckAction
{
    [self.clientSocket writeData:[@"CK\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:15 tag:0];
    NSLog(@"开始发心跳包");
}

#pragma mark AsyncSocket delegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"连接上了");
    [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(ckAction) userInfo:nil repeats:YES];
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    NSLog(@"断开连接");
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"长度:%lu--数据:%@",(unsigned long)data.length, str);
    
    NSString *content = self.consoleTextView.text;
    self.consoleTextView.text = [content stringByAppendingString:str];
    [self.consoleTextView scrollRangeToVisible:NSMakeRange(self.consoleTextView.text.length, 1)];
    
    NSArray *tempArray = [str componentsSeparatedByString:@"|"];
    NSString *symbol = tempArray.firstObject;
    if ([@"ED" isEqualToString:symbol]) {
        NSLog(@"对方主动断开连接");
//        return;
    }else if ([@"AB" isEqualToString:symbol]) {
        NSLog(@"收到管理服务器数据");
        NSString *nodeServer = tempArray[1];
        NSString *portStr = tempArray.lastObject;

        [self disconnectManagerServerAndConnectNodeServer:nodeServer port:portStr.intValue];
        return;
    }else if ([@"EX" isEqualToString:symbol]) {
        NSLog(@"出现异常:%@",tempArray[1]);
//        return
    }
    
    
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    
}

- (void)disconnectManagerServerAndConnectNodeServer:(NSString *)host port:(UInt16)port
{
    self.clientSocket.delegate = nil;
    [self.clientSocket disconnect];
    self.clientSocket = nil;
    
    self.clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:port error:&error];
    NSLog(@"%@",error);
}


- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"data did send -- %ld", sock.userData);
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
        [self.clientSocket writeData:mutableData withTimeout:-1 tag:0];
        
    });

}

#pragma mark get



@end
