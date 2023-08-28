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

#import "JSQMessagesCollectionViewCell.h"

#import "JSQMessagesCollectionViewCellIncoming.h"
#import "JSQMessagesCollectionViewCellOutgoing.h"
#import "JSQMessagesCollectionViewLayoutAttributes.h"

#import "UIView+JSQMessages.h"
#import "UIDevice+JSQMessages.h"


static NSMutableSet *jsqMessagesCollectionViewCellActions = nil;


@interface JSQMessagesCollectionViewCell ()

@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellTopLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *messageBubbleTopLabel;
@property (weak, nonatomic) IBOutlet JSQMessagesLabel *cellBottomLabel;

@property (weak, nonatomic) IBOutlet UIView *messageBubbleContainerView;
@property (weak, nonatomic) IBOutlet UIImageView *messageBubbleImageView;
@property (weak, nonatomic) IBOutlet JSQMessagesCellTextView *textView;

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UIView *avatarContainerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleContainerWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTopVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewBottomVerticalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewAvatarHorizontalSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewMarginHorizontalSpaceConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *messageBubbleTopLabelHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *cellBottomLabelHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *avatarContainerViewHeightConstraint;

@property (assign, nonatomic) UIEdgeInsets textViewFrameInsets;

@property (assign, nonatomic) CGSize avatarViewSize;

@property (weak, nonatomic, readwrite) UITapGestureRecognizer *tapGestureRecognizer;

- (void)jsq_handleTapGesture:(UITapGestureRecognizer *)tap;

- (void)jsq_updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant;

@end


@implementation JSQMessagesCollectionViewCell

#pragma mark - Class methods

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        jsqMessagesCollectionViewCellActions = [NSMutableSet new];
    });
}

+ (UINib *)nib
{
    return [UINib nibWithNibName:NSStringFromClass([self class]) bundle:[NSBundle bundleForClass:[self class]]];
}

+ (NSString *)cellReuseIdentifier
{
    return NSStringFromClass([self class]);
}

+ (NSString *)mediaCellReuseIdentifier
{
    return [NSString stringWithFormat:@"%@_JSQMedia", NSStringFromClass([self class])];
}

+ (void)registerMenuAction:(SEL)action
{
    [jsqMessagesCollectionViewCellActions addObject:NSStringFromSelector(action)];
}

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];

    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.backgroundColor = [UIColor whiteColor];

    self.cellTopLabelHeightConstraint.constant = 0.0f;
    self.messageBubbleTopLabelHeightConstraint.constant = 0.0f;
    self.cellBottomLabelHeightConstraint.constant = 0.0f;

    self.avatarViewSize = CGSizeZero;

    self.cellTopLabel.textAlignment = NSTextAlignmentCenter;
    self.cellTopLabel.font = [UIFont boldSystemFontOfSize:12.0f];
    self.cellTopLabel.textColor = [UIColor lightGrayColor];

    self.messageBubbleTopLabel.font = [UIFont systemFontOfSize:12.0f];
    self.messageBubbleTopLabel.textColor = [UIColor lightGrayColor];

    self.cellBottomLabel.font = [UIFont systemFontOfSize:11.0f];
    self.cellBottomLabel.textColor = [UIColor lightGrayColor];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(jsq_handleTapGesture:)];
    [self addGestureRecognizer:tap];
    self.tapGestureRecognizer = tap;
}

- (void)dealloc
{
    _delegate = nil;

    _cellTopLabel = nil;
    _messageBubbleTopLabel = nil;
    _cellBottomLabel = nil;

    _textView = nil;
    _messageBubbleImageView = nil;
    _mediaView = nil;

    _avatarImageView = nil;

    [_tapGestureRecognizer removeTarget:nil action:NULL];
    _tapGestureRecognizer = nil;
}

#pragma mark - Collection view cell

- (void)prepareForReuse
{
    [super prepareForReuse];

    self.cellTopLabel.text = nil;
    self.messageBubbleTopLabel.text = nil;
    self.cellBottomLabel.text = nil;

    self.textView.dataDetectorTypes = UIDataDetectorTypeNone;
    self.textView.text = nil;
    self.textView.attributedText = nil;

    self.avatarImageView.image = nil;
    self.avatarImageView.highlightedImage = nil;
}

- (UICollectionViewLayoutAttributes *)preferredLayoutAttributesFittingAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    return layoutAttributes;
}

- (void)applyLayoutAttributes:(UICollectionViewLayoutAttributes *)layoutAttributes
{
    [super applyLayoutAttributes:layoutAttributes];

    JSQMessagesCollectionViewLayoutAttributes *customAttributes = (JSQMessagesCollectionViewLayoutAttributes *)layoutAttributes;
    
    if (self.textView.font != customAttributes.messageBubbleFont) {
            self.textView.font = customAttributes.messageBubbleFont;
    }
    
    if (!UIEdgeInsetsEqualToEdgeInsets(self.textView.textContainerInset, customAttributes.textViewTextContainerInsets)) {
        self.textView.textContainerInset = customAttributes.textViewTextContainerInsets;
    }

    self.textViewFrameInsets = customAttributes.textViewFrameInsets;

    [self jsq_updateConstraint:self.messageBubbleContainerWidthConstraint
                  withConstant:customAttributes.messageBubbleContainerViewWidth];

    [self jsq_updateConstraint:self.cellTopLabelHeightConstraint
                  withConstant:customAttributes.cellTopLabelHeight];

    [self jsq_updateConstraint:self.messageBubbleTopLabelHeightConstraint
                  withConstant:customAttributes.messageBubbleTopLabelHeight];

    [self jsq_updateConstraint:self.cellBottomLabelHeightConstraint
                  withConstant:customAttributes.cellBottomLabelHeight];

    if ([self isKindOfClass:[JSQMessagesCollectionViewCellIncoming class]]) {
        self.avatarViewSize = customAttributes.incomingAvatarViewSize;
    }
    else if ([self isKindOfClass:[JSQMessagesCollectionViewCellOutgoing class]]) {
        self.avatarViewSize = customAttributes.outgoingAvatarViewSize;
    }
    
    // Apply different font size to emoji characters
      if ([self stringContainsOnlyEmoji:self.textView.text] && !(self.textView.text.length > 7)) {
          UIFont *messageBubbleFont = customAttributes.messageBubbleFont;
            CGFloat emojiFontSize = messageBubbleFont.pointSize + 31; // Adjust the value as needed
            UIFont *emojiFont = [UIFont fontWithName:messageBubbleFont.fontName size:emojiFontSize];
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:self.textView.attributedText];
            
            [attributedString enumerateAttribute:NSFontAttributeName inRange:NSMakeRange(0, attributedString.length) options:0 usingBlock:^(id value, NSRange range, BOOL *stop) {
                if (value && [value isKindOfClass:[UIFont class]]) {
                    UIFont *font = (UIFont *)value;
                    if ([self isEmojiCharacter:[attributedString.string substringWithRange:range]]) {
                        [attributedString addAttribute:NSFontAttributeName value:emojiFont range:range];
                    }
                }
            }];
            self.textView.attributedText = attributedString;
      }
}

- (BOOL)stringContainsOnlyEmoji:(NSString *)string {
    __block BOOL onlyEmoji = YES;

    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop) {
        if (![self isEmojiCharacter:substring]) {
            onlyEmoji = NO;
            *stop = YES;
        }
    }];

    return onlyEmoji;
}

- (BOOL)isEmojiCharacter:(NSString *)string {

    __block BOOL returnValue = NO;

    [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                               options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString* substring, NSRange substringRange, NSRange enclosingRange, BOOL* stop)
     {
         const unichar hs = [substring characterAtIndex:0];
         const unichar ls = substring.length > 1 ? [substring characterAtIndex:1] : 0;

#define IS_IN(val, min, max) (((val) >= (min)) && ((val) <= (max)))

         if(IS_IN(hs, 0xD800, 0xDBFF))
         {
             if(substring.length > 1)
             {
                 const int uc = ((hs - 0xD800) * 0x400) + (ls - 0xDC00) + 0x10000;

                 // Musical: [U+1D000, U+1D24F]
                 // Enclosed Alphanumeric Supplement: [U+1F100, U+1F1FF]
                 // Enclosed Ideographic Supplement: [U+1F200, U+1F2FF]
                 // Miscellaneous Symbols and Pictographs: [U+1F300, U+1F5FF]
                 // Supplemental Symbols and Pictographs: [U+1F900, U+1F9FF]
                 // Emoticons: [U+1F600, U+1F64F]
                 // Transport and Map Symbols: [U+1F680, U+1F6FF]
                 if(IS_IN(uc, 0x1D000, 0x1F9FF))
                     returnValue = YES;
             }
         }
         else if(substring.length > 1 && ls == 0x20E3)
         {
             // emojis for numbers: number + modifier ls = U+20E3
             returnValue = YES;
         }
         else
         {
             if(        // Latin-1 Supplement
                hs == 0x00A9 || hs == 0x00AE
                // General Punctuation
                ||  hs == 0x203C || hs == 0x2049
                // Letterlike Symbols
                ||  hs == 0x2122 || hs == 0x2139
                // Arrows
                ||  IS_IN(hs, 0x2194, 0x2199) || IS_IN(hs, 0x21A9, 0x21AA)
                // Miscellaneous Technical
                ||  IS_IN(hs, 0x231A, 0x231B) || IS_IN(hs, 0x23E9, 0x23F3) || IS_IN(hs, 0x23F8, 0x23FA) || hs == 0x2328 || hs == 0x23CF
                // Geometric Shapes
                ||  IS_IN(hs, 0x25AA, 0x25AB) || IS_IN(hs, 0x25FB, 0x25FE) || hs == 0x25B6 || hs == 0x25C0
                // Miscellaneous Symbols
                ||  IS_IN(hs, 0x2600, 0x2604) || IS_IN(hs, 0x2614, 0x2615) || IS_IN(hs, 0x2622, 0x2623) || IS_IN(hs, 0x262E, 0x262F)
                ||  IS_IN(hs, 0x2638, 0x263A) || IS_IN(hs, 0x2648, 0x2653) || IS_IN(hs, 0x2665, 0x2666) || IS_IN(hs, 0x2692, 0x2694)
                ||  IS_IN(hs, 0x2696, 0x2697) || IS_IN(hs, 0x269B, 0x269C) || IS_IN(hs, 0x26A0, 0x26A1) || IS_IN(hs, 0x26AA, 0x26AB)
                ||  IS_IN(hs, 0x26B0, 0x26B1) || IS_IN(hs, 0x26BD, 0x26BE) || IS_IN(hs, 0x26C4, 0x26C5) || IS_IN(hs, 0x26CE, 0x26CF)
                ||  IS_IN(hs, 0x26D3, 0x26D4) || IS_IN(hs, 0x26D3, 0x26D4) || IS_IN(hs, 0x26E9, 0x26EA) || IS_IN(hs, 0x26F0, 0x26F5)
                ||  IS_IN(hs, 0x26F7, 0x26FA)
                ||  hs == 0x260E || hs == 0x2611 || hs == 0x2618 || hs == 0x261D || hs == 0x2620 || hs == 0x2626 || hs == 0x262A
                ||  hs == 0x2660 || hs == 0x2663 || hs == 0x2668 || hs == 0x267B || hs == 0x267F || hs == 0x2699 || hs == 0x26C8
                ||  hs == 0x26D1 || hs == 0x26FD
                // Dingbats
                ||  IS_IN(hs, 0x2708, 0x270D) || IS_IN(hs, 0x2733, 0x2734) || IS_IN(hs, 0x2753, 0x2755)
                ||  IS_IN(hs, 0x2763, 0x2764) || IS_IN(hs, 0x2795, 0x2797)
                ||  hs == 0x2702 || hs == 0x2705 || hs == 0x270F || hs == 0x2712 || hs == 0x2714 || hs == 0x2716 || hs == 0x271D
                ||  hs == 0x2721 || hs == 0x2728 || hs == 0x2744 || hs == 0x2747 || hs == 0x274C || hs == 0x274E || hs == 0x2757
                ||  hs == 0x27A1 || hs == 0x27B0 || hs == 0x27BF
                // CJK Symbols and Punctuation
                ||  hs == 0x3030 || hs == 0x303D
                // Enclosed CJK Letters and Months
                ||  hs == 0x3297 || hs == 0x3299
                // Supplemental Arrows-B
                ||  IS_IN(hs, 0x2934, 0x2935)
                // Miscellaneous Symbols and Arrows
                ||  IS_IN(hs, 0x2B05, 0x2B07) || IS_IN(hs, 0x2B1B, 0x2B1C) || hs == 0x2B50 || hs == 0x2B55
                )
             {
                 returnValue = YES;
             }
         }

#undef IS_IN
     }];

    return returnValue;
}


- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    self.avatarImageView.highlighted = highlighted;
    self.messageBubbleImageView.highlighted = highlighted;
}

- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    self.avatarImageView.highlighted = selected;
    self.messageBubbleImageView.highlighted = selected;
}

//  FIXME: radar 18326340
//         remove when fixed
//         hack for Xcode6 / iOS 8 SDK rendering bug that occurs on iOS 7.x
//         see issue #484
//         https://github.com/jessesquires/JSQMessagesViewController/issues/484
//
- (void)setBounds:(CGRect)bounds
{
    [super setBounds:bounds];

    if ([UIDevice jsq_isCurrentDeviceBeforeiOS8]) {
        self.contentView.frame = bounds;
    }
}

#pragma mark - Menu actions

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(aSelector)]) {
        return YES;
    }

    return [super respondsToSelector:aSelector];
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(anInvocation.selector)]) {
        __unsafe_unretained id sender;
        [anInvocation getArgument:&sender atIndex:0];
        [self.delegate messagesCollectionViewCell:self didPerformAction:anInvocation.selector withSender:sender];
    }
    else {
        [super forwardInvocation:anInvocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    if ([jsqMessagesCollectionViewCellActions containsObject:NSStringFromSelector(aSelector)]) {
        return [NSMethodSignature signatureWithObjCTypes:"v@:@"];
    }

    return [super methodSignatureForSelector:aSelector];
}

#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];

    self.cellTopLabel.backgroundColor = backgroundColor;
    self.messageBubbleTopLabel.backgroundColor = backgroundColor;
    self.cellBottomLabel.backgroundColor = backgroundColor;

    self.messageBubbleImageView.backgroundColor = backgroundColor;
    self.avatarImageView.backgroundColor = backgroundColor;

    self.messageBubbleContainerView.backgroundColor = backgroundColor;
    self.avatarContainerView.backgroundColor = backgroundColor;
}

- (void)setAvatarViewSize:(CGSize)avatarViewSize
{
    if (CGSizeEqualToSize(avatarViewSize, self.avatarViewSize)) {
        return;
    }

    [self jsq_updateConstraint:self.avatarContainerViewWidthConstraint withConstant:avatarViewSize.width];
    [self jsq_updateConstraint:self.avatarContainerViewHeightConstraint withConstant:avatarViewSize.height];
}

- (void)setTextViewFrameInsets:(UIEdgeInsets)textViewFrameInsets
{
    if (UIEdgeInsetsEqualToEdgeInsets(textViewFrameInsets, self.textViewFrameInsets)) {
        return;
    }

    [self jsq_updateConstraint:self.textViewTopVerticalSpaceConstraint withConstant:textViewFrameInsets.top];
    [self jsq_updateConstraint:self.textViewBottomVerticalSpaceConstraint withConstant:textViewFrameInsets.bottom];
    [self jsq_updateConstraint:self.textViewAvatarHorizontalSpaceConstraint withConstant:textViewFrameInsets.right];
    [self jsq_updateConstraint:self.textViewMarginHorizontalSpaceConstraint withConstant:textViewFrameInsets.left];
}

- (void)setMediaView:(UIView *)mediaView
{
    [self.messageBubbleImageView removeFromSuperview];
    [self.textView removeFromSuperview];

    [mediaView setTranslatesAutoresizingMaskIntoConstraints:NO];
    mediaView.frame = self.messageBubbleContainerView.bounds;

    [self.messageBubbleContainerView addSubview:mediaView];
    [self.messageBubbleContainerView jsq_pinAllEdgesOfSubview:mediaView];
    _mediaView = mediaView;

    //  because of cell re-use (and caching media views, if using built-in library media item)
    //  we may have dequeued a cell with a media view and add this one on top
    //  thus, remove any additional subviews hidden behind the new media view
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.messageBubbleContainerView.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger index, BOOL *stop) {
            if (subview != _mediaView) {
                [subview removeFromSuperview];
            }
        }];
    });
}

#pragma mark - Getters

- (CGSize)avatarViewSize
{
    return CGSizeMake(self.avatarContainerViewWidthConstraint.constant,
                      self.avatarContainerViewHeightConstraint.constant);
}

- (UIEdgeInsets)textViewFrameInsets
{
    return UIEdgeInsetsMake(self.textViewTopVerticalSpaceConstraint.constant,
                            self.textViewMarginHorizontalSpaceConstraint.constant,
                            self.textViewBottomVerticalSpaceConstraint.constant,
                            self.textViewAvatarHorizontalSpaceConstraint.constant);
}

#pragma mark - Utilities

- (void)jsq_updateConstraint:(NSLayoutConstraint *)constraint withConstant:(CGFloat)constant
{
    if (constraint.constant == constant) {
        return;
    }

    constraint.constant = constant;
}

#pragma mark - Gesture recognizers

- (void)jsq_handleTapGesture:(UITapGestureRecognizer *)tap
{
    CGPoint touchPt = [tap locationInView:self];

    if (CGRectContainsPoint(self.avatarContainerView.frame, touchPt)) {
        [self.delegate messagesCollectionViewCellDidTapAvatar:self];
    }
    else if (CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt)) {
        [self.delegate messagesCollectionViewCellDidTapMessageBubble:self];
    }
    else {
        [self.delegate messagesCollectionViewCellDidTapCell:self atPosition:touchPt];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchPt = [touch locationInView:self];

    if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return CGRectContainsPoint(self.messageBubbleContainerView.frame, touchPt);
    }
    
    return NO;
}

@end
