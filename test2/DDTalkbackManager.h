//
//  DDTalkbackManager.h
//  test2
//
//  Created by 刘健 on 16/7/9.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^goodFriendInviteResultBlock)(BOOL result, NSString *blockFromUser, NSString *blockToUserID);

@protocol DDTalkbackManagerDelegate  <NSObject>
@required

/**
 *  收到好友对讲邀请后的操作
 *
 *  @param fromUser   好友的json对象
 *  @param callback 待用户选择 接受 或 拒绝 后的回调块
 */
- (void)whetherAcceptFriendInvitation:(NSString *)fromUser completion:(goodFriendInviteResultBlock)callback;


@end

@interface DDTalkbackManager : NSObject

@property (nonatomic, strong) id<DDTalkbackManagerDelegate> delegate;

+ (instancetype)sharedInstance;


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
 *  给好友发送音频数据 e.g:SM|语音部分的字节数|二进制语音|说话者userId
 *
 *  @param audioData 音频数据
 *  @param IDStr     目标id
 */
- (void)sendAudioData:(NSData *)audioData toUserID:(NSString *)userid;

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

//- (void)

@end
