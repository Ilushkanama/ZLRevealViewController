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

-(ZLRevealViewController *) revealViewController
{
    ZLRevealViewController *viewController = [self findPresentingRevealViewController];
    if (!viewController) {
        viewController = [self findParentRevealViewController];
    }

    return viewController;
}

-(ZLRevealViewController *) findPresentingRevealViewController
{
    UIViewController *viewController = self;
    while (viewController) {
        if ([viewController isKindOfClass:[ZLRevealViewController class]]) {
            break;
        }

        viewController = viewController.presentingViewController;
    }
    return (ZLRevealViewController *) viewController;
}

-(ZLRevealViewController *) findParentRevealViewController
{
    UIViewController *viewController = self;
    while (viewController) {
        if ([viewController isKindOfClass:[ZLRevealViewController class]]) {
            break;
        }

        viewController = viewController.parentViewController;
    }
    return (ZLRevealViewController *) viewController;
}


@end

/////////////////////////////////////////////////////
