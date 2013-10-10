#import "TCDocumentViewerController.h"
@protocol TCDirectoryViewerControllerDelegate;

@interface TCDirectoryViewController : TCDocumentViewerController
@property(weak) id<TCDirectoryViewerControllerDelegate> delegate;
+ (NSArray*)viewControllersForPathComponentsInURL:(NSURL*)url;
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err;
@end

@protocol TCDirectoryViewerControllerDelegate <NSObject>
/** When selecting an item in the directory, a viewer for it will be fetched. If you return
    YES, it will be pushed on its navigation controller. */
- (BOOL)directoryViewer:(TCDirectoryViewController*)vc shouldPresentContentViewController:(TCDocumentViewerController*)document;
@end