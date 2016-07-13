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

#define SocketManagerServerIP @"192.168.77.118"
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
#define SocketCommandIdentifyET @"ET" // 音频结束


@interface DDTalkbackManager()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSMutableData *SMData;
@property (nonatomic, strong) NSMutableData *leftData;

@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) NSData *useridData;

@property (nonatomic, assign) int number;

@end

@implementation DDTalkbackManager


+ (instancetype)sharedInstance {
    static DDTalkbackManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[DDTalkbackManager alloc] init];
        // 先连接管理服务器
        dispatch_queue_t serialQueue = dispatch_queue_create([@"serial_queue" UTF8String], DISPATCH_QUEUE_SERIAL);
        sharedInstance.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:sharedInstance delegateQueue:serialQueue];
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
    
    dispatch_queue_t serialQueue = dispatch_queue_create([@"serial_queue" UTF8String], DISPATCH_QUEUE_SERIAL);
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:serialQueue];
    NSError *error = nil;
    [self.clientSocket connectToHost:host onPort:portStr.integerValue error:&error];
//    NSLog(@"重新连接只节点服务器错误:%@",error);
}


#pragma mark GCDAsyncSocketDelegate
- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
//    NSLog(@"数据已发送");
}

// 和socket服务器建立连接
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"did connect to %@, port %hu",host, port);
    if (port == SocketManagerServerPort) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self timer];
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
    
    
    [self test5:data andSocket:sock];
    
}

- (void)test5:(NSData *)data andSocket:(GCDAsyncSocket *)sock
{
    NSLog(@"当前线程:%@,循环之前的data数据长度:%ld,++++++ 上一次残缺数据剩余:%ld",[NSThread currentThread],data.length, self.leftData.length);
    // 黏包
    if (self.leftData.length) {
        NSMutableData *tempData = [NSMutableData dataWithData:self.leftData];
        [tempData appendData:data];
        data = [NSData dataWithData:tempData];
        self.leftData = nil;
    }
    
    NSData *useridData = nil;
    NSInteger offset = 0;
    NSInteger number =0;
    do{
        if (data.length < (offset + 2)) {
            offset -= 2;
            break;
        }
        NSData *messageTypeData = [data subdataWithRange:NSMakeRange(offset, 2)];
        NSString *messageTypeStr = [[NSString alloc] initWithData:messageTypeData encoding:NSUTF8StringEncoding];
        // 偏移量指向包长度字节开始位置
        offset += 2;
        
        if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到音频数据
            // 取数据前判断
            if (data.length < (offset + 4)) {
                offset -= 2;
                break;
            }
            NSInteger currentAudioLength = convertDataToInt([data subdataWithRange:NSMakeRange(offset, 4)]);
            // 偏移量指向音频包内容开始位置
            offset += 4;
            
            if (data.length < (offset + currentAudioLength)){
                offset -= 6;
                break;
            }
            [self.audioData appendData:[data subdataWithRange:NSMakeRange(offset, currentAudioLength)]];
            
            // 偏移量指向userid开始位置
            offset += currentAudioLength;
            
            NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding] options:0 range:NSMakeRange(offset, data.length - offset)];
            if (range.location != NSNotFound) {
                useridData = [data subdataWithRange:NSMakeRange(offset, range.location - offset)];
                NSString *str = [[NSString alloc] initWithData:useridData encoding:NSUTF8StringEncoding];
                NSLog(@"当前线程:%@,发送者的id:%@",[NSThread currentThread], str);
            }else{
                offset -= (currentAudioLength + 4 + 2);
                break; // 没找到userid,就跳出去,并保留当前剩下的data
            }
            
            offset += (useridData.length + 1); // 加1是为了跨过换行符
            
        }else if ([SocketCommandIdentifyET isEqualToString:messageTypeStr]) { // 音频结束
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            
            NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"xxx.mp3"];
            BOOL result = [self.audioData writeToFile:path atomically:YES];
            if (result) {
                NSLog(@"创建文件成功:%@",path);
            }else{
                NSLog(@"创建文件失败");
            }
            self.audioData = nil;
            
        }else if ([SocketCommandIdentifyAB isEqualToString:messageTypeStr]) { // 管理服务器回复
            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            
            NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
            [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
            NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentifyAC isEqualToString:messageTypeStr]) { // 连接管理服务器回复
            NSLog(@"收到命令:AC");
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentifyCK isEqualToString:messageTypeStr]) { // 心跳包回复
            NSLog(@"收到命令:CK");
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentifyFN isEqualToString:messageTypeStr]) { // 收到好友发出对讲请求
            NSLog(@"收到命令:FN");
            
            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
            [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
            
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentifyED isEqualToString:messageTypeStr]) { // 断开和好友的对讲回复
            NSLog(@"收到命令:ED");
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
            NSLog(@"收到命令:EX");
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
        }else{
            [self.clientSocket readDataWithTimeout:-1 tag:0];
            return;
        }
        number++;
        NSLog(@"当前线程:%@,循环次数%ld",[NSThread currentThread] ,number);
    } while (data.length - offset > 1);
    
    // 存包r
    if (data.length - offset > 1) {
        self.leftData = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(offset, data.length - offset)]];
    }
    
    [self.clientSocket readDataWithTimeout:-1 tag:0];
//    NSLog(@"while之后解包次数%d",_number);
    NSLog(@"当前线程:%@,循环之后:audiodata长度:%ld, -------上一次残缺数据剩余:%ld",[NSThread currentThread],self.audioData.length, self.leftData.length);
}


// 取出当前偏移位置到下一个换行符的数据,并偏移
- (NSData *)offset:(NSData *)data andOffset:(NSInteger *)offset
{
    NSData *tempData = nil;
    NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(*offset, data.length - *offset)];
    if (range.location != NSNotFound) {
        tempData = [data subdataWithRange:NSMakeRange(*offset, range.location - *offset)];
        *offset = range.location;
    }else{
        *offset -= 2;
    }
    return tempData;
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
    [self.clientSocket writeData:[@"CK|\n" dataUsingEncoding:NSUTF8StringEncoding] withTimeout:15 tag:0];

}

- (NSMutableData *)SMData
{
    if (!_SMData) {
        _SMData = [NSMutableData data];
    }
    return _SMData;
}

- (NSMutableData *)audioData
{
    if (!_audioData) {
        _audioData = [NSMutableData data];
    }
    return _audioData;
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
