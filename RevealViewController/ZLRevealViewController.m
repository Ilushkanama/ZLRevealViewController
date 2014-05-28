//
//  ZLRevealViewController.m
//  RevealViewControllerTest
//
//  Created by Ilya Dyakonov on 19/04/14.
//  Copyright (c) 2014 ZappyLab. All rights reserved.
//

#import <ZLCategories/UIView+ZLCConstraintsSetup.h>

#import "ZLRevealViewController.h"

/////////////////////////////////////////////////////

static NSTimeInterval const ZLRevealSidekickAnimationDuration = 0.18;
static CGFloat const ZLRevealRightSideKickWidth = 256;

/////////////////////////////////////////////////////

@interface ZLRevealViewController () <UIGestureRecognizerDelegate>

@property (readwrite) CGPoint lastPanPoint;
@property (readwrite) CGFloat lastPanDistance;

@property (strong) UIView *viewControllerContainer;
@property (strong) UIView *viewControllerContainerTapHelper;
@property (strong) UIView *rightSidekickContainer;

@property (strong) NSLayoutConstraint *viewControllerContainerPositionConstraint;

@property (strong) UIViewController *viewController;
@property (strong) UIViewController *rightSideKickController;

@end

/////////////////////////////////////////////////////

@implementation ZLRevealViewController

#pragma mark - Initialization

-(id) initWithNibName:(NSString *) nibNameOrNil
               bundle:(NSBundle *) nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil
                           bundle:nibBundleOrNil];
    if (self)
    {

    }

    return self;
}

#pragma mark - View lifecycle

-(void) viewDidLoad
{
    [super viewDidLoad];

    [self setupViewControllerContainer];
    [self setupRightSidekickContainer];
    [self addPanRecognizer];
    [self setupViewControllerContainerTapHelper];
}

-(void) setupViewControllerContainer
{
    self.viewControllerContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.viewControllerContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.viewControllerContainer];
    [self setupViewControllerContainerLayout];
    [self setupViewControllerContainerConstraints];
}

-(void) setupViewControllerContainerLayout
{
    self.viewControllerContainer.backgroundColor = [UIColor clearColor];
    self.viewControllerContainer.layer.shadowOffset = CGSizeMake(-4, 0);
    self.viewControllerContainer.layer.masksToBounds = NO;
    self.viewControllerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.viewControllerContainer.layer.shadowOpacity = 0.2;
}

-(void) setupViewControllerContainerConstraints
{
    [self bindViewControllerContainerVertically];
    [self bindViewControllerContainerWidth];
    [self fixViewControllerContainerPosition];
}

-(void) bindViewControllerContainerVertically
{
    [self.viewControllerContainer.superview ZLC_bindSubviewVertically:self.viewControllerContainer];
}

-(void) bindViewControllerContainerWidth
{
    NSLayoutConstraint *viewControllerContainerWidthConstraint = [self.viewControllerContainer ZLC_constraintForEqualWidthsWithView:self.viewControllerContainer.superview];
    [self.viewControllerContainer.superview addConstraint:viewControllerContainerWidthConstraint];
}

-(void) fixViewControllerContainerPosition
{
    self.viewControllerContainerPositionConstraint = [self.viewControllerContainer ZLC_constraintAlingningLeftEdgesWithView:self.viewControllerContainer.superview];
    [self.viewControllerContainer.superview addConstraint:self.viewControllerContainerPositionConstraint];
}

-(void) addPanRecognizer
{
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleGestureRecognizer:)];
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [self.viewControllerContainer addGestureRecognizer:panRecognizer];
}

-(void) setupViewControllerContainerTapHelper
{
    self.viewControllerContainerTapHelper = [[UIView alloc] initWithFrame:self.view.bounds];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleHelperTap)];
    [self.viewControllerContainerTapHelper addGestureRecognizer:tapRecognizer];
}

-(void) viewWillAppear:(BOOL) animated
{
    [super viewWillAppear:animated];
    [self.view bringSubviewToFront:self.viewControllerContainer];
}

#pragma mark - UIGestureRecognizerDelegate methods

-(void) handleGestureRecognizer:(UIPanGestureRecognizer *) panRecognizer
{
    CGPoint currentPanPoint = [panRecognizer locationInView:self.view];

    switch (panRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            self.lastPanPoint = currentPanPoint;
            break;

        case UIGestureRecognizerStateChanged:
            [self handlePanMoveToPoint:currentPanPoint];
            break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self handlePanFinishAtPoint:currentPanPoint];
            break;

        default:
            break;
    }
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *) gestureRecognizer
       shouldReceiveTouch:(UITouch *) touch
{
    CGPoint touchLocation = [touch locationInView:self.viewControllerContainer];
    return touchLocation.x <= 60 || touchLocation.y <= 40;

}

-(void) handlePanMoveToPoint:(CGPoint) panPoint
{
    CGFloat distance = [self calculateDistanceWithPanPoint:panPoint];
    if (distance != 0)
    {
        self.lastPanDistance = distance;

        CGFloat appContainerPosition = self.viewControllerContainerPositionConstraint.constant + distance;
        CGFloat minX = self.rightSideKickController ? -ZLRevealRightSideKickWidth : 0;
        if (appContainerPosition < minX)
        {
            appContainerPosition = minX;
        }
        else if (appContainerPosition > CGRectGetWidth(self.menuContainer.frame))
        {
            appContainerPosition = CGRectGetWidth(self.menuContainer.frame);
        }

        [self moveToPosition:appContainerPosition
                    animated:NO];

        self.lastPanPoint = panPoint;
    }
}

-(CGFloat) calculateDistanceWithPanPoint:(CGPoint) panPoint
{
    return panPoint.x - self.lastPanPoint.x;
}

-(void) handlePanFinishAtPoint:(CGPoint) finishPoint
{
    if (self.viewControllerContainerPositionConstraint.constant >= 0)
    {
        if (self.lastPanDistance >= 0)
        {
            [self showSidekick];
        }
        else
        {
            [self hideSidekick];
        }
    }
    else
    {
        if (self.lastPanDistance < 0)
        {
            [self showRightSidekick];
        }
        else
        {
            [self hideRightSidekick];
        }
    }
}

-(void) showRightSidekick
{
    [self moveToPosition:-ZLRevealRightSideKickWidth
                animated:YES];
    [self installTapHelper];
}

-(void) hideRightSidekick
{
    [self moveToPosition:0
                animated:YES];
    [self removeTapHelper];
}

-(void) handleHelperTap
{
    [self hideSidekick];
}

-(void) toggleSidekick
{
    round(self.viewControllerContainerPositionConstraint.constant) == 0
    ? [self showSidekick]
    : [self hideSidekick];
}

-(void) showSidekick
{
    [self moveToPosition:CGRectGetWidth(self.menuContainer.frame)
                animated:YES];
    [self installTapHelper];
}

-(void) installTapHelper
{
    [self.viewControllerContainer addSubview:self.viewControllerContainerTapHelper];
}

-(void) moveToPosition:(CGFloat) position
              animated:(BOOL) animated
{
    void (^moveBlock)() = ^{
        self.viewControllerContainerPositionConstraint.constant = position;
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    };

    if (animated)
    {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:[self moveAnimationDurationForPosition:position]
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:moveBlock
                         completion:nil];
    }
    else
    {
        moveBlock();
    }
}

-(NSTimeInterval) moveAnimationDurationForPosition:(CGFloat) position
{
    return ZLRevealSidekickAnimationDuration * (fabsf(position - CGRectGetMinX(self.viewControllerContainer.frame)) / CGRectGetWidth(self.menuContainer.frame));
}

-(void) hideSidekick
{
    [self moveToPosition:0
                animated:YES];
    [self removeTapHelper];
}

-(void) removeTapHelper
{
    [self.viewControllerContainerTapHelper removeFromSuperview];
}

#pragma mark - View controllers presentation

-(void) showViewController:(UIViewController *) viewController
{
    self.viewController = viewController;
    [self showViewController:viewController
                 inContainer:self.viewControllerContainer];
}

-(void) showViewController:(UIViewController *) viewController
               inContainer:(UIView *) container
{
    [self removeViewOfViewController:viewController];
    [self addViewOfViewController:viewController
                      toContainer:container];
    [self setupViewOfViewControllerToBeDisplayed:viewController];
}

-(void) removeViewOfViewController:(UIViewController *) viewController
{
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
}

-(void) addViewOfViewController:(UIViewController *) viewController
                    toContainer:(UIView *) container
{
    [self addChildViewController:viewController];
    [container addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

-(void) setupViewOfViewControllerToBeDisplayed:(UIViewController *) viewController
{
    [self setupConstraintsForViewController];
    [viewController.view setNeedsLayout];
    [viewController.view layoutIfNeeded];
}

-(void) setupConstraintsForViewController
{
    [self.viewController.view.superview ZLC_bindSubviewHorizontally:self.viewController.view];
    [self.viewController.view.superview ZLC_bindSubviewVertically:self.viewController.view];
}

#pragma mark - Right sidekick

-(void) setupRightSidekickContainer
{
    self.rightSidekickContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.rightSidekickContainer.backgroundColor = [UIColor blackColor];
    self.rightSidekickContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rightSidekickContainer];
    [self setupRightSidekickConstraints];
}

-(void) setupRightSidekickConstraints
{
    [self.rightSidekickContainer.superview ZLC_bindSubviewVertically:self.rightSidekickContainer];
    [self.rightSidekickContainer ZLC_bindWidth:ZLRevealRightSideKickWidth];

    NSLayoutConstraint *rightSidekickPositionConstraint = [self.rightSidekickContainer ZLC_constraintAligningLeftEdgeWithRightEdgeOfView:self.viewControllerContainer];
    [self.rightSidekickContainer.superview addConstraint:rightSidekickPositionConstraint];
}

-(void) showRightSidekickController:(UIViewController *) viewController
{
    self.rightSideKickController = viewController;
    [self showViewController:viewController
                 inContainer:self.rightSidekickContainer];
}

@end

/////////////////////////////////////////////////////
