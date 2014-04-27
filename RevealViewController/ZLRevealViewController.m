//
//  ZLRevealViewController.m
//  RevealViewControllerTest
//
//  Created by Ilya Dyakonov on 19/04/14.
//  Copyright (c) 2014 ZappyLab. All rights reserved.
//

#import "ZLRevealViewController.h"

/////////////////////////////////////////////////////

static NSTimeInterval const ZLRevealSidekickAnimationDuration = 0.18;

/////////////////////////////////////////////////////

@interface ZLRevealViewController () <UIGestureRecognizerDelegate>

@property (strong) UIPanGestureRecognizer *panRecognizer;
@property (readwrite) CGPoint lastPanPoint;
@property (readwrite) CGFloat lastPanDistance;

@property (strong) UIView *slidingAppContainerView;
@property (strong) UIView *slidingAppContainerViewTapHelper;

@property (strong) UIViewController *currentViewController;

@end

/////////////////////////////////////////////////////

@implementation ZLRevealViewController

#pragma mark - Initialization

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }

    return self;
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setupSlidingView];
    [self addPanRecognizer];
    [self setupSlidingViewTapHelper];
}

-(void) setupSlidingView
{
    self.slidingAppContainerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.slidingAppContainerView.backgroundColor = [UIColor clearColor];
    self.slidingAppContainerView.layer.shadowOffset = CGSizeMake(-4, 0);
    self.slidingAppContainerView.layer.masksToBounds = NO;
    self.slidingAppContainerView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.slidingAppContainerView.layer.shadowOpacity = 0.2;
}

-(void) addPanRecognizer
{
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleGestureRecognizer:)];
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    [self.slidingAppContainerView addGestureRecognizer:panRecognizer];
}

-(void) setupSlidingViewTapHelper
{
    self.slidingAppContainerViewTapHelper = [[UIView alloc] initWithFrame:self.view.bounds];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                    action:@selector(handleHelperTap)];
    [self.slidingAppContainerViewTapHelper addGestureRecognizer:tapRecognizer];
}

#pragma mark - UIGestureRecognizerDelegate methods

-(void) handleGestureRecognizer:(UIPanGestureRecognizer *) panRecognizer
{
    CGPoint currentPanPoint = [panRecognizer locationInView:self.view];

    switch (panRecognizer.state) {
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
    CGPoint touchLocation = [touch locationInView:self.slidingAppContainerView];
    if (touchLocation.x <= 60 || touchLocation.y <= 40) {
        return YES;
    }

    return NO;
}

-(void) handlePanMoveToPoint:(CGPoint) panPoint
{
    CGFloat distance = [self calculateDistanceWithPanPoint:panPoint];
    if (distance != 0.0) {
        self.lastPanDistance = distance;

        CGRect frame = self.slidingAppContainerView.frame;
        frame.origin.x += distance;
        if (frame.origin.x < 0.0) {
            frame.origin.x = 0.0;
        }
        else if (frame.origin.x > self.menuContainer.frame.size.width) {
            frame.origin.x = self.menuContainer.frame.size.width;
        }

        self.slidingAppContainerView.frame = frame;
        self.lastPanPoint = panPoint;
    }
}

-(CGFloat) calculateDistanceWithPanPoint:(CGPoint) panPoint
{
    return panPoint.x - self.lastPanPoint.x;
}

-(void) handlePanFinishAtPoint:(CGPoint) finishPoint
{
    if (self.lastPanDistance >= 0) {
        [self showSidekick];
    }
    else {
        [self hideSidekick];
    }
}

-(void) handleHelperTap
{
    [self hideSidekick];
}

-(void) toggleSidekick
{
    round(self.slidingAppContainerView.frame.origin.x) == 0 ? [self showSidekick] : [self hideSidekick];
}

#pragma mark - Sidekick

-(void) showSidekick
{
    CGRect newFrame = self.slidingAppContainerView.frame;
    newFrame.origin.x = self.menuContainer.frame.size.width;
    [self animateSliderViewToFrame:newFrame];
    [self installTapHelper];
}

-(void) installTapHelper
{
    [self.slidingAppContainerView addSubview:self.slidingAppContainerViewTapHelper];
}

-(void) animateSliderViewToFrame:(CGRect) newFrame
{
    [UIView animateWithDuration:[self slidingViewAnimationDurationForFrame:newFrame]
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^
     {
         self.slidingAppContainerView.frame = newFrame;
     }
                     completion:nil];
}

-(NSTimeInterval) slidingViewAnimationDurationForFrame:(CGRect) frame
{
    return ZLRevealSidekickAnimationDuration * (fabsf(frame.origin.x - self.slidingAppContainerView.frame.origin.x) / self.menuContainer.frame.size.width);
}

-(void) hideSidekick
{
    CGRect newFrame = self.slidingAppContainerView.frame;
    newFrame.origin.x = 0.0;
    [self animateSliderViewToFrame:newFrame];
    [self removeTapHelper];
}

-(void) removeTapHelper
{
    [self.slidingAppContainerViewTapHelper removeFromSuperview];
}

#pragma mark - View controllers presentation

-(void) showViewController:(UIViewController *) viewController
{
    [self removeViewOfCurrentViewController];
    [self addViewOfViewController:viewController];
    [self setupViewOfViewControllerToBeDisplayed:viewController];

    self.currentViewController = viewController;
}

-(void) setupViewOfViewControllerToBeDisplayed:(UIViewController *) viewController
{
    viewController.view.frame = self.slidingAppContainerView.bounds;
    [viewController.view setNeedsLayout];
    [viewController.view layoutIfNeeded];
}

-(void) addViewOfViewController:(UIViewController *) viewController
{
    [self addChildViewController:viewController];
    [self.slidingAppContainerView addSubview:viewController.view];

    if (!self.slidingAppContainerView.superview) {
        self.slidingAppContainerView.frame = self.view.bounds;
        [self.view addSubview:self.slidingAppContainerView];
    }
}

-(void) removeViewOfCurrentViewController
{
    [self.currentViewController removeFromParentViewController];
    [self.currentViewController.view removeFromSuperview];
    [self.currentViewController.view removeGestureRecognizer:self.panRecognizer];
}

@end

/////////////////////////////////////////////////////
