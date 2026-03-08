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

#import "JSQMessagesMediaViewBubbleImageMasker.h"
#import "JSQMessagesBubbleImageFactory.h"
#import "UIImage+JSQMessages.h"

@implementation JSQMessagesMediaViewBubbleImageMasker

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithBubbleImageFactory:[[JSQMessagesBubbleImageFactory alloc] init]];
}

- (instancetype)initWithBubbleImageFactory:(JSQMessagesBubbleImageFactory *)bubbleImageFactory {
    NSParameterAssert(bubbleImageFactory != nil);
    if (self = [super init]) {
        _bubbleImageFactory = bubbleImageFactory;
    }
    return self;
}

#pragma mark - Public Methods

- (void)applyOutgoingBubbleImageMaskToMediaView:(UIView *)mediaView {
    [self applyBubbleImageMaskToMediaView:mediaView
                                    color:[UIColor whiteColor]
                              isOutgoing:YES];
}

- (void)applyIncomingBubbleImageMaskToMediaView:(UIView *)mediaView {
    [self applyBubbleImageMaskToMediaView:mediaView
                                    color:[UIColor whiteColor]
                              isOutgoing:NO];
}

+ (void)applyBubbleImageMaskToMediaView:(UIView *)mediaView isOutgoing:(BOOL)isOutgoing {
    NSParameterAssert(mediaView != nil);

    UIColor *bubbleColor = [UIColor whiteColor];
    JSQMessagesMediaViewBubbleImageMasker *masker = [[JSQMessagesMediaViewBubbleImageMasker alloc] init];
    [masker applyBubbleImageMaskToMediaView:mediaView color:bubbleColor isOutgoing:isOutgoing];
}

#pragma mark - Private Helpers

//- (void)applyBubbleImageMaskToMediaView:(UIView *)mediaView color:(UIColor *)color isOutgoing:(BOOL)isOutgoing {
//    UIImage *solidBubble = [UIImage jsq_solidBubbleImage];
//    JSQMessagesBubbleImage *bubbleImageData = isOutgoing
//        ? [self.bubbleImageFactory outgoingMessagesBubbleImageWithColor:solidBubble]
//        : [self.bubbleImageFactory incomingMessagesBubbleImageWithColor:solidBubble];
//
//    [self jsq_maskView:mediaView withImage:[bubbleImageData messageBubbleImage]];
//}

- (void)applyBubbleImageMaskToMediaView:(UIView *)mediaView color:(UIColor *)color isOutgoing:(BOOL)isOutgoing {
    UIImage *solidBubble = [UIImage jsq_solidBubbleImage];
    
    UIImageView *maskView = [[UIImageView alloc] initWithImage:solidBubble];
    maskView.frame = mediaView.bounds;
    maskView.contentMode = UIViewContentModeScaleAspectFill;
    
    if (@available(iOS 14.0, *)) {
        mediaView.maskView = maskView;
    } else {
        mediaView.layer.mask = maskView.layer;
        mediaView.layer.masksToBounds = YES;
    }
}


- (void)jsq_maskView:(UIView *)view withImage:(UIImage *)image {
    NSParameterAssert(view != nil);
    NSParameterAssert(image != nil);
    
    UIImageView *imageViewMask = [[UIImageView alloc] initWithImage:image];
    imageViewMask.frame = CGRectInset(view.bounds, 2.0f, 2.0f);
    imageViewMask.contentMode = UIViewContentModeScaleAspectFill;

    if (@available(iOS 14.0, *)) {
        view.maskView = imageViewMask;
    } else {
        view.layer.mask = imageViewMask.layer;
        view.layer.masksToBounds = YES;
    }
}

@end
