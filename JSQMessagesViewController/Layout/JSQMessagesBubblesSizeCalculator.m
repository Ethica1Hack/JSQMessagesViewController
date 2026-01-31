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
#import "JSQMessagesBubblesSizeCalculator.h"

#import "JSQMessagesCollectionView.h"
#import "JSQMessagesCollectionViewDataSource.h"
#import "JSQMessagesCollectionViewFlowLayout.h"
#import "JSQMessageData.h"
#import "UIImage+JSQMessages.h"

NS_ASSUME_NONNULL_BEGIN

@interface JSQMessagesBubblesSizeCalculator ()

@property (nonatomic, strong, readonly) NSCache<NSNumber *, NSValue *> *cache;
@property (nonatomic, assign, readonly) NSUInteger minimumBubbleWidth;
@property (nonatomic, assign, readonly) BOOL usesFixedWidthBubbles;
@property (nonatomic, assign, readonly) NSInteger additionalInset;
@property (nonatomic, assign) CGFloat layoutWidthForFixedWidthBubbles;
@property (nonatomic, strong, readonly) NSCache<NSString *, NSNumber *> *emojiCache;

@end

@implementation JSQMessagesBubblesSizeCalculator

#pragma mark - Initializers

- (instancetype)initWithCache:(NSCache *)cache
           minimumBubbleWidth:(NSUInteger)minimumBubbleWidth
        usesFixedWidthBubbles:(BOOL)usesFixedWidthBubbles
{
    NSParameterAssert(cache);
    NSParameterAssert(minimumBubbleWidth > 0);

    self = [super init];
    if (self) {
        _cache = cache;
        _minimumBubbleWidth = minimumBubbleWidth;
        _usesFixedWidthBubbles = usesFixedWidthBubbles;
        _layoutWidthForFixedWidthBubbles = 0.0f;
        _emojiCache = [NSCache new];
        _emojiCache.countLimit = 500;
        // boundingRect rounding correction
        _additionalInset = 2;
    }
    return self;
}

- (instancetype)init
{
    NSCache *cache = [NSCache new];
    cache.name = @"JSQMessagesBubblesSizeCalculator.cache";
    cache.countLimit = 200;

    return [self initWithCache:cache
            minimumBubbleWidth:[UIImage jsq_outgoingTwoToneBubble].size.width
         usesFixedWidthBubbles:NO];
}

#pragma mark - NSObject

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: cache=%@ minimumBubbleWidth=%lu usesFixedWidthBubbles=%@>",
            NSStringFromClass([self class]),
            self.cache,
            (unsigned long)self.minimumBubbleWidth,
            self.usesFixedWidthBubbles ? @"YES" : @"NO"];
}

#pragma mark - JSQMessagesBubbleSizeCalculating

- (void)prepareForResettingLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    [self.cache removeAllObjects];
}

- (void)resetBubbleSizeCacheForMessageData:(id<JSQMessageData>)messageData
{
    [self.cache removeObjectForKey:@(messageData.messageHash)];
}

- (CGSize)messageBubbleSizeForMessageData:(id<JSQMessageData>)messageData
                              atIndexPath:(NSIndexPath *)indexPath
                               withLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    NSNumber *cacheKey = @(messageData.messageHash);
    NSValue *cachedSize = [self.cache objectForKey:cacheKey];
    if (cachedSize) {
        return cachedSize.CGSizeValue;
    }

    CGSize finalSize = CGSizeZero;

    if (messageData.isMediaMessage) {
        finalSize = messageData.media.mediaViewDisplaySize;
    } else {

        CGSize avatarSize = [self jsq_avatarSizeForMessageData:messageData withLayout:layout];
        CGFloat spacing = 2.0f;

        CGFloat horizontalInsets =
        layout.messageBubbleTextViewTextContainerInsets.left +
        layout.messageBubbleTextViewTextContainerInsets.right +
        layout.messageBubbleTextViewFrameInsets.left +
        layout.messageBubbleTextViewFrameInsets.right +
        spacing;

        CGFloat maxTextWidth =
        [self textBubbleWidthForLayout:layout] -
        avatarSize.width -
        layout.messageBubbleLeftRightMargin -
        horizontalInsets;

        CGRect textRect =
        [messageData.text boundingRectWithSize:CGSizeMake(maxTextWidth, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                    attributes:@{ NSFontAttributeName : layout.messageBubbleFont }
                                       context:nil];

        CGSize textSize = CGRectIntegral(textRect).size;

        CGFloat verticalInsets =
        layout.messageBubbleTextViewTextContainerInsets.top +
        layout.messageBubbleTextViewTextContainerInsets.bottom +
        layout.messageBubbleTextViewFrameInsets.top +
        layout.messageBubbleTextViewFrameInsets.bottom +
        self.additionalInset;

        CGFloat finalWidth =
        MAX(textSize.width + horizontalInsets, self.minimumBubbleWidth) +
        self.additionalInset;

        if ([self stringContainsOnlyEmoji:messageData.text] && messageData.text.length <= 7) {
            finalWidth += MAX(5.0f + textSize.width + horizontalInsets,
                              self.minimumBubbleWidth);
        }

        finalSize = CGSizeMake(finalWidth, textSize.height + verticalInsets);
    }

    [self.cache setObject:[NSValue valueWithCGSize:finalSize] forKey:cacheKey];
    return finalSize;
}

#pragma mark - Emoji Detection

- (BOOL)stringContainsOnlyEmoji:(NSString *)string
{
    NSNumber *cached = [self.emojiCache objectForKey:string];
    if (cached) {
        return cached.boolValue;
    }

    __block BOOL onlyEmoji = YES;

    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange _, NSRange __, BOOL *stop) {
        if (![self isEmojiCharacter:substring]) {
            onlyEmoji = NO;
            *stop = YES;
        }
    }];

    [self.emojiCache setObject:@(onlyEmoji) forKey:string];
    return onlyEmoji;
}


- (BOOL)isEmojiCharacter:(NSString *)string
{
    __block BOOL isEmoji = NO;

    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange _, NSRange __, BOOL *stop) {

        const unichar hs = [substring characterAtIndex:0];
        const unichar ls = substring.length > 1 ? [substring characterAtIndex:1] : 0;

#define IS_IN(val, min, max) ((val) >= (min) && (val) <= (max))

        if (IS_IN(hs, 0xD800, 0xDBFF) && substring.length > 1) {
            const int uc = ((hs - 0xD800) * 0x400) + (ls - 0xDC00) + 0x10000;
            if (IS_IN(uc, 0x1D000, 0x1F9FF)) {
                isEmoji = YES;
            }
        } else if (substring.length > 1 && ls == 0x20E3) {
            isEmoji = YES;
        } else if (
            hs == 0x00A9 || hs == 0x00AE ||
            hs == 0x203C || hs == 0x2049 ||
            hs == 0x2122 || hs == 0x2139 ||
            IS_IN(hs, 0x2194, 0x2199) ||
            IS_IN(hs, 0x2600, 0x27BF) ||
            IS_IN(hs, 0x2B05, 0x2B55) ||
            hs == 0x3030 || hs == 0x303D ||
            hs == 0x3297 || hs == 0x3299
        ) {
            isEmoji = YES;
        }

#undef IS_IN
    }];

    return isEmoji;
}

#pragma mark - Layout Helpers

- (CGSize)jsq_avatarSizeForMessageData:(id<JSQMessageData>)messageData
                            withLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    if ([messageData.senderId isEqualToString:layout.collectionView.dataSource.senderId]) {
        return layout.outgoingAvatarViewSize;
    }
    return layout.incomingAvatarViewSize;
}

- (CGFloat)textBubbleWidthForLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    return self.usesFixedWidthBubbles
    ? [self widthForFixedWidthBubblesWithLayout:layout]
    : layout.itemWidth;
}

- (CGFloat)widthForFixedWidthBubblesWithLayout:(JSQMessagesCollectionViewFlowLayout *)layout
{
    if (self.layoutWidthForFixedWidthBubbles > 0.0f) {
        return self.layoutWidthForFixedWidthBubbles;
    }

    CGFloat horizontalInsets =
    layout.sectionInset.left +
    layout.sectionInset.right +
    self.additionalInset;

    CGFloat width =
    CGRectGetWidth(layout.collectionView.bounds) - horizontalInsets;

    CGFloat height =
    CGRectGetHeight(layout.collectionView.bounds) - horizontalInsets;

    self.layoutWidthForFixedWidthBubbles = MIN(width, height);
    return self.layoutWidthForFixedWidthBubbles;
}

@end

NS_ASSUME_NONNULL_END

