//
//  NSString+Model.m
//  test2
//
//  Created by lj on 16/7/13.
//  Copyright © 2016年 Chengdu Chezhilian Technology Co., Ltd. All rights reserved.
//

#import "NSString+Model.h"

@implementation NSString (Model)
- (NSDictionary *)toDictionary
{
    NSData *data = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        return nil;
    }else{
        return dictionary;
    }
}

- (NSData *)toData
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

@end
