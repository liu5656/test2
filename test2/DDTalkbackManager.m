//
//  DDTalkbackManager.m
//  test2
//
//  Created by 刘健 on 16/7/9.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "DDTalkbackManager.h"
#import "GCDAsyncSocket.h"
#import "MessageData.h"

#define SocketManagerServerIP @"192.168.77.107"
#define SocketManagerServerPort 10000
#define TimeOut 30

#define UserID @"user10058"
#define Username @"bigheart"
#define FriendID @"user10100"
// 发送
#define SocketCommandIdentifyAC @"AC" // 管理服务器指令
#define SocketCommandIdentifyLD @"LD" // 和节点服务器建立长连接指令
#define SocketCommandIdentifyCK @"CK" // 心跳指令
#define SocketCommandIdentifyFS @"FS" // 向好友发起对讲请求指令 FS|{"userid":"user10300","username","张鹏飞"}|user10200
#define SocketCommandIdentifyFR @"FR" // 拒绝好友对讲请求指令
#define SocketCommandIdentifyFA @"FA" // 接收好友对讲请求指令
#define SocketCommandIdentifyED @"ED" // 退出与好友的对讲指令
#define SocketCommandIdentifySM @"SM" // 发送语音指令(好友)
#define SocketCommandIdentifySG @"SG" // 发送语音指令(频道)


// 接收
#define SocketCommandIdentifyAB @"AB" // 管理服务器返回节点服务器和端口
#define SocketCommandIdentifyFN @"FN" // 收到好友对讲请求
#define SocketCommandIdentify00 @"00" // 收到回复00
#define SocketCommandIdentifyEX @"EX" // 异常



@interface DDTalkbackManager()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSMutableData *SMData;
@property (nonatomic, strong) NSData *leftData;

@end

@implementation DDTalkbackManager


+ (instancetype)sharedInstance {
    static DDTalkbackManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDTalkbackManager alloc] init];
        // 先连接管理服务器
        sharedInstance.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:sharedInstance delegateQueue:dispatch_get_global_queue(0, 0)];
        [sharedInstance.clientSocket connectToHost:SocketManagerServerIP onPort:SocketManagerServerPort error:nil];
    });
    return sharedInstance;
}

- (void)inviteGoodFriendTalkback:(NSString *)toUserID fromUserID:(NSString *)fromUserID andUsername:(NSString *)fromUsername
{
    NSString *message = [NSString stringWithFormat:@"FS|{\"userid\":\"%@\",\"username\",\"%@\"}|%@", fromUserID, fromUsername, toUserID];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:30 tag:0];
}

- (void)disconnectManagerServerAndConnectNodeServer:(NSString *)host port:(NSString *)portStr
{
    self.clientSocket.delegate = nil;
    [self.clientSocket disconnect];
    self.clientSocket = nil;
    
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:portStr.integerValue error:&error];
    NSLog(@"重新连接只节点服务器错误:%@",error);
}


#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"数据已发送");
}

// 和socket服务器建立连接
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"did connect to %@, port %hu",host, port);
    if (port == SocketManagerServerPort) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            [self timer];
        });
        
        // request node server ip and port
        [self.clientSocket writeData:[[NSString stringWithFormat:@"%@|\n",SocketCommandIdentifyAC] dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    }else {
        // building long connect with node server
        NSString *LDcommand = [NSString stringWithFormat:@"%@|%@\n",SocketCommandIdentifyLD, UserID];
        [self.clientSocket writeData:[LDcommand dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
        
    }
    [self.clientSocket readDataWithTimeout:15 tag:0];
}

// 和socket服务器断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"did disconnect to %@,error:%@",sock.connectedHost, err);
    if (![sock.connectedHost isEqualToString:SocketManagerServerIP]) {
        [self.clientSocket connectToHost:sock.connectedHost onPort:sock.connectedPort error:nil];
    }
}

// 收到数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    // 黏包
    if (self.leftData.length) {
        NSMutableData *tempData = [NSMutableData dataWithData:self.leftData];
        [tempData appendData:data];
        data = [NSData dataWithData:tempData];
        self.leftData = nil;
    }
    
    
    // 直到大于2
    [self.SMData appendData:data];
    if(self.SMData.length < 2) {
        return;
    }
    
    NSData *messageTypeData = [self.SMData subdataWithRange:NSMakeRange(0, 2)];
    NSString *messageTypeStr = [[NSString alloc] initWithData:messageTypeData encoding:NSUTF8StringEncoding];
    /*
     ****************************************************音频****************************************************************************
     */
    if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到音频数据
        NSLog(@"收到命令:%@------当前收到的包的长度:%ld",messageTypeStr, data.length);
        NSInteger totalLength = 0;
        NSData *audioData = nil;
        NSData *useridData = nil;
        if (self.SMData.length < 6) {
            return;
        }
        
        NSData *totalLengthData = [self.SMData subdataWithRange:NSMakeRange(2, 4)];
        totalLength = convertDataToInt(totalLengthData);
        
        if (self.SMData.length < (totalLength + 6)) {
            return;
        }else{
            audioData = [self.SMData subdataWithRange:NSMakeRange(6, totalLength)];
        }
        
        // 找到音频数据结束后的换行符的range
        NSRange range = [self.SMData rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range:NSMakeRange(totalLength + 6, self.SMData.length - totalLength - 6)];
        if (range.location != NSNotFound) {
            // 拿到userid
            useridData = [self.SMData subdataWithRange:NSMakeRange(totalLength + 6, range.location - (totalLength + 6) - 1)];
        }
        
        NSString *useridStr = [[NSString alloc] initWithData:useridData encoding:NSUTF8StringEncoding];
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:useridStr];
        BOOL result = [audioData writeToFile:path atomically:YES];
        if (result) {
            NSLog(@"创建文件成功:%@",path);
        }else{
            NSLog(@"创建文件失败");
        }
        
        self.leftData = [self.SMData subdataWithRange:NSMakeRange(range.location + 1, self.SMData.length - (range.location + range.length - 1) )];
        self.SMData = nil;
        
        /*
         ****************************************************其他****************************************************************************
         */
        
    }else if ([SocketCommandIdentifyAB isEqualToString:messageTypeStr]) { // 管理服务器回复
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
        [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
    }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
        NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
    }else if ([SocketCommandIdentifyAC isEqualToString:messageTypeStr]) { // 连接管理服务器回复
        NSLog(@"收到命令:AC");
    }else if ([SocketCommandIdentifyCK isEqualToString:messageTypeStr]) { // 心跳包回复
        NSLog(@"收到命令:CK");
    }else if ([SocketCommandIdentifyFN isEqualToString:messageTypeStr]) { // 收到好友发出对讲请求
        NSLog(@"收到命令:FN");
        
        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
        [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
        
        
    }else if ([SocketCommandIdentifyED isEqualToString:messageTypeStr]) { // 断开和好友的对讲回复
        NSLog(@"收到命令:ED");
    }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
        NSLog(@"收到命令:EX");
    }else{ // 丢弃
    
    }

    self.SMData = nil;
    
    
//    [self test:data andSocket:sock];
}

- (void)test:(NSData *)data andSocket:(GCDAsyncSocket *)sock
{
    /*
     ************************************************************************************************************************************
     */
    
    
    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"has received data:%@",dataStr);
    NSLog(@"包长度:%ld",data.length);
    NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
    
    // 收到管理服务器发送的00|AC
    if ([sock.connectedHost isEqualToString:SocketManagerServerIP] && [SocketCommandIdentifyAB isEqualToString:tempArray.firstObject]) {
        [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
        return;
    }
    
    NSString *firstInstruction = tempArray.firstObject;
    
    // 处理音频数据
    if ([SocketCommandIdentifySM isEqualToString:firstInstruction] || [SocketCommandIdentifySG isEqualToString:firstInstruction]) { // 接收到对好友说出的音频数据
        [self handleReceivedAudioData:data];
        [self.clientSocket readDataWithTimeout:-1 tag:0];
        return;
    }
    
    // 处理普通指令
    if ([@"00" isEqualToString:firstInstruction]) {
        if (1 < tempArray.count) {
            NSString *commandStr = tempArray[1];
            if ([commandStr isEqualToString:SocketCommandIdentifyAC]) {
                
            }else if ([commandStr isEqualToString:SocketCommandIdentifyCK]) {
                
            }else if ([commandStr isEqualToString:SocketCommandIdentifySM]) {
                //                NSLog(@"message has sended");
                
            }else if ([commandStr isEqualToString:SocketCommandIdentifyFN]) { // 收到好友发出对讲请求
                [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
            }else if ([commandStr isEqualToString:SocketCommandIdentifyED]) {
                NSLog(@"好友已经断开和你的对讲连接");
            }
        }
        
    }else{ // 处理异常
        if (1 < tempArray.count) {
            NSString *errorNum = tempArray[1];
            NSString *responseStr = nil;
            if ([errorNum isEqualToString:@"90"]) {
                responseStr = @"好友不在线";
            }
        }
    }
    [self.clientSocket readDataWithTimeout:-1 tag:0];

}



/**
 ***************************************************好友对讲************************************************************************************
 */
- (void)inviteGoodFriendTalkbackFromUser:(NSString *)fromUser toUserID:(NSString *)toUserID
{
    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyFS, fromUser, toUserID];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
}


- (void)disconnectTalkback:(NSString *)fromUser WithUserID:(NSString *)toUserid
{
    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyED, fromUser, toUserid];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
}

- (void)refuseTalkbackInvitationOfFriendID:(NSString *)toUserID fromUser:(NSString *)fromUser
{
    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyED, fromUser, toUserID];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
}

/**
 *  收到好友对讲请求
 *
 *  @param fromUser 好友的json对象
 *  @param toUserID 自己的id
 */
- (void)acceptGoodFriendInviteFromUserID:(NSString *)fromUser toUserID:(NSString *)toUserID
{
    if ([self.delegate respondsToSelector:@selector(whetherAcceptFriendInvitation:completion:)]) {
        
        // 是否接收from的对讲请求
        __weak typeof(self) weadSelf = self;
        [self.delegate whetherAcceptFriendInvitation:fromUser completion:^(BOOL result, NSString *blockFromUser, NSString *blockToUserID) {
            [weadSelf handleInviationFrom:blockFromUser toUserID:blockToUserID WithResult:result];
        }];
    }
}

/**
 *  对好友的对讲请求进行操作
 *
 *  @param fromUser 自己的json对象
 *  @param toUserID 向我发起好友对讲的用户id
 *  @param result   是否接收对讲请求
 */
- (void)handleInviationFrom:(NSString *)fromUser toUserID:(NSString *)toUserID WithResult:(BOOL)result
{
    NSData *jsonData = [fromUser dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *fromUserDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableLeaves error:nil];
    NSString *fromUserName = [fromUserDict valueForKey:@"username"];
    NSString *fromUserID = [fromUserDict valueForKey:@"userid"];
    NSString *message = [NSString stringWithFormat:@"%@|{\"userid\":\"%@\",\"username\":\"%@\"}|%@",result?SocketCommandIdentifyFA:SocketCommandIdentifyFN, fromUserID, fromUserName, toUserID];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
}


/**
 ***************************************************发送或接收数据************************************************************************************
 */
- (void)sendAudioData:(NSData *)audioData toUserID:(NSString *)userid
{
    NSMutableData *mutableData = [NSMutableData data];
    NSUInteger a = audioData.length;
    Byte b[4];
    
    b[3] =  (a & 0xff);
    b[2] = (a >> 8 & 0xff);
    b[1] = (a >> 16 & 0xff);
    b[0] = (a >> 24 & 0xff);
    
    NSData *lengthData = [[NSData alloc] initWithBytes:b length:4];
    
    NSString *tempIDStr =  [userid stringByAppendingString:@"\n"];
    NSData *idData = [tempIDStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [mutableData appendData:[SocketCommandIdentifySM dataUsingEncoding:NSUTF8StringEncoding]];
    [mutableData appendData:lengthData];
    [mutableData appendData:audioData];
    [mutableData appendData:idData];
    
    NSLog(@"send data length:%ld",mutableData.length);
    
    //    dispatch_async(dispatch_get_main_queue(), ^{
    [self.clientSocket writeData:mutableData withTimeout:-1 tag:0];
    
    //    });
    
}

/**
 *  处理收到的音频数据
 *
 *  @param audioData 音频数据(需要进行格式处理才能播放)
 */
- (void)handleReceivedAudioData:(NSData *)audioData
{
    
}

#pragma mark get
- (NSTimer *)timer
{
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(sendHeartBeatPacket) userInfo:nil repeats:YES];
        [_timer fire];
    }
    return _timer;
}

- (void)sendHeartBeatPacket
{
    NSLog(@"send heartbeat packet");
    [self.clientSocket writeData:[@"CK|\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:15 tag:0];

}

- (NSMutableData *)SMData
{
    if (!_SMData) {
        _SMData = [NSMutableData data];
    }
    return _SMData;
}


#pragma mark life circle
- (void)dealloc
{
    NSLog(@"%s",__func__);
}


#pragma mark c function
NSData *convertIntToData(int totallength)
{
    unsigned char* totallengthByte =malloc(sizeof(unsigned char) * 4);
    totallengthByte[0] = (char)(totallength >>24 & 0xff);
    totallengthByte[1] = (char)((totallength >> 16) & 0xff);
    totallengthByte[2] = (char)((totallength >> 8) & 0xff);
    totallengthByte[3] = (char)((totallength) & 0xff);
    NSData *data = [NSData dataWithBytes:totallengthByte length:4];
    return data;
}

int convertDataToInt(NSData *data)
{
    return CFSwapInt32BigToHost(*(int*)([data bytes]));
}


@end
