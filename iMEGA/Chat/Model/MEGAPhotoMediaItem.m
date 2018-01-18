
#import "MEGAPhotoMediaItem.h"

#import "JSQMessagesMediaPlaceholderView.h"

#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAGetPreviewRequestDelegate.h"

#import <MobileCoreServices/UTCoreTypes.h>

@interface MEGAPhotoMediaItem ()

@property (strong, nonatomic) UIImageView *cachedImageView;
@property (strong, nonatomic) UIView *activityIndicator;

@end

@implementation MEGAPhotoMediaItem

- (instancetype)initWithMEGANode:(MEGANode *)node {
    self = [super init];
    if (self) {
        _node = node;
        
        CGSize size = [self mediaViewDisplaySize];
        _cachedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
        _cachedImageView.contentMode = UIViewContentModeScaleAspectFill;
        _cachedImageView.clipsToBounds = YES;
        _cachedImageView.layer.cornerRadius = 5;
        _cachedImageView.backgroundColor = [UIColor whiteColor];
        
        NSString *previewFilePath = [[[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"previewsV3"] stringByAppendingPathComponent:self.node.base64Handle];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:previewFilePath]) {
            [self configureCachedImageViewWithImagePath:previewFilePath];
        } else {
            if ([self.node hasPreview]) {
                _activityIndicator = [JSQMessagesMediaPlaceholderView viewWithActivityIndicator];
                _activityIndicator.frame = _cachedImageView.frame;
                [_cachedImageView addSubview:_activityIndicator];
                MEGAGetPreviewRequestDelegate *getPreviewRequestDelegate = [[MEGAGetPreviewRequestDelegate alloc] initWithCompletion:^(MEGARequest *request) {
                    [self configureCachedImageViewWithImagePath:request.file];
                    [_activityIndicator removeFromSuperview];
                }];
                [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
                [[MEGASdkManager sharedMEGASdk] getPreviewNode:self.node destinationFilePath:previewFilePath delegate:getPreviewRequestDelegate];
            } else {
                [self.cachedImageView mnz_setImageForExtension:self.node.name.pathExtension];
            }
        }

        if (@available(iOS 11.0, *)) {
            self.cachedImageView.accessibilityIgnoresInvertColors = YES;
        }
    }
    return self;
}

- (void)clearCachedMediaViews {
    [super clearCachedMediaViews];
    _cachedImageView = nil;
}

- (void)setNode:(MEGANode *)node {
    _node = [node copy];
    _cachedImageView = nil;
}

- (void)setAppliesMediaViewMaskAsOutgoing:(BOOL)appliesMediaViewMaskAsOutgoing {
    [super setAppliesMediaViewMaskAsOutgoing:appliesMediaViewMaskAsOutgoing];
    _cachedImageView = nil;
}

- (CGSize)mediaViewDisplaySize {
    const CGFloat kMaxBubbleWidth = 566.0f;
    CGFloat displaySize = [[UIScreen mainScreen] bounds].size.width - 92; // 75 + 17, by design
    if (displaySize > kMaxBubbleWidth) {
        displaySize = kMaxBubbleWidth;
    }
    return CGSizeMake(displaySize, displaySize);
}

- (UIView *)mediaPlaceholderView {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [indicator startAnimating];
    return indicator;
}

#pragma mark - Private

- (void)configureCachedImageViewWithImagePath:(NSString *)imagePath {
    _cachedImageView.image = [UIImage imageWithContentsOfFile:imagePath];

    [self.activityIndicator removeFromSuperview];
    if (self.node.name.mnz_isMultimediaPathExtension) {
        UIImageView *playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"video_list"]];
        playImageView.center = _cachedImageView.center;
        [_cachedImageView addSubview:playImageView];
    }
}

#pragma mark - JSQMessageMediaData protocol

- (UIView *)mediaView {
    return self.cachedImageView;
}

- (NSUInteger)mediaHash {
    return self.hash;
}

- (NSString *)mediaDataType {
    return (NSString *)kUTTypeJPEG;
}

- (id)mediaData {
    return UIImageJPEGRepresentation(self.image, 1);
}

#pragma mark - NSObject

- (NSUInteger)hash {
    return super.hash ^ self.image.hash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: image=%@, appliesMediaViewMaskAsOutgoing=%@>",
            [self class], self.image, @(self.appliesMediaViewMaskAsOutgoing)];
}

#pragma mark - NSCoding

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        _node = [aDecoder decodeObjectForKey:NSStringFromSelector(@selector(node))];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.node forKey:NSStringFromSelector(@selector(node))];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(NSZone *)zone {
    MEGAPhotoMediaItem *copy = [[MEGAPhotoMediaItem allocWithZone:zone] initWithMEGANode:self.node];
    copy.appliesMediaViewMaskAsOutgoing = self.appliesMediaViewMaskAsOutgoing;
    return copy;
}

@end