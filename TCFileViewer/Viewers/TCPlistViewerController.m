#import "TCPlistViewerController.h"
#import "TCArrayViewerController.h"
#import "TCDictionaryViewerController.h"

@implementation TCPlistViewerController
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
	id plist = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfURL:path options:0 error:err] options:0 format:nil error:err];
	if(!plist)
		return nil;
	
	if([plist isKindOfClass:[NSArray class]]) {
		TCArrayViewerController *avc = [[TCArrayViewerController alloc] initWithObject:plist];
		avc.title = path.lastPathComponent;
		return (id)avc;
	} else if([plist isKindOfClass:[NSDictionary class]]) {
		TCDictionaryViewerController *dvc = [[TCDictionaryViewerController alloc] initWithObject:plist];
		dvc.title = path.lastPathComponent;
		return (id)dvc;
	}
	
	return nil;
}

+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return [@[@"plist"] containsObject:url.pathExtension.lowercaseString];
}

@end
