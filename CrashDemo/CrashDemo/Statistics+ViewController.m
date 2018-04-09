//
//  Statistics+ViewController.m
//  CrashDemo
//
//  Created by 灌汤包的大蒸笼 on 2017/7/27.
//  Copyright © 2017年 灌汤包的大蒸笼. All rights reserved.
//

#import "Statistics+ViewController.h"
#import <objc/runtime.h>

@implementation UIViewController (Statistics)


+(void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Method originalMethod = class_getInstanceMethod([self class], @selector(viewWillAppear:));
        Method swizzledMethod = class_getInstanceMethod([self class], @selector(KviewWillAppear:));
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
        
    });
}

- (void)KviewWillAppear:(BOOL)animated
{
    [self KviewWillAppear:animated];
    NSLog(@"进入%@",[self class]);
}

@end
