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
- (BOOL)whetherAcceptFriendInvitation:(NSString *)userid completion:(goodFriendInviteResultBlock)callback;


@end

@interface DDTalkbackManager : NSObject

@property (nonatomic, strong) id<DDTalkbackManagerDelegate> delegate;

+ (instancetype)sharedInstance;

/**
 *  邀请好友进行对讲
 *
 *  @param fromUser 邀请对象的json字符串
 *  @param toUserID 被邀请对象ID
 */
- (void)inviteGoodFriendTalkbackFromUser:(NSString *)fromUser toUserID:(NSString *)toUserID;

/**
 *  拒绝好友邀请
 *
 *  @param toUserID 被拒绝的好友id
 *  @param fromUser 用户json对象
 */
- (void)refuseTalkbackInvitationOfFriendID:(NSString *)toUserID fromUser:(NSString *)fromUser;

/**
 *  给好友发送音频数据
 *
 *  @param audioData 音频数据
 *  @param IDStr     目标id
 */
- (void)sendAudioData:(NSData *)audioData toUserID:(NSString *)userid;

/**
 *  主动断开和好友的连接
 *
 *  @param fromUser json对象
 *  @param toUserid 被断开者的id
 */
- (void)disconnectTalkback:(NSString *)fromUser WithUserID:(NSString *)toUserid;

@end
