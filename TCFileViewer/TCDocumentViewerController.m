#import "TCDirectoryViewController.h"
#import <objc/runtime.h>



@implementation TCDocumentViewerController
+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return NO;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err;
{
    self.restorationIdentifier = path.absoluteString;
    return [super init];
}
+ (UIImage*)thumbIcon;
{
    return [UIImage imageNamed:@"GenericDocumentIcon"];
}

+ (NSArray *)viewerClasses
{
    __unsafe_unretained Class *buffer = NULL;
    
    int count, size;
    do
    {
        count = objc_getClassList(NULL, 0);
        buffer = (__unsafe_unretained Class *)realloc(buffer, count * sizeof(*buffer));
        size = objc_getClassList(buffer, count);
    } while(size != count);
    
    NSMutableArray *array = [NSMutableArray array];
    for(int i = 0; i < count; i++)
    {
        Class candidate = buffer[i];
        Class superclass = candidate;
        while(superclass)
        {
            if(superclass == [TCDocumentViewerController class])
            {
                [array addObject:candidate];
                break;
            }
            superclass = class_getSuperclass(superclass);
        }
    }
    free(buffer);
    return array;
}

- (NSArray*)viewersForURL:(NSURL*)url
{
    NSMutableArray *matchingViewers = [NSMutableArray array];
    for(Class candidate in [[self class] viewerClasses])
        if([candidate canViewDocumentAtURL:url])
            [matchingViewers addObject:candidate];
    return matchingViewers;
}

@end

