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
#import "NSString+Model.h"

#define SocketManagerServerIP @"192.168.20.183"
#define SocketManagerServerPort 10001
#define TimeOut 30

#define UserID @"user10020"
#define Username @"bigheart"
#define FriendID @"user10058"

#pragma mark send command
#define SocketCommandIdentifyAC @"AC" // 管理服务器指令
#define SocketCommandIdentifyLD @"LD" // 和节点服务器建立长连接指令
#define SocketCommandIdentifyCK @"CK" // 心跳指令
#define SocketCommandIdentifyFS @"FS" // 向好友发起对讲请求指令 FS|{"userid":"user10300","username","张鹏飞"}|user10200
#define SocketCommandIdentifyFR @"FR" // 拒绝好友对讲请求指令
#define SocketCommandIdentifyFA @"FA" // 接收好友对讲请求指令
#define SocketCommandIdentifyED @"ED" // 退出与好友的对讲指令
#define SocketCommandIdentifySM @"SM" // 发送语音指令(好友)
#define SocketCommandIdentifySG @"SG" // 发送语音指令(频道)

#pragma mark channel send command
#define SocketCommandIdentifyGS @"GS" // 发出进入频道对讲的指令：GS|{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
#define SocketCommandIdentifyEG @"EG" // 退出当前正在对讲的频道 EG|{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
#define SocketCommandIdentifyGM @"GM" // 进入频道没人对讲时,邀请 GM|{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
#define SocketCommandIdentifyGT @"GT" // 频道对讲语音结束标志 GT|发送者对象 GT|{"userid":"user10300","username":"user10300"}

#pragma mark receive command
#define SocketCommandIdentifyAB @"AB" // 管理服务器返回节点服务器和端口
#define SocketCommandIdentifyFN @"FN" // 收到好友对讲请求
#define SocketCommandIdentify00 @"00" // 收到回复00
#define SocketCommandIdentifyEX @"EX" // 异常
#define SocketCommandIdentifyET @"ET" // 好友对讲语音结束标志 ET|发送者对象 ET|{"userid":"user10300","username":"user10300"}
#define SocketCommandIdentifyAL @"AL" // 频道有人在对讲,节点相同,进入频道后就可以收到 AL|已经进入的人员列表
#define SocketCommandIdentifyGB @"GB" // 频道有人在对讲,节点不同,需要连接到此返回的节点服务器和端口后发送LD命令成功后就可以使用GS进入频道

#pragma mark channel receive command
#define SocketCommandIdentifyNT @"NT" // 有人进入频道时：协议：NT|新进入对象|频道对象
#define SocketCommandIdentifyEG @"EG" // 有人退出频道时：协议：EG|退出者对象|频道对象
#define SocketCommandIdentifySG @"SG" // 发送或接收频道语音 SG(|)语音部分的字节数(|)二进制语音(|)说话者userId



typedef enum : NSUInteger {
    SocketExceptionTypeNobodyOnline = 0,            // 没人在线,没人对讲
    SocketExceptionTypeNobodyOnTalk = 91,           // 有人在线,没人对讲
    SocketExceptionTypeFriendNotOnline = 90,        // 好友不在线
} SocketExceptionType;


@interface DDTalkbackManager()<GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@property (nonatomic, strong) NSMutableData *SMData;
@property (nonatomic, strong) NSMutableData *leftData;

@property (nonatomic, strong) NSMutableData *audioData;
@property (nonatomic, strong) NSData *useridData;

@property (nonatomic, assign) int number;

@property (nonatomic, strong) NSMutableDictionary *channelAudioDataDictionary;
@property (nonatomic, strong) NSMutableArray *channelAudioDataIndexArray;

@property (nonatomic, copy) NSString *connectedHost;
@property (nonatomic, copy) NSString *port;


// 接受邀请时,需要跟换节点服务器时暂时保存这两个对象
@property (nonatomic, strong) NSString *sender;
@property (nonatomic, copy) NSString *channel;

@property (nonatomic, assign) NSInteger inviteFriendCountDown;

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
    
    self.connectedHost = host;
    self.port = portStr;
    
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
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

// 和socket服务器断开连接
- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"did disconnect to %@,error:%@",sock.connectedHost, err);
    if (![sock.connectedHost isEqualToString:SocketManagerServerIP]) {
        [self.clientSocket connectToHost:self.connectedHost onPort:self.port.integerValue error:nil];
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
        
        if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到好友音频数据
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
         
        }else if ([SocketCommandIdentifyET isEqualToString:messageTypeStr]) { // 好友语音结束标志
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
            
        }else if ([SocketCommandIdentifyFR isEqualToString:messageTypeStr]) { // 拒绝好友的对讲邀请
            
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            NSString *errStr = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            NSLog(@"收到命令:FR---%@",errStr);
            [self handleResultOfInvitationFromFriend:YES andReason:errStr];
        }else if ([SocketCommandIdentifyFA isEqualToString:messageTypeStr]) { // 接受好友的对讲邀请
            
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            NSString *str = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            NSLog(@"收到命令:FA---%@",str);
            [self handleResultOfInvitationFromFriend:YES andReason:str];
            
        /*
         ******************************频道****************************************
         */
        }else if ([SocketCommandIdentifySG isEqualToString:messageTypeStr]) { // 收到频道音频数据
            if (data.length < (offset + 4)) {
                offset -= 2;
                break;
            }
            
            NSInteger currentAudioLength = convertDataToInt([data subdataWithRange:NSMakeRange(offset, 4)]); // 音频文件长度占四个字节
            offset += 4;
            
            if (data.length < (offset + currentAudioLength)){
                offset -= 6;
                break;
            }
            NSData *tempData = [data subdataWithRange:NSMakeRange(offset, currentAudioLength)];
            
            
            // 偏移量指向userid开始位置
            offset += currentAudioLength;
            
            NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding] options:0 range:NSMakeRange(offset, data.length - offset)];
            if (range.location != NSNotFound) {
                useridData = [data subdataWithRange:NSMakeRange(offset, range.location - offset)];
                NSString *str = [[NSString alloc] initWithData:useridData encoding:NSUTF8StringEncoding];
                
                NSLog(@"当前线程:%@,发送者的id:%@",[NSThread currentThread], str);
                
                NSMutableData *valueData = [self.channelAudioDataDictionary valueForKey:str];
                if (valueData.length) {
                    [valueData appendData:tempData];
                }else{
                    NSMutableData *mutableData = tempData.mutableCopy;
                    [self.channelAudioDataDictionary setObject:mutableData forKey:str];
                    [self.channelAudioDataIndexArray addObject:str];
                }
            }else{
                offset -= (currentAudioLength + 4 + 2);
                break; // 没找到userid,就跳出去,并保留当前剩下的data
            }
            
            offset += (useridData.length + 1); // 加1是为了跨过换行符
            
        }else if ([SocketCommandIdentifyGT isEqualToString:messageTypeStr]) { // 频道语音结束标志
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;

            NSString *userInfo = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            
            NSArray *tempArray = [userInfo componentsSeparatedByString:@"|"];
            NSString *string = tempArray.firstObject;
            NSDictionary *dict = string.toDictionary;
            NSString *userid = [dict valueForKey:@"userid"];
            
            NSMutableData *userAudioData = [self.channelAudioDataDictionary valueForKey:userid];
            if (userAudioData.length) { // 频道语音字典里面存在
                
                NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp3",userid]];
                
                BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:path];
                if (isExist) {
                    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                }
                
                BOOL result = [userAudioData writeToFile:path atomically:YES];
                if (result) {
                    NSLog(@"创建文件成功:%@",path);
                }else{
                    NSLog(@"创建文件失败");
                }
                
                [self.channelAudioDataDictionary removeObjectForKey:userid];
//                for (<#initialization#>; <#condition#>; <#increment#>) {
//                    <#statements#>
//                }
                
            }
        }else if ([SocketCommandIdentifyGM isEqualToString:messageTypeStr]) { // 收到频道邀请
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            
            [self handleChannelInviteation:data];
        }else if ([SocketCommandIdentifyAL isEqualToString:messageTypeStr]) { // 进入频道,得到对讲人员列表
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            
            NSString *list = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            NSLog(@"进入频道,得到对讲人员列表:%@",list);
        }else if ([SocketCommandIdentifyNT isEqualToString:messageTypeStr]) { // 有人进入频道,
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            
            NSString *incomer = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            NSLog(@"有新人进入频道:%@",incomer);
            
        }else if ([SocketCommandIdentifyEG isEqualToString:messageTypeStr]) { // 有人退出频道,
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            
            NSString *dropout = [[NSString alloc] initWithData:tempData encoding:NSUTF8StringEncoding];
            NSLog(@"有人退出频道:%@",dropout);
            
        }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
            NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            [self handleCommonResponseData:data];

        }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
            
            NSData *tempData = [self offset:data andOffset:&offset];
            if (tempData.length == 0) break;
            [self handleExceptionFromServer:tempData];
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
    NSLog(@"当前线程:%@,循环之后:audiodata长度:%ld, -------上一次残缺数据剩余:%ld",[NSThread currentThread],self.audioData.length, self.leftData.length);
}


// 取出当前偏移位置到下一个换行符的数据,并偏移
- (NSData *)offset:(NSData *)data andOffset:(NSInteger *)offset
{
    NSData *tempData = nil;
    NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:0 range:NSMakeRange(*offset, data.length - *offset)];
    if (range.location != NSNotFound) {
        tempData = [data subdataWithRange:NSMakeRange(*offset + 1, range.location - *offset)];
        *offset = range.location;
    }else{
        *offset -= 2;
    }
    return tempData;
}







#pragma mark ***************************************************好友对讲************************************************************************
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

//- (void)refuseTalkbackInvitationOfFriendID:(NSString *)toUserID fromUser:(NSString *)fromUser
//{
//    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyED, fromUser, toUserID];
//    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
//    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
//}

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
    NSString *message = [NSString stringWithFormat:@"%@|{\"userid\":\"%@\",\"username\":\"%@\"}|%@\n",result?SocketCommandIdentifyFA:SocketCommandIdentifyFR, fromUserID, fromUserName, toUserID];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
}


#pragma mark ***************************************************开始发送,结束发送*******************************************************************
- (void)sendAudioData:(NSData *)audioData andSenderID:(NSString *)senderid withTalkbackType:(TalkbackType)type
{
    NSMutableData *mutableData = [NSMutableData data];
    NSUInteger a = audioData.length;
    Byte b[4];
    
    b[3] =  (a & 0xff);
    b[2] = (a >> 8 & 0xff);
    b[1] = (a >> 16 & 0xff);
    b[0] = (a >> 24 & 0xff);
    
    NSData *lengthData = [[NSData alloc] initWithBytes:b length:4];
    
    NSString *tempIDStr =  [senderid stringByAppendingString:@"\n"];
    NSData *idData = [tempIDStr dataUsingEncoding:NSUTF8StringEncoding];
    
    NSString *commandStr = [NSString stringWithFormat:@"%@",type == TalkbackTypeFriend ? SocketCommandIdentifySM : SocketCommandIdentifySG];
    NSData *commandData = [commandStr dataUsingEncoding:NSUTF8StringEncoding];
    
    [mutableData appendData:commandData];
    [mutableData appendData:lengthData];
    [mutableData appendData:audioData];
//    [mutableData appendData:idData];
    
    NSLog(@"send data length:%ld",mutableData.length);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.clientSocket writeData:mutableData withTimeout:-1 tag:0];
    });
    
}

- (void)finishSendAudioDataByType:(TalkbackType)type
{
    NSString *sendStr = nil;
    if (type == TalkbackTypeFriend) {
        sendStr = SocketCommandIdentifyET;
    }else{
        sendStr = SocketCommandIdentifyGT;
    }
    sendStr = [sendStr stringByAppendingString:@"|{\"userid\":\"user10020\",\"username\":\"梨花哥\"}\n"];
    [self sendString:sendStr];
}

#pragma mark *************************************************操作服务器返回的局部数据****************************************************************
- (void)handleResultOfInvitationFromFriend:(BOOL)result andReason:(NSString *)reason
{
    if ([self.delegate respondsToSelector:@selector(inviteFriendResult:andReason:)]) {
        [self.delegate inviteFriendResult:result andReason:reason];
    }
}

/**
 *  处理收到的频道对讲邀请
 *
 *  @param invitationData 邀请数据
 */
- (void)handleChannelInviteation:(NSData *)invitationData
{
    NSString *str = [[NSString alloc] initWithData:invitationData encoding:NSUTF8StringEncoding];
    NSArray *tempArray = [str componentsSeparatedByString:@"|"];
    
    NSString *senderInfo = tempArray[1];
    NSString *channelInfo = tempArray[2];
    NSString *nodeServerIP = nil;
    NSString *nodeServerPort = nil;
    if (3 < tempArray.count) {
        nodeServerIP = tempArray[2];
        nodeServerPort = tempArray.lastObject;
    }
    
    if ([self.delegate respondsToSelector:@selector(whetherAcceptChannelInvitation:completion:)]) {
        __weak typeof(self) weakSelf = self;
        [self.delegate whetherAcceptChannelInvitation:str completion:^(BOOL result, NSString *blockSender, NSString *blockChannel) {
            if (result) { // 接受邀请,
                if (nodeServerPort.length && nodeServerIP.length) {
                    [weakSelf disconnectManagerServerAndConnectNodeServer:nodeServerIP port:nodeServerPort];
                }else{
                    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyGS, blockSender, blockChannel];
                    [weakSelf sendString:message];
                }
            }
        }];
    }
}

// 00
- (void)handleCommonResponseData:(NSData *)data
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"__________________%@",str);
    // 如果是重新连接到频道对讲的节点服务器
    if ([SocketCommandIdentifyLD isEqualToString:str] && self.sender.length && self.channel.length ) {
        self.sender = nil;
        self.channel = nil;
        [self sendString:[NSString stringWithFormat:@"%@|%@|%@\n",SocketCommandIdentifyGM, self.sender, self.channel]];
    }else if (SocketCommandIdentifyFA){
        
        }
}
#pragma mark *************************************************异常处理******************************************************************
- (void)handleExceptionFromServer:(NSData *)data
{
    NSString *exStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"收到命令:EX----%@",exStr);
    if (data.length < 3) return;
    NSData *errorCodeData = [data subdataWithRange:NSMakeRange(1, 2)];
    NSString *errorCodeStr = [[NSString alloc] initWithData:errorCodeData encoding:NSUTF8StringEncoding];
    NSInteger errorCode = errorCodeStr.integerValue;
    __weak typeof(self) weakSelf = self;
    switch (errorCode) {
        case SocketExceptionTypeNobodyOnTalk:
            // 没人对讲
            if ([self.delegate respondsToSelector:@selector(whetherInviteOtherChannelMemeberAftercompletion:)]) {
                [self.delegate whetherInviteOtherChannelMemeberAftercompletion:^(BOOL result, NSString *blockSender, NSString *blockChannel) {
                    if (result) {
                        [weakSelf sendString:[NSString stringWithFormat:@"%@|%@|%@\n",SocketCommandIdentifyGM, blockSender, blockChannel]];
                    }
                }];
            }
            
            break;
        case SocketExceptionTypeFriendNotOnline:
            // 好友不在线
            
            [self handleResultOfInvitationFromFriend:NO andReason:@"好友不在线"];
            
            break;
            
        default:
            break;
    }
    
}



#pragma mark ***************************************************频道对讲************************************************************************
// 加入对讲
- (void)requestJoinChannelTalkback:(NSString *)channelJsonModel andFromUser:(NSString *)fromUser
{
    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyGS, fromUser, channelJsonModel];
    [self sendString:message];
}

// 退出对讲
- (void)quiteCurrentChannelTalkback:(NSString *)channelJsonModel andFromUser:(NSString *)fromUser
{
    NSString *message = [NSString stringWithFormat:@"%@|%@|%@\n", SocketCommandIdentifyEG, fromUser, channelJsonModel];
    [self sendString:message];

}



#pragma mark send package data
- (void)sendString:(NSString *)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:TimeOut tag:0];
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

- (NSMutableDictionary *)channelAudioDataDictionary
{
    if (!_channelAudioDataDictionary) {
        _channelAudioDataDictionary = [NSMutableDictionary dictionary];
    }
    return _channelAudioDataDictionary;
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
