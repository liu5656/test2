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

- (void)sendAudioData:(NSData *)audioData toUserIDOrChannelID:(NSString *)IDStr;

@end
