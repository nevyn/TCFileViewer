#import <UIKit/UIKit.h>

// Subclass this to register viewers for different document types
@interface TCDocumentViewerController : UIViewController
+ (BOOL)canViewDocumentAtURL:(NSURL*)url;
+ (UIImage*)thumbIcon;
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err;

- (NSArray*)viewersForURL:(NSURL*)url;
@end
