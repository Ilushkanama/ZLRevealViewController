//
//  ViewController.m
//  RevealViewControllerTest
//
//  Created by Ilya Dyakonov on 19/04/14.
//  Copyright (c) 2014 ZappyLab. All rights reserved.
//

#import "ViewController.h"

/////////////////////////////////////////////////////

@interface ViewController ()

@end

/////////////////////////////////////////////////////

@implementation ViewController

#pragma mark -

-(void) viewDidLoad
{
    [super viewDidLoad];

    UIViewController *childViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                             instantiateViewControllerWithIdentifier:@"ChildViewController"];
    [self showViewController:childViewController];

    UIViewController *rightSidekickController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil]
                                                               instantiateViewControllerWithIdentifier:@"RightSidekickController"];
    rightSidekickController.view.backgroundColor = [UIColor redColor];
    [self showRightSidekickController:rightSidekickController];

//    [self showSidekick];
}

@end

/////////////////////////////////////////////////////
