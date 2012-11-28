//
//  TCVideoViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2012-11-28.
//  Copyright (c) 2012 ThirdCog. All rights reserved.
//

#import "TCVideoViewerController.h"
#import <MediaPlayer/MediaPlayer.h>

@implementation TCVideoViewerController {
    MPMoviePlayerController *_mpc;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
    if(!(self = [super initWithURL:path error:err])) return nil;
    _mpc = [[MPMoviePlayerController alloc] initWithContentURL:path];
    _mpc.shouldAutoplay = YES;
    [_mpc play];
    self.title = path.lastPathComponent;
    return self;
}
- (void)loadView
{
    self.view = _mpc.view;
}
+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return [@[@"mp4", @"m4v", @"mov", @"3gpp"] containsObject:url.pathExtension.lowercaseString];
}
+ (UIImage*)thumbIcon;
{
    return [UIImage imageNamed:@"GenericMovieIcon"];
}

@end
