//
//  MessageData.m
//  test2
//
//  Created by lj on 16/7/11.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "MessageData.h"

#import "GCDAsyncSocket.h"

@implementation MessageData


//- (void)test4:(NSData *)data andSocket:(GCDAsyncSocket *)sock
//{
//    
//    NSLog(@"循环之前的数据长度:%ld",data.length);
//    
//    // 黏包
//    if (self.leftData.length) {
//        NSMutableData *tempData = [NSMutableData dataWithData:self.leftData];
//        [tempData appendData:data];
//        data = [NSData dataWithData:tempData];
//        self.leftData = nil;
//    }
//    
//    NSData *useridData = nil;
//    NSInteger offset = 0;
//    do{
//        if (data.length < (offset + 2)) {
//            offset -= 2;
//            break;
//        }
//        NSData *messageTypeData = [data subdataWithRange:NSMakeRange(offset, 2)];
//        NSString *messageTypeStr = [[NSString alloc] initWithData:messageTypeData encoding:NSUTF8StringEncoding];
//        // 偏移量指向包长度字节开始位置
//        offset += 2;
//        
//        if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到音频数据
//            // 取数据前判断
//            if (data.length < (offset + 4)) {
//                offset -= 2;
//                break;
//            }
//            NSInteger currentAudioLength = convertDataToInt([data subdataWithRange:NSMakeRange(offset, 4)]);
//            // 偏移量指向音频包内容开始位置
//            offset += 4;
//            
//            if (data.length < (offset + currentAudioLength)){
//                offset -= 6;
//                break;
//            }
//            [self.audioData appendData:[data subdataWithRange:NSMakeRange(offset, currentAudioLength)]];
//            
//            // 偏移量指向userid开始位置
//            offset += currentAudioLength;
//            
//            NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSASCIIStringEncoding] options:1 range:NSMakeRange(offset, data.length - offset)];
//            if (range.location != NSNotFound) {
//                useridData = [data subdataWithRange:NSMakeRange(offset, range.location - offset)];
//                NSString *str = [[NSString alloc] initWithData:useridData encoding:NSUTF8StringEncoding];
//                NSLog(@"发送者的id:%@",str);
//            }else{
//                offset -= (currentAudioLength + 4 + 2);
//                break; // 没找到userid,就跳出去,并保留当前剩下的data
//            }
//            
//            offset += (useridData.length + 1); // 加1是为了跨过换行符
//            
//        }else if ([SocketCommandIdentifyET isEqualToString:messageTypeStr]) { // 音频结束
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//            
//            NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"xxx.mp3"];
//            BOOL result = [self.audioData writeToFile:path atomically:YES];
//            if (result) {
//                NSLog(@"创建文件成功:%@",path);
//            }else{
//                NSLog(@"创建文件失败");
//            }
//            self.audioData = nil;
//            
//        }else if ([SocketCommandIdentifyAB isEqualToString:messageTypeStr]) { // 管理服务器回复
//            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            
//            NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//            [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
//            NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentifyAC isEqualToString:messageTypeStr]) { // 连接管理服务器回复
//            NSLog(@"收到命令:AC");
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentifyCK isEqualToString:messageTypeStr]) { // 心跳包回复
//            NSLog(@"收到命令:CK");
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentifyFN isEqualToString:messageTypeStr]) { // 收到好友发出对讲请求
//            NSLog(@"收到命令:FN");
//            
//            NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//            [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
//            
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentifyED isEqualToString:messageTypeStr]) { // 断开和好友的对讲回复
//            NSLog(@"收到命令:ED");
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
//            NSLog(@"收到命令:EX");
//            NSData *tempData = [self offset:data andOffset:&offset];
//            if (tempData.length == 0) break;
//        }else{
//            [self.clientSocket readDataWithTimeout:-1 tag:0];
//            return;
//        }
//    } while (data.length - offset  > 1);
//    
//    // 存包
//    if (data.length - offset > 1) {
//        self.leftData = [NSMutableData dataWithData:[data subdataWithRange:NSMakeRange(offset, data.length - offset)]];
//    }
//    [self.clientSocket readDataWithTimeout:-1 tag:0];
//    NSLog(@"while之后解包次数%d",_number);
//    
//}
//
//- (void)test3:(NSData *)data andSocket:(GCDAsyncSocket *)sock
//{
//    [self.clientSocket readDataWithTimeout:-1 tag:0];
//    NSData *messageTypeData = [data subdataWithRange:NSMakeRange(0, 2)];
//    NSString *messageTypeStr = [[NSString alloc] initWithData:messageTypeData encoding:NSUTF8StringEncoding];
//    /*
//     ****************************************************音频****************************************************************************
//     */
//    
//    NSInteger offset = 0;
//    if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到音频数据
//        //        NSInteger totalLength = convertDataToInt([data subdataWithRange:NSMakeRange(2, 4)]);
//        //        NSData *currentAudioData = [data subdataWithRange:NSMakeRange(6, totalLength)];
//        //        [self.audioData appendData:currentAudioData];
//        //        _useridData = [data subdataWithRange:NSMakeRange(totalLength + 6, data.length - totalLength - 6)];
//        //
//        //        NSLog(@"收到%@音频包,长度%ld",[[NSString alloc] initWithData:_useridData encoding:NSUTF8StringEncoding], totalLength);
//        
//        
//        
//        
//        NSData *useridData = nil;
//        
//        do{
//            // 偏移量指向包长度字节开始位置
//            offset += 2;
//            NSInteger currentAudioLength = convertDataToInt([data subdataWithRange:NSMakeRange(offset, 4)]);
//            // 偏移量指向音频包内容开始位置
//            offset += 4;
//            [self.audioData appendData:[data subdataWithRange:NSMakeRange(offset, currentAudioLength)]];
//            // 偏移量指向userid开始位置
//            offset += currentAudioLength;
//            NSRange range = [data rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchAnchored range:NSMakeRange(offset, data.length - offset - 1)];
//            if (range.location != NSNotFound) {
//                useridData = [data subdataWithRange:NSMakeRange(offset, range.location - offset)];
//            }
//            
//            offset += (useridData.length + 1); // 加1是为了跨过换行符
//            
//            if ((data.length - offset) > 2) {
//                NSRange commandRange = NSMakeRange(offset, 2);
//                NSData *commandData = [data subdataWithRange:commandRange];
//                messageTypeStr = [[NSString alloc] initWithData:commandData encoding:NSUTF8StringEncoding];
//            }
//            
//            
//        } while ([messageTypeStr isEqualToString:SocketCommandIdentifySM]);
//        
//        
//        
//        
//        
//        
//        
//    }else if ([SocketCommandIdentifyET isEqualToString:messageTypeStr]) { // 音频结束
//        NSLog(@"结束收音乐包,开始创建文件");
//        
//        NSString *useridStr = [[NSString alloc] initWithData:_useridData encoding:NSUTF8StringEncoding];
//        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:useridStr];
//        BOOL result = [self.audioData writeToFile:path atomically:YES];
//        if (result) {
//            NSLog(@"创建文件成功:%@",path);
//        }else{
//            NSLog(@"创建文件失败");
//        }
//        self.audioData = nil;
//        
//        /*
//         ****************************************************其他****************************************************************************
//         */
//        
//    }else if ([SocketCommandIdentifyAB isEqualToString:messageTypeStr]) { // 管理服务器回复
//        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//        [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
//    }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
//        NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//    }else if ([SocketCommandIdentifyAC isEqualToString:messageTypeStr]) { // 连接管理服务器回复
//        NSLog(@"收到命令:AC");
//    }else if ([SocketCommandIdentifyCK isEqualToString:messageTypeStr]) { // 心跳包回复
//        NSLog(@"收到命令:CK");
//    }else if ([SocketCommandIdentifyFN isEqualToString:messageTypeStr]) { // 收到好友发出对讲请求
//        NSLog(@"收到命令:FN");
//        
//        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//        [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
//        
//        
//    }else if ([SocketCommandIdentifyED isEqualToString:messageTypeStr]) { // 断开和好友的对讲回复
//        NSLog(@"收到命令:ED");
//    }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
//        NSLog(@"收到命令:EX");
//    }else{ // 丢弃
//        
//    }
//    
//    self.SMData = nil;
//    
//}
//
//- (void)test2:(NSData *)data andSocket:(GCDAsyncSocket *)sock
//{
//    [self.clientSocket readDataWithTimeout:-1 tag:0];
//    // 黏包
//    if (self.leftData.length) {
//        NSMutableData *tempData = [NSMutableData dataWithData:self.leftData];
//        [tempData appendData:data];
//        data = [NSData dataWithData:tempData];
//        self.leftData = nil;
//    }
//    
//    
//    // 直到大于2
//    [self.SMData appendData:data];
//    if(self.SMData.length < 2) {
//        return;
//    }
//    
//    NSData *messageTypeData = [self.SMData subdataWithRange:NSMakeRange(0, 2)];
//    NSString *messageTypeStr = [[NSString alloc] initWithData:messageTypeData encoding:NSUTF8StringEncoding];
//    /*
//     ****************************************************音频****************************************************************************
//     */
//    if ([SocketCommandIdentifySM isEqualToString:messageTypeStr]) { // 收到音频数据
//        NSLog(@"收到命令:%@------当前收到的包的长度:%ld",messageTypeStr, data.length);
//        NSInteger totalLength = 0;
//        NSData *audioData = nil;
//        NSData *useridData = nil;
//        if (self.SMData.length < 6) {
//            return;
//        }
//        
//        NSData *totalLengthData = [self.SMData subdataWithRange:NSMakeRange(2, 4)];
//        totalLength = convertDataToInt(totalLengthData);
//        
//        if (self.SMData.length < (totalLength + 6)) {
//            return;
//        }else{
//            audioData = [self.SMData subdataWithRange:NSMakeRange(6, totalLength)];
//        }
//        
//        // 找到音频数据结束后的换行符的range
//        NSRange range = [self.SMData rangeOfData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding] options:NSDataSearchBackwards range:NSMakeRange(totalLength + 6, self.SMData.length - totalLength - 6)];
//        if (range.location != NSNotFound) {
//            // 拿到userid
//            useridData = [self.SMData subdataWithRange:NSMakeRange(totalLength + 6, range.location - (totalLength + 6) - 1)];
//        }else{
//            return;
//        }
//        
//        NSString *useridStr = [[NSString alloc] initWithData:useridData encoding:NSUTF8StringEncoding];
//        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:useridStr];
//        BOOL result = [audioData writeToFile:path atomically:YES];
//        if (result) {
//            NSLog(@"创建文件成功:%@",path);
//        }else{
//            NSLog(@"创建文件失败");
//        }
//        
//        self.leftData = [self.SMData subdataWithRange:NSMakeRange(range.location + 1, self.SMData.length - (range.location + range.length - 1) )];
//        self.SMData = nil;
//        
//        /*
//         ****************************************************其他****************************************************************************
//         */
//        
//    }else if ([SocketCommandIdentifyAB isEqualToString:messageTypeStr]) { // 管理服务器回复
//        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//        [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
//    }else if ([SocketCommandIdentify00 isEqualToString:messageTypeStr]) { // 其他回复
//        NSLog(@"收到命令:00--%@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//    }else if ([SocketCommandIdentifyAC isEqualToString:messageTypeStr]) { // 连接管理服务器回复
//        NSLog(@"收到命令:AC");
//    }else if ([SocketCommandIdentifyCK isEqualToString:messageTypeStr]) { // 心跳包回复
//        NSLog(@"收到命令:CK");
//    }else if ([SocketCommandIdentifyFN isEqualToString:messageTypeStr]) { // 收到好友发出对讲请求
//        NSLog(@"收到命令:FN");
//        
//        NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//        [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
//        
//        
//    }else if ([SocketCommandIdentifyED isEqualToString:messageTypeStr]) { // 断开和好友的对讲回复
//        NSLog(@"收到命令:ED");
//    }else if ([SocketCommandIdentifyEX isEqualToString:messageTypeStr]) { // 异常
//        NSLog(@"收到命令:EX");
//    }else{ // 丢弃
//        
//    }
//    
//    self.SMData = nil;
//    
//}
//
//
//- (void)test:(NSData *)data andSocket:(GCDAsyncSocket *)sock
//{
//    /*
//     ************************************************************************************************************************************
//     */
//    
//    
//    NSString *dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"has received data:%@",dataStr);
//    NSLog(@"包长度:%ld",data.length);
//    NSArray *tempArray = [dataStr componentsSeparatedByString:@"|"];
//    
//    // 收到管理服务器发送的00|AC
//    if ([sock.connectedHost isEqualToString:SocketManagerServerIP] && [SocketCommandIdentifyAB isEqualToString:tempArray.firstObject]) {
//        [self disconnectManagerServerAndConnectNodeServer:tempArray[1] port:tempArray.lastObject];
//        return;
//    }
//    
//    NSString *firstInstruction = tempArray.firstObject;
//    
//    // 处理音频数据
//    if ([SocketCommandIdentifySM isEqualToString:firstInstruction] || [SocketCommandIdentifySG isEqualToString:firstInstruction]) { // 接收到对好友说出的音频数据
//        [self handleReceivedAudioData:data];
//        [self.clientSocket readDataWithTimeout:-1 tag:0];
//        return;
//    }
//    
//    // 处理普通指令
//    if ([@"00" isEqualToString:firstInstruction]) {
//        if (1 < tempArray.count) {
//            NSString *commandStr = tempArray[1];
//            if ([commandStr isEqualToString:SocketCommandIdentifyAC]) {
//                
//            }else if ([commandStr isEqualToString:SocketCommandIdentifyCK]) {
//                
//            }else if ([commandStr isEqualToString:SocketCommandIdentifySM]) {
//                //                NSLog(@"message has sended");
//                
//            }else if ([commandStr isEqualToString:SocketCommandIdentifyFN]) { // 收到好友发出对讲请求
//                [self acceptGoodFriendInviteFromUserID:tempArray[1] toUserID:tempArray.lastObject];
//            }else if ([commandStr isEqualToString:SocketCommandIdentifyED]) {
//                NSLog(@"好友已经断开和你的对讲连接");
//            }
//        }
//        
//    }else{ // 处理异常
//        if (1 < tempArray.count) {
//            NSString *errorNum = tempArray[1];
//            NSString *responseStr = nil;
//            if ([errorNum isEqualToString:@"90"]) {
//                responseStr = @"好友不在线";
//            }
//        }
//    }
//    [self.clientSocket readDataWithTimeout:-1 tag:0];
//    
//}



@end
