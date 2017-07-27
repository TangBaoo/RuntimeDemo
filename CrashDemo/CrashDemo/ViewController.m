//
//  ViewController.m
//  CrashDemo
//
//  Created by 灌汤包的大蒸笼 on 2017/7/27.
//  Copyright © 2017年 灌汤包的大蒸笼. All rights reserved.
//

#import "ViewController.h"
#import "SecViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // 数组越界演示
    /*
    NSMutableArray *muArray = [NSMutableArray new];
    [muArray setObject:@"crash" atIndexedSubscript:1];
    */
    
    
    UIButton *pushBt = [UIButton buttonWithType:UIButtonTypeCustom];
    pushBt.frame = CGRectMake(100, 300, 100, 40);
    pushBt.backgroundColor = [UIColor brownColor];
    [pushBt addTarget:self action:@selector(pushView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pushBt];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)pushView
{
    SecViewController *vc = [[SecViewController alloc] init];
    [self presentViewController:vc animated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
