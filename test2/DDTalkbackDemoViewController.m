//
//  DDTalkbackDemoViewController.m
//  test2
//
//  Created by 刘健 on 16/7/11.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "DDTalkbackDemoViewController.h"

#import "DDTalkbackManager.h"

@interface DDTalkbackDemoViewController ()

@property (nonatomic, strong) DDTalkbackManager *talkbackManager;

@end

@implementation DDTalkbackDemoViewController
- (IBAction)inviteFriendAction:(UIButton *)sender {
    [[DDTalkbackManager sharedInstance] inviteGoodFriendTalkbackFromUser:@"{\"userid\":\"user10058\",\"username\",\"zhangpengfei\"}" toUserID:@"user10100"];
}
- (IBAction)startSendAudioAction:(UIButton *)sender {
}
- (IBAction)endSendAudioAction:(UIButton *)sender {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.talkbackManager = [DDTalkbackManager sharedInstance];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
