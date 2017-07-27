//
//  DJ+TableView.m
//  CrashDemo
//
//  Created by 灌汤包的大蒸笼 on 2017/7/27.
//  Copyright © 2017年 灌汤包的大蒸笼. All rights reserved.
//

#import "DJ+TableView.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation UITableView (DJ_TableView)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Method originalMethod = class_getInstanceMethod(self, @selector(setDelegate:));
        Method swizzledMethod = class_getInstanceMethod(self, @selector(DJsetDelegate:));
        
        BOOL didAddMethod =
        class_addMethod(self,
                        @selector(setDelegate:),
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(self,
                                @selector(DJsetDelegate:),
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
    
}

- (void)DJsetDelegate:(id<UITableViewDelegate>)delegate
{
    [self DJsetDelegate:delegate];
    
    if (class_addMethod([delegate class], NSSelectorFromString(@"DJdidSelectRowAtIndexPath"), (IMP)DJdidSelectRowAtIndexPath, "v@:@@")) {
        Method didSelectOriginalMethod = class_getInstanceMethod([delegate class], NSSelectorFromString(@"DJdidSelectRowAtIndexPath"));
        Method didSelectSwizzledMethod = class_getInstanceMethod([delegate class], @selector(tableView:didSelectRowAtIndexPath:));
        
        method_exchangeImplementations(didSelectOriginalMethod, didSelectSwizzledMethod);
    }
    
}

void DJdidSelectRowAtIndexPath(id self, SEL _cmd, id tableView, id indexPath)
{
    SEL selector = NSSelectorFromString(@"DJdidSelectRowAtIndexPath");
    ((void(*)(id, SEL, id, id))objc_msgSend)(self, selector, tableView, indexPath);
    NSLog(@"点击了");
}

@end
