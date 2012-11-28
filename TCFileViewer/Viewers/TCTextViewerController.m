//
//  TCTextViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2012-11-28.
//  Copyright (c) 2012 ThirdCog. All rights reserved.
//

#import "TCTextViewerController.h"

@implementation TCTextViewerController {
    NSString *_contents;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
    if(!(self = [super initWithURL:path error:err])) return nil;
    _contents = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:err];
    if(!_contents)
        return nil;
    self.title = path.lastPathComponent;
    return self;
}
- (void)loadView
{
    UITextView *tv = [[UITextView alloc] init];
    tv.text = _contents;
    self.view = tv;
}
+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return [@[@"txt", @"text", @"log", @"json", @"plist"] containsObject:url.pathExtension.lowercaseString];
}
+ (UIImage*)thumbIcon;
{
    return [UIImage imageNamed:@"GenericTextIcon"];
}

@end
