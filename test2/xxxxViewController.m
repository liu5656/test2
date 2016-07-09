//
//  xxxxViewController.m
//  test2
//
//  Created by lj on 16/7/9.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "xxxxViewController.h"
#import "AsyncSocket.h"

@interface xxxxViewController ()

@property (nonatomic, strong) AsyncSocket *socket;

@end

@implementation xxxxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.socket = [[AsyncSocket alloc] initWithDelegate:self];
    [self.socket connectToHost:@"192.168.20.251" onPort:10000 error:nil];
}



@end
