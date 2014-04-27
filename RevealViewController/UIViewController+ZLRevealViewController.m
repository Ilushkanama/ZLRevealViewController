//
//  UIViewController+ZLRevealViewController.m
//  RevealViewControllerTest
//
//  Created by Ilya Dyakonov on 27/04/14.
//  Copyright (c) 2014 ZappyLab. All rights reserved.
//

#import "UIViewController+ZLRevealViewController.h"

#import "ZLRevealViewController.h"

/////////////////////////////////////////////////////

@implementation UIViewController (ZLRevealViewController)

-(void) toggleRevealSidekick
{
    [[self revealViewController] toggleSidekick];
}

-(ZLRevealViewController *) revealViewController
{
    id presentingViewController = self.presentingViewController;
    while (presentingViewController) {
        if ([presentingViewController isKindOfClass:[ZLRevealViewController class]]) {
            break;
        }
    }
    
    return presentingViewController;
}

@end

/////////////////////////////////////////////////////
