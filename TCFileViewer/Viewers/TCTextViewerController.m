//
//  TCTextViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2012-11-28.
//  Copyright (c) 2012 ThirdCog. All rights reserved.
//

#import "TCTextViewerController.h"

@implementation TCTextViewerController {
    UITextView *_textView;
    NSURL *_url;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
    if(!(self = [super initWithURL:path error:err])) return nil;
    NSString *contents = [NSString stringWithContentsOfURL:path encoding:NSUTF8StringEncoding error:err];
    if(!contents)
        return nil;
    
    _url = path;
    _textView = [[UITextView alloc] init];
    _textView.text = contents;
    self.title = path.lastPathComponent;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(save:)];
    
    return self;
}

- (void)loadView
{
    self.view = _textView;
}

- (IBAction)save:(id)sender
{
    NSError *err;
    if(![_textView.text writeToURL:_url atomically:NO encoding:NSUTF8StringEncoding error:&err]) {
        [[[UIAlertView alloc] initWithTitle:@"Couldn't save document" message:err.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
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
