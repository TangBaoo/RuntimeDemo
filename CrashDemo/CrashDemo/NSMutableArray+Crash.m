//
//  NSMuableArray+Crash.m
//  CrashDemo
//
//  Created by 灌汤包的大蒸笼 on 2017/7/27.
//  Copyright © 2017年 灌汤包的大蒸笼. All rights reserved.
//

#import "NSMutableArray+Crash.h"
#import <objc/runtime.h>

#define AvoidCrashSeparator         @"================================================================"
#define AvoidCrashSeparatorWithFlag @"========================AvoidCrash Log=========================="
#define AvoidCrashDefaultIgnore     @"This framework default is to ignore this operation to avoid crash."

#define key_errorName        @"errorName"
#define key_errorReason      @"errorReason"
#define key_errorPlace       @"errorPlace"
#define key_defaultToDo      @"defaultToDo"
#define key_callStackSymbols @"callStackSymbols"
#define key_exception        @"exception"

@implementation NSMutableArray (Crash)

+(void)load
{
    // 执行一次.
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Class muArrayClass = NSClassFromString(@"__NSArrayM");
        SEL originalMethodSel = @selector(setObject:atIndexedSubscript:);
        SEL swizzledMethodSel = @selector(KsetObject:atIndexedSubscript:);
        
        Method originalMethod = class_getInstanceMethod(muArrayClass, originalMethodSel);
        Method swizzledMethod = class_getInstanceMethod(muArrayClass, swizzledMethodSel);
        
        BOOL didAddMethod =
        class_addMethod(muArrayClass,
                        originalMethodSel,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(muArrayClass,
                                originalMethodSel,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        }
        
        else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    });
}


- (void)KsetObject:(id)object atIndexedSubscript:(NSInteger)index{
    
    
    // 可能crash的方法,并且获取crash的信息
    @try {
        // 因为交换过方法,所以在此调用这个其实是调用的系统原先的方法.
        [self KsetObject:object atIndexedSubscript:index];
    } @catch (NSException *exception) {
        [self noteErrorWithException:exception defaultToDo:AvoidCrashDefaultIgnore];
    } @finally {
        
        // 这里面的代码一定会执行.
    }
    
}

/**
 *  获取堆栈主要崩溃精简化的信息<根据正则表达式匹配出来>
 *
 *  @param callStackSymbols 堆栈主要崩溃信息
 *
 *  @return 堆栈主要崩溃精简化的信息
 */

- (NSString *)getMainCallStackSymbolMessageWithCallStackSymbols:(NSArray<NSString *> *)callStackSymbols {
    
    //mainCallStackSymbolMsg的格式为   +[类名 方法名]  或者 -[类名 方法名]
    __block NSString *mainCallStackSymbolMsg = nil;
    
    //匹配出来的格式为 +[类名 方法名]  或者 -[类名 方法名]
    NSString *regularExpStr = @"[-\\+]\\[.+\\]";
    
    
    NSRegularExpression *regularExp = [[NSRegularExpression alloc] initWithPattern:regularExpStr options:NSRegularExpressionCaseInsensitive error:nil];
    
    
    for (int index = 2; index < callStackSymbols.count; index++) {
        NSString *callStackSymbol = callStackSymbols[index];
        
        [regularExp enumerateMatchesInString:callStackSymbol options:NSMatchingReportProgress range:NSMakeRange(0, callStackSymbol.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
            if (result) {
                NSString* tempCallStackSymbolMsg = [callStackSymbol substringWithRange:result.range];
                
                //get className
                NSString *className = [tempCallStackSymbolMsg componentsSeparatedByString:@" "].firstObject;
                className = [className componentsSeparatedByString:@"["].lastObject;
                
                NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(className)];
                
                //filter category and system class
                if (![className hasSuffix:@")"] && bundle == [NSBundle mainBundle]) {
                    mainCallStackSymbolMsg = tempCallStackSymbolMsg;
                    
                }
                *stop = YES;
            }
        }];
        
        if (mainCallStackSymbolMsg.length) {
            break;
        }
    }
    
    return mainCallStackSymbolMsg;
}


/**
 *  提示崩溃的信息(控制台输出、通知)
 *
 *  @param exception   捕获到的异常
 *  @param defaultToDo 这个框架里默认的做法
 */
- (void)noteErrorWithException:(NSException *)exception defaultToDo:(NSString *)defaultToDo {
    
    //堆栈数据
    NSArray *callStackSymbolsArr = [NSThread callStackSymbols];
    
    //获取在哪个类的哪个方法中实例化的数组  字符串格式 -[类名 方法名]  或者 +[类名 方法名]
    NSString *mainCallStackSymbolMsg = [self getMainCallStackSymbolMessageWithCallStackSymbols:callStackSymbolsArr];
    
    if (mainCallStackSymbolMsg == nil) {
        
        mainCallStackSymbolMsg = @"崩溃方法定位失败,请您查看函数调用栈来排查错误原因";
        
    }
    
    NSString *errorName = exception.name;
    NSString *errorReason = exception.reason;
    //errorReason 可能为 -[__NSCFConstantString avoidCrashCharacterAtIndex:]: Range or index out of bounds
    //将avoidCrash去掉
    errorReason = [errorReason stringByReplacingOccurrencesOfString:@"avoidCrash" withString:@""];
    
    NSString *errorPlace = [NSString stringWithFormat:@"Error Place:%@",mainCallStackSymbolMsg];
    
    NSDictionary *errorInfoDic = @{
                                   key_errorName        : errorName,
                                   key_errorReason      : errorReason,
                                   key_errorPlace       : errorPlace,
                                   key_defaultToDo      : defaultToDo,
                                   key_exception        : exception,
                                   key_callStackSymbols : callStackSymbolsArr
                                   };
    
    //将错误信息放在字典里，用通知的形式发送出去
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"%@",errorInfoDic);
    });
    
    
}


@end
