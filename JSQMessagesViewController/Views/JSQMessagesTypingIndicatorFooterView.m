//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesTypingIndicatorFooterView.h"
#import "JSQMessagesTypingView.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "UIColor+JSQMessages.h"
#import "UIImage+JSQMessages.h"

const CGFloat kJSQMessagesTypingIndicatorFooterViewHeight = 46.0f;


@interface JSQMessagesTypingIndicatorFooterView ()

@property (weak, nonatomic) IBOutlet UIImageView *bubbleImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleImageViewRightHorizontalConstraint;
@property (weak, nonatomic) IBOutlet JSQMessagesTypingView *typingView;
@property (weak, nonatomic) IBOutlet UIImageView *typingIndicatorImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typingIndicatorImageViewRightHorizontalConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *typingIndicatorToBubbleImageAlignConstraint;

@end



@implementation JSQMessagesTypingIndicatorFooterView

#pragma mark - Class methods

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([JSQMessagesTypingIndicatorFooterView class])
                          bundle:[NSBundle bundleForClass:[JSQMessagesTypingIndicatorFooterView class]]];
}

+ (NSString *)footerReuseIdentifier
{
    return NSStringFromClass([JSQMessagesTypingIndicatorFooterView class]);
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.backgroundColor = [UIColor clearColor];
    self.userInteractionEnabled = NO;

}

#pragma mark - Reusable view

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
    self.bubbleImageView.backgroundColor = backgroundColor;
}

#pragma mark - Typing indicator

- (void)configureWithEllipsisColor:(UIColor *)ellipsisColor
                messageBubbleColor:(UIColor *)messageBubbleColor
                          animated:(BOOL)animated
               shouldDisplayOnLeft:(BOOL)shouldDisplayOnLeft
                 forCollectionView:(UICollectionView *)collectionView
{
    NSParameterAssert(ellipsisColor != nil);
    NSParameterAssert(messageBubbleColor != nil);
    NSParameterAssert(collectionView != nil);
    
    CGFloat bubbleMarginMinimumSpacing = 6.0f;
    
    JSQMessagesBubbleImageFactory *bubbleImageFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    
    if (shouldDisplayOnLeft) {
        self.bubbleImageView.image = [bubbleImageFactory incomingMessagesBubbleImageWithColor:messageBubbleColor].messageBubbleImage;
        
        CGFloat collectionViewWidth = CGRectGetWidth(collectionView.frame);
        CGFloat bubbleWidth = CGRectGetWidth(self.bubbleImageView.frame);
 
        
        CGFloat bubbleMarginMaximumSpacing = collectionViewWidth - bubbleWidth - bubbleMarginMinimumSpacing;
 
        
        self.bubbleImageViewRightHorizontalConstraint.constant = bubbleMarginMaximumSpacing;

         self.typingIndicatorToBubbleImageAlignConstraint.constant = 0;
    }
    else {
        self.bubbleImageView.image = [bubbleImageFactory outgoingMessagesBubbleImageWithColor:messageBubbleColor].messageBubbleImage;
        
        self.bubbleImageViewRightHorizontalConstraint.constant = bubbleMarginMinimumSpacing;

         self.typingIndicatorToBubbleImageAlignConstraint.constant = 6;
    }
    
    [self setNeedsUpdateConstraints];
 
        self.typingView.dotsColor = [UIColor colorWithRed:(185/255.0) green:(201/255.0) blue:(202/255.0) alpha:1.0];
        self.typingView.animateToColor = [UIColor colorWithRed:(39/255.0) green:(48/255.0) blue:(61/255.0) alpha:0.0];
        self.typingView.animated = animated;
        self.typingView.animationDuration = 1.33;

         if (animated) {
            CAAnimation *pulseAnimation = [JSQMessagesTypingIndicatorFooterView pulseAnimation];
             pulseAnimation.duration = self.typingView.animationDuration * 2;
            [self.bubbleImageView.layer addAnimation:pulseAnimation forKey:@"pulsing"];
        }
    }

+ (CAKeyframeAnimation *)pulseAnimation
    {
        CAKeyframeAnimation *pulseAnimation = [CAKeyframeAnimation animation];
        pulseAnimation.keyPath = @"transform";

         pulseAnimation.values = @[
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.32, 1.13, 0.7)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.03, 0.82, 1.0)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.32, 1.13, 0.7)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.03, 0.82, 1.0)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.32, 1.13, 0.7)]
                                  ];

        pulseAnimation.keyTimes = @[ @0, @(1/4.0), @(1/2.0), @(3/4.0), @1 ];
        pulseAnimation.repeatCount = LONG_MAX;
        pulseAnimation.autoreverses = YES;
        return pulseAnimation;
}

@end
