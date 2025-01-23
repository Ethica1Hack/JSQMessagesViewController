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

#import "JSQMediaItem.h"
#import "JSQMessagesMediaPlaceholderView.h"
#import "JSQMessagesMediaViewBubbleImageMasker.h"

@interface JSQMediaItem ()
@property (strong, nonatomic, nullable) UIView *cachedPlaceholderView;
@end

@implementation JSQMediaItem

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithMaskAsOutgoing:YES];
}

- (instancetype)initWithMaskAsOutgoing:(BOOL)maskAsOutgoing {
    self = [super init];
    if (self) {
        _appliesMediaViewMaskAsOutgoing = maskAsOutgoing;
        _cachedPlaceholderView = nil;

        __weak typeof(self) weakSelf = self;
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification * _Nonnull note) {
            [weakSelf clearCachedMediaViews];
        }];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Property Setters

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    if (_appliesMediaViewMaskAsOutgoing != appliesMediaViewMaskAsOutgoing) {
        _appliesMediaViewMaskAsOutgoing = appliesMediaViewMaskAsOutgoing;
        _cachedPlaceholderView = nil; // Clear cached view if outgoing state changes
    }
}

#pragma mark - Public Methods

- (void)clearCachedMediaViews {
    if (_cachedPlaceholderView != nil) {
        _cachedPlaceholderView = nil;
    }
}

#pragma mark - JSQMessageMediaData Protocol

- (UIView *)mediaView {
    NSAssert(NO, @"Required method not implemented in subclass. Implement %s", __PRETTY_FUNCTION__);
    return nil;
}

- (CGSize)mediaViewDisplaySize {
    return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ?
    CGSizeMake(315.0f, 225.0f) :
    CGSizeMake(210.0f, 150.0f);
}

- (UIView *)mediaPlaceholderView {
    if (!_cachedPlaceholderView) {
        CGSize size = [self mediaViewDisplaySize];
        UIView *view = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
        view.frame = CGRectMake(0.0f, 0.0f, size.width, size.height);

        [JSQMessagesMediaViewBubbleImageMasker applyBubbleImageMaskToMediaView:view
                                                                  isOutgoing:self.appliesMediaViewMaskAsOutgoing];
        _cachedPlaceholderView = view;
    }
    return _cachedPlaceholderView;
}

- (NSUInteger)mediaHash {
    return self.hash;
}

#pragma mark - NSObject Overrides

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }

    if (![object isKindOfClass:[self class]]) {
        return NO;
    }

    JSQMediaItem *item = (JSQMediaItem *)object;
    return self.appliesMediaViewMaskAsOutgoing == item.appliesMediaViewMaskAsOutgoing;
}

- (NSUInteger)hash {
    // Use modern hashing API
    return [@(self.appliesMediaViewMaskAsOutgoing) hash];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: appliesMediaViewMaskAsOutgoing=%@>",
            NSStringFromClass([self class]), @(self.appliesMediaViewMaskAsOutgoing)];
}

- (id)debugQuickLookObject {
    return [self mediaView] ?: [self mediaPlaceholderView];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _appliesMediaViewMaskAsOutgoing = [aDecoder decodeBoolForKey:NSStringFromSelector(@selector(appliesMediaViewMaskAsOutgoing))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeBool:self.appliesMediaViewMaskAsOutgoing forKey:NSStringFromSelector(@selector(appliesMediaViewMaskAsOutgoing))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    return [[[self class] allocWithZone:zone] initWithMaskAsOutgoing:self.appliesMediaViewMaskAsOutgoing];
}

@end
