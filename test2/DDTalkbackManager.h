//
//  DDTalkbackManager.h
//  test2
//
//  Created by 刘健 on 16/7/9.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    TalkbackTypeFriend = 1,
    TalkbackTypeChannel,
} TalkbackType;

typedef void(^goodFriendInviteResultBlock)(BOOL result, NSString *blockFromUser, NSString *blockToUserID);
typedef void (^channelInviteResultBlock)(BOOL result, NSString *blockToUser, NSString *blockFromChannel);
typedef void (^channelCallback)(BOOL result, NSString *blockSender, NSString *blockChannel);
@protocol DDTalkbackManagerDelegate  <NSObject>
@required

/**
 *  收到好友对讲邀请后的操作
 *
 *  @param fromUser   好友的json对象
 *  @param callback 待用户选择 接受 或 拒绝 后的回调块
 */
- (void)whetherAcceptFriendInvitation:(NSString *)fromUser completion:(goodFriendInviteResultBlock)callback;

/**
 *  进入频道时,没人对讲,是否邀请频道成员进行对讲回调块
 *
 *  @param result 是否邀请
 *  @param blocksender 发送邀请的对象json
 *  @param bolcKChannel 向哪个频道发送
 */
- (void)whetherInviteOtherChannelMemeberAftercompletion:(channelCallback)callback;

/**
 *  收到频道对讲邀请
 *
 *  @param result 是否接受邀请
 *  @param blocksender 发送邀请对象
 *  @param bolcKChannel 向哪个频道发送
 *  @param callback 用户选择回调块{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
 */
- (void)whetherAcceptChannelInvitation:(NSString *)channel completion:(channelCallback)callback;


@end

@interface DDTalkbackManager : NSObject

@property (nonatomic, strong) id<DDTalkbackManagerDelegate> delegate;

+ (instancetype)sharedInstance;

/**
 *  发送语音数据
 *
 *  @param audioData 音频数据
 *  @param senderid  发送者id
 *  @param type      目标类型,好友 频道
 */
- (void)sendAudioData:(NSData *)audioData andSenderID:(NSString *)senderid withTalkbackType:(TalkbackType)type;
/**
 ********************************************好友对讲************************************************************************************
 */

/**
 *  邀请好友进行对讲 FS|发起者对象|接收者ID FS|{"userid":"user10300","username","张鹏飞"}|user10200
 *
 *  @param fromUser 邀请对象的json字符串
 *  @param toUserID 被邀请对象ID
 */
- (void)inviteGoodFriendTalkbackFromUser:(NSString *)fromUser toUserID:(NSString *)toUserID;

/**
 *  拒绝好友邀请 FR|发送者对象|接收者ID FR|{"userid":"user10200","username":"user10200"}|user10300
 *
 *  @param toUserID 被拒绝的好友id
 *  @param fromUser 用户json对象
 */
- (void)refuseTalkbackInvitationOfFriendID:(NSString *)toUserID fromUser:(NSString *)fromUser;


/**
 *  主动退出和好友的连接 ED|发起者对象 e.g:ED|{"userid":"user10300","username":"user10300"}
 *
 *  @param fromUser json对象
 *  @param toUserid 被断开者的id
 */
- (void)disconnectTalkback:(NSString *)fromUser WithUserID:(NSString *)toUserid;


/**
 ********************************************频道对讲************************************************************************************
 */
/**
 *  发出进入频道对讲的指令，目标node服务器；协议：GS|发起者对象|频道对象
 *  e.g:GS|{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
 *
 *  @param channelJsonModel 频道json对象
 *  @param fromUser         申请者的json对象
 */
- (void)requestJoinChannelTalkback:(NSString *)channelJsonModel andFromUser:(NSString *)fromUser;


/**
 *  发出退出指令，目标node服务器；协议：EG|退出者对象|频道对象
 *  e.g:EG|{"userid":"user10300","username":"我是大魔王"}|{"groupId":"10060","groupName":"飙车俱乐部"}
 *
 *  @param channelJsonModel 频道Json对象
 *  @param fromUser         退出者对象
 */
- (void)quiteCurrentChannelTalkback:(NSString *)channelJsonModel andFromUser:(NSString *)fromUser;

@end
