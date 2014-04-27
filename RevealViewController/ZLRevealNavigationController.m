//
// Created by Ilya Dyakonov on 28/11/13.
// Copyright (c) 2013 ZappyLab. All rights reserved.
//
//


#import "ZLRevealNavigationController.h"

#import "UIViewController+ZLRevealViewController.h"

/////////////////////////////////////////////////////

@interface ZLRevealNavigationController ()

@end

/////////////////////////////////////////////////////

@implementation ZLRevealNavigationController

#pragma mark - Class methods

static NSString *sidekickButtonImageName;

+(void) setSidekickButtonImageName:(NSString *) imageName
{
    sidekickButtonImageName = imageName;
}

#pragma mark - Accessors

-(void) setViewControllers:(NSArray *) viewControllers
{
    [super setViewControllers:viewControllers];
    [self setupSidekickButton];
}

#pragma mark - Initializations

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self setupSidekickButton];
}

-(id) initWithNibName:(NSString *) nibNameOrNil
               bundle:(NSBundle *) nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self) {

    }

    return self;
}

-(id) initWithRootViewController:(UIViewController *) rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        [self setupSidekickButton];
    }

    return self;
}

-(void) setupSidekickButton
{
    UINavigationItem *rootViewControllerNavigationItem = [[self.viewControllers firstObject] navigationItem];
    UIBarButtonItem *sidekickButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:sidekickButtonImageName]
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(toggleRevealSidekick)];
    rootViewControllerNavigationItem.leftBarButtonItem = sidekickButton;
}

@end

/////////////////////////////////////////////////////
