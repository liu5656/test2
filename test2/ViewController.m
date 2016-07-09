//
//  ViewController.m
//  test2
//
//  Created by lj on 16/2/27.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "ViewController.h"
#import "AsyncSocket.h"


@interface ViewController ()<AsyncSocketDelegate>

@property (nonatomic, strong)AsyncSocket *serverSocket;
@property (nonatomic, copy)NSString *host;
@property (nonatomic, strong)AsyncSocket *myNewSocket;
@property (nonatomic, strong)AsyncSocket *clientSocket;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.serverSocket = [[AsyncSocket alloc] initWithDelegate:self];
    [self.serverSocket acceptOnPort:8000 error:nil];
}

-(void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket{
    self.myNewSocket = newSocket;
}
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
    
    [self.myNewSocket readDataWithTimeout:-1 tag:0];
    self.host = host;
    NSLog(@"host = %@",host);
    
    
}
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag{
    NSString *info = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到信息%@",info);
    //继续读取数据
    [sock readDataWithTimeout:-1 tag:0];
}


- (void)attributeString
{
    NSString *str = @"你要放\n在2233 \n 里的文本字符串  \n  换行符";
    NSMutableAttributedString *attriStr = [[NSMutableAttributedString alloc] initWithString:str];
    
    NSAttributedString *subStr = [[NSAttributedString alloc] initWithString:@"哈哈"];
    
    
    [attriStr addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 3)];
    [attriStr addAttribute:NSForegroundColorAttributeName value:[UIColor blueColor] range:NSMakeRange(4, 6)];
    [attriStr addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:11] range:NSMakeRange(4, 6)];
    
    UILabel *lb = [[UILabel alloc]initWithFrame:CGRectMake(50,50,100,180)];
    lb.textAlignment = NSTextAlignmentCenter;
    lb.attributedText = attriStr;
    lb.numberOfLines = 0; // 最关键的一句
    [self.view addSubview:lb];

}

@end
