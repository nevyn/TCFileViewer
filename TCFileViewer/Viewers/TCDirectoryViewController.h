#import "TCDocumentViewerController.h"

@interface TCDirectoryViewController : TCDocumentViewerController
+ (NSArray*)viewControllersForPathComponentsInURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err;
@end

