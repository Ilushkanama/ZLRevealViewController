//
//  ZLRevealViewController.m
//  RevealViewControllerTest
//
//  Created by Ilya Dyakonov on 19/04/14.
//  Copyright (c) 2014 ZappyLab. All rights reserved.
//

#import <ZLCategories/UIView+ZLCConstraintsSetup.h>

#import "ZLRevealViewController.h"
#import "UIResponder+ZLCFirstResponder.h"

/////////////////////////////////////////////////////

static NSTimeInterval const ZLRevealSidekickAnimationDuration = 0.18;
static CGFloat const ZLRevealRightSideKickWidth = 256;
static CGFloat const ZLRevealLeftSidekickDefaultWidth = 256;
static CGFloat const ZLRevealLeftSidekickMaxDisplacement = 60;

static CGFloat const ZLRevealPanAreaWidth = 60;
static CGFloat const ZLRevealPanAreaHeight = 40;

static CGFloat const ZLRevealShadowOffset = -4;
static CGFloat const ZLRevealShadowOpacity = 0.2;

/////////////////////////////////////////////////////

@interface ZLRevealViewController () <UIGestureRecognizerDelegate>

@property (readwrite) CGPoint lastPanPoint;
@property (readwrite) CGFloat lastPanDistance;

@property (strong) UIView *viewControllerContainer;
@property (strong) UIView *viewControllerContainerTapHelper;
@property (strong) UIView *rightSidekickContainer;
@property (strong) UIView *leftSidekickContainer;

@property (strong) NSLayoutConstraint *viewControllerContainerPositionConstraint;
@property (strong) NSLayoutConstraint *leftSidekickContainerPositionConstraint;
@property (strong) NSLayoutConstraint *leftSidekickContainerWidthConstraint;

@property (strong) UIViewController *viewController;
@property (strong) UIViewController *rightSideKickController;

@property (readwrite) BOOL panIsForLeftSidekick;

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

#pragma mark -

-(void) setLeftSidekickWidth:(CGFloat) width
{
    self.leftSidekickContainerWidthConstraint.constant = width;
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#pragma mark - View lifecycle

-(void) viewDidLoad
{
    [super viewDidLoad];

    [self setupLeftSidekickContainer];
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
    self.viewControllerContainer.layer.shadowOffset = CGSizeMake(ZLRevealShadowOffset, 0);
    self.viewControllerContainer.layer.masksToBounds = NO;
    self.viewControllerContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.viewControllerContainer.layer.shadowOpacity = ZLRevealShadowOpacity;
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

#pragma mark - UIGestureRecognizerDelegate methods

-(void) handleGestureRecognizer:(UIPanGestureRecognizer *) panRecognizer
{
    CGPoint currentPanPoint = [panRecognizer locationInView:self.view];

    switch (panRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            self.lastPanPoint = currentPanPoint;
            [self determinePanTarget:[panRecognizer locationInView:self.viewControllerContainer]];
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

-(void) determinePanTarget:(CGPoint) panPoint
{
    self.panIsForLeftSidekick = panPoint.x < ZLRevealPanAreaWidth;
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *) gestureRecognizer
       shouldReceiveTouch:(UITouch *) touch
{
    CGPoint touchLocation = [touch locationInView:self.viewControllerContainer];
    CGFloat distanceToRightEdge = CGRectGetWidth(self.viewControllerContainer.frame) - touchLocation.x;
    return touchLocation.x <= ZLRevealPanAreaWidth ||
            touchLocation.y <= ZLRevealPanAreaHeight ||
    (self.rightSideKickController && distanceToRightEdge < ZLRevealPanAreaWidth);

}

-(void) handlePanMoveToPoint:(CGPoint) panPoint
{
    CGFloat distance = [self calculateDistanceWithPanPoint:panPoint];
    if (distance != 0)
    {
        self.lastPanDistance = distance;

        CGFloat appContainerPosition = self.viewControllerContainerPositionConstraint.constant + distance;
        [self moveToPosition:[self normalizedPosition:appContainerPosition]
                    animated:NO];

        self.lastPanPoint = panPoint;
    }
}

-(CGFloat) normalizedPosition:(CGFloat) position
{
    CGFloat minX = 0;
    CGFloat maxX = CGRectGetWidth(self.leftSidekickContainer.frame);

    if (!self.panIsForLeftSidekick && self.rightSideKickController)
    {
        // user tries to reveal right sidekick
        minX = -ZLRevealRightSideKickWidth;
        maxX = 0;
    }

    if (position < minX)
    {
        position = minX;
    }
    else if (position > maxX)
    {
        position = maxX;
    }

    return position;
}

-(CGFloat) calculateDistanceWithPanPoint:(CGPoint) panPoint
{
    return panPoint.x - self.lastPanPoint.x;
}

-(void) handlePanFinishAtPoint:(CGPoint) finishPoint
{
    if (self.panIsForLeftSidekick)
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
    else if (self.rightSideKickController)
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
    [self moveToPosition:CGRectGetWidth(self.leftSidekickContainer.frame)
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
    [[UIResponder ZLC_currentFirstResponder] resignFirstResponder];

    void (^moveBlock)() = ^{
        self.viewControllerContainerPositionConstraint.constant = position;
        self.leftSidekickContainerPositionConstraint.constant = [self leftSidekickDisplacementForViewControllerPosition:position];

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

-(CGFloat) leftSidekickDisplacementForViewControllerPosition:(CGFloat) position
{
    // full sidekick displacement is achieved when view controller positioned at 0
    // no sidekick displacement is needed when sidekick is fully visible -
    // view controller positioned at coordinate = left sidekick container width
    CGFloat displacement = -ZLRevealLeftSidekickMaxDisplacement;

    if (position >= 0)
    {
        position -= CGRectGetWidth(self.leftSidekickContainer.frame);
        displacement = position / CGRectGetWidth(self.leftSidekickContainer.frame) * ZLRevealLeftSidekickMaxDisplacement;
    }

    return displacement;
}

-(NSTimeInterval) moveAnimationDurationForPosition:(CGFloat) position
{
    return ZLRevealSidekickAnimationDuration * (fabsf(position - CGRectGetMinX(self.viewControllerContainer.frame)) / CGRectGetWidth(self.leftSidekickContainer.frame));
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
    [self setupConstraintsForViewController:viewController];
    [viewController.view setNeedsLayout];
    [viewController.view layoutIfNeeded];
}

-(void) setupConstraintsForViewController:(UIViewController *) viewController
{
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [viewController.view.superview ZLC_bindSubviewHorizontally:viewController.view];
    [viewController.view.superview ZLC_bindSubviewVertically:viewController.view];
}

#pragma mark - Right sidekick

-(void) setupRightSidekickContainer
{
    self.rightSidekickContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.rightSidekickContainer.backgroundColor = [UIColor whiteColor];
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
    if (viewController)
    {
        [self showViewController:viewController
                     inContainer:self.rightSidekickContainer];
    }
    else
    {
        [self removeViewOfViewController:self.rightSideKickController];
    }
    
    self.rightSideKickController = viewController;
}

#pragma mark - Left sidekick

-(void) setupLeftSidekickContainer
{
    self.leftSidekickContainer = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.leftSidekickContainer];

    [self setupLeftSidekickConstraints];
}

-(void) setupLeftSidekickConstraints
{
    self.leftSidekickContainer.translatesAutoresizingMaskIntoConstraints = NO;

    [self.leftSidekickContainer.superview ZLC_bindSubviewVertically:self.leftSidekickContainer];
    self.leftSidekickContainerWidthConstraint = [self.leftSidekickContainer ZLC_bindWidth:ZLRevealLeftSidekickDefaultWidth];

    self.leftSidekickContainerPositionConstraint = [self.leftSidekickContainer ZLC_constraintAlingningLeftEdgesWithView:self.leftSidekickContainer.superview];
    self.leftSidekickContainerPositionConstraint.constant = -ZLRevealLeftSidekickMaxDisplacement;
    [self.leftSidekickContainer.superview addConstraint:self.leftSidekickContainerPositionConstraint];
}

-(void) showLeftSidekickController:(UIViewController *) viewController
{
    [self showViewController:viewController
                 inContainer:self.leftSidekickContainer];
}

@end

/////////////////////////////////////////////////////
