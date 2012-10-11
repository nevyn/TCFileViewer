#import "TCImageViewerController.h"

@implementation TCImageViewerController {
    UIImage *_image;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
    if(!(self = [super initWithURL:path error:err])) return nil;
    _image = [[UIImage alloc] initWithContentsOfFile:path.path];
    if(!_image)
        return nil;
    self.title = path.lastPathComponent;
    return self;
}
- (void)loadView
{
    self.view = [[UIImageView alloc] initWithImage:_image];
    self.view.contentMode = UIViewContentModeScaleAspectFit;
}
+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return [@[@"png", @"jpg", @"jpeg", @"tiff", @"tif", @"gif", @"bmp", @"ico", @"cur", @"xbm"] containsObject:url.pathExtension.lowercaseString];
}
+ (UIImage*)thumbIcon;
{
    return [UIImage imageNamed:@"GenericImageIcon"];
}
@end