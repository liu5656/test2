//
//  AudioViewController.m
//  test2
//
//  Created by lj on 16/7/8.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "AudioViewController.h"
#import "AsyncSocket.h"


@interface AudioViewController ()<AsyncSocketDelegate>

@property (nonatomic, strong) AsyncSocket *clientSocket;

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [NSThread detachNewThreadSelector:@selector(clientSocketConnect) toTarget:self withObject:nil];
}

- (void)clientSocketConnect
{
    
}

#pragma mark async socekt delegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"did connect to %@", host);
}

- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    
}

#pragma mark get
- (AsyncSocket *)clientSocket
{
    if (!_clientSocket) {
        _clientSocket = [[AsyncSocket alloc] initWithDelegate:self];
        [_clientSocket connectToHost:@"192.168.20.183" onPort:10000 withTimeout:-1 error:nil];
    }
    return _clientSocket;
}
@end
