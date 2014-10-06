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

@property (strong) UIView *viewControllerContainer;
@property (strong) UIView *viewControllerContainerTapHelper;
@property (strong) UIView *rightSidekickContainer;
@property (strong) UIView *leftSidekickContainer;

@property (strong) NSLayoutConstraint *viewControllerContainerPositionConstraint;
@property (strong) NSLayoutConstraint *leftSidekickContainerPositionConstraint;
@property (strong) NSLayoutConstraint *leftSidekickContainerWidthConstraint;
@property (strong, nonatomic) NSLayoutConstraint *rightSidekickContainerPositionConstraint;

@property (strong) UIViewController *viewController;
@property (strong) UIViewController *rightSideKickController;

@property (readwrite) BOOL panIsForLeftSidekick;
@property (readwrite) CGFloat lastPanDistance;

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
    self.viewControllerContainerPositionConstraint = [self.viewControllerContainer ZLC_constraintAligningLeftEdgesWithView:self.viewControllerContainer.superview];
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
    switch (panRecognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            self.lastPanDistance = [panRecognizer translationInView:self.view].x;
            [self determinePanTarget:[panRecognizer locationInView:self.viewControllerContainer]];
            break;

        case UIGestureRecognizerStateChanged:
            [self handlePanMoveByDistance:[panRecognizer translationInView:self.view].x];
            [panRecognizer setTranslation:CGPointZero
                                   inView:self.view];
            break;

        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
            [self handlePanFinish];
            break;

        default:
            break;
    }
}

-(void) determinePanTarget:(CGPoint) panPoint
{
    CGFloat distanceToRightEdge = CGRectGetWidth(self.viewControllerContainer.frame) - panPoint.x;
    if ([self rightSidekickVisible])
    {
        self.panIsForLeftSidekick = NO;
    }
    else
    {
        self.panIsForLeftSidekick = panPoint.x < ZLRevealPanAreaWidth
                                    || (distanceToRightEdge > ZLRevealPanAreaHeight &&
                                        panPoint.y < ZLRevealPanAreaHeight);
    }
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *) gestureRecognizer
       shouldReceiveTouch:(UITouch *) touch
{
    BOOL shouldReceiveTouch;
    
    CGPoint touchLocation = [touch locationInView:self.viewControllerContainer];
    CGFloat distanceToRightEdge = CGRectGetWidth(self.viewControllerContainer.frame) - touchLocation.x;
    if ([self rightSidekickVisible] || [self leftSidekickVisible])
    {
        shouldReceiveTouch = YES;
    }
    else
    {
        shouldReceiveTouch = touchLocation.x <= ZLRevealPanAreaWidth ||
                                touchLocation.y <= ZLRevealPanAreaHeight ||
                                (self.rightSideKickController && distanceToRightEdge < ZLRevealPanAreaWidth);
    }
    
    return shouldReceiveTouch;
}

-(void) handlePanMoveByDistance:(CGFloat) distance
{
    if (distance != 0)
    {
        self.lastPanDistance = distance;

        if (self.panIsForLeftSidekick)
        {
            CGFloat position = self.viewControllerContainerPositionConstraint.constant + distance;
            [self moveToPosition:[self normalizedPosition:position]
                        animated:NO];
        }
        else
        {
            CGFloat position = self.rightSidekickContainerPositionConstraint.constant + distance;
            [self moveRightSidekickToOffset:[self normalizedRightSidekickOffset:position]
                                   animated:NO];
        }
    }
}

-(CGFloat) normalizedPosition:(CGFloat) position
{
    CGFloat minX = 0;
    CGFloat maxX = CGRectGetWidth(self.leftSidekickContainer.frame);

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

-(CGFloat) normalizedRightSidekickOffset:(CGFloat) offset
{
    CGFloat minX = -ZLRevealRightSideKickWidth;
    CGFloat maxX = 0;

    if (offset < minX)
    {
        offset = minX;
    }
    else if (offset > maxX)
    {
        offset = maxX;
    }

    return offset;
}

-(void) handlePanFinish
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
    [self moveRightSidekickToOffset:-ZLRevealRightSideKickWidth
                           animated:YES];
    [self installTapHelper];
}

-(void) hideRightSidekick
{
    [self notifyAboutRightSidekickDidHide];
    [self moveRightSidekickToOffset:0
                           animated:YES];
    [self removeTapHelper];
}

-(void) moveRightSidekickToOffset:(CGFloat) offset
                         animated:(BOOL) animated
{
    [[UIResponder ZLC_currentFirstResponder] resignFirstResponder];

    void (^moveBlock)() = ^
    {
        self.rightSidekickContainerPositionConstraint.constant = offset;

        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    };

    if (animated)
    {
        [self.view layoutIfNeeded];
        [UIView animateWithDuration:0.25
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

-(void) notifyAboutRightSidekickDidHide
{
    [[NSNotificationCenter defaultCenter] postNotificationName:ZLRevealViewControllerDidHideRightSidekickNotification
                                                        object:self];
}

-(void) handleHelperTap
{
    if ([self rightSidekickVisible])
    {
        [self hideRightSidekick];
    }
    else
    {
        [self hideSidekick];
    }
}

-(BOOL) rightSidekickVisible
{
    return self.rightSidekickContainerPositionConstraint.constant < 0;
}

-(BOOL) leftSidekickVisible
{
    return self.viewControllerContainerPositionConstraint.constant > 0;
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

    void (^moveBlock)() = ^
    {
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
    [self removeViewOfViewController:self.viewController];
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
    [viewController willMoveToParentViewController:nil];
    [viewController removeFromParentViewController];
    [viewController.view removeFromSuperview];
    [viewController didMoveToParentViewController:nil];
}

-(void) addViewOfViewController:(UIViewController *) viewController
                    toContainer:(UIView *) container
{
    [viewController willMoveToParentViewController:self];
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

    self.rightSidekickContainerPositionConstraint = [self.rightSidekickContainer ZLC_constraintAligningLeftEdgeWithRightEdgeOfView:self.viewControllerContainer];
    [self.rightSidekickContainer.superview addConstraint:self.rightSidekickContainerPositionConstraint];
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

    self.leftSidekickContainerPositionConstraint = [self.leftSidekickContainer ZLC_constraintAligningLeftEdgesWithView:self.leftSidekickContainer.superview];
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
