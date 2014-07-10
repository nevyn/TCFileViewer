//
//  TCJSONViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2014-07-10.
//  Copyright (c) 2014 ThirdCog. All rights reserved.
//

#import "TCJSONViewerController.h"
#import "TCArrayViewerController.h"
#import "TCDictionaryViewerController.h"

@implementation TCJSONViewerController
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
	id json = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfURL:path options:0 error:err] options:0 error:err];
	if(!json)
		return nil;
	
	if([json isKindOfClass:[NSArray class]]) {
		TCArrayViewerController *avc = [[TCArrayViewerController alloc] initWithObject:json];
		avc.title = path.lastPathComponent;
		return (id)avc;
	} else if([json isKindOfClass:[NSDictionary class]]) {
		TCDictionaryViewerController *dvc = [[TCDictionaryViewerController alloc] initWithObject:json];
		dvc.title = path.lastPathComponent;
		return (id)dvc;
	}
	
	return nil;
}

+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    return [@[@"json"] containsObject:url.pathExtension.lowercaseString];
}

@end
