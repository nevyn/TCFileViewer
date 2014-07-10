//
//  TCDictionaryViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2014-07-10.
//  Copyright (c) 2014 ThirdCog. All rights reserved.
//

#import "TCDictionaryViewerController.h"
#import "TCArrayViewerController.h"

@interface TCDictionaryViewerController () 
@property(nonatomic) NSDictionary *object;
@property(nonatomic) NSArray *keys;
@end

@implementation TCDictionaryViewerController
- (id)initWithObject:(NSDictionary*)object
{
	if(!(self = [super initWithStyle:UITableViewStylePlain]))
		return nil;
	
	self.object = object;
	self.keys = [[object allKeys] sortedArrayUsingSelector:@selector(compare:)];
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _keys.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *key = _keys[indexPath.row];
	id value = _object[key];
	
	UITableViewCell *cell = nil;
	if([value isKindOfClass:[NSDictionary class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"dictionaryCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"dictionaryCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu key/value pair%@", (unsigned long)[value count], [value count] > 1 ? @"s" : @""];
	} else if([value isKindOfClass:[NSArray class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"arrayCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"arrayCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu value%@", (unsigned long)[value count], [value count] > 1 ? @"s" : @""];

	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"descriptionCell"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		cell.detailTextLabel.text = [value description];
	}
	cell.textLabel.text = key;
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *key = _keys[indexPath.row];
	id value = _object[key];
	UIViewController *vc = nil;
	if([value isKindOfClass:[NSDictionary class]]) {
		vc = [[TCDictionaryViewerController alloc] initWithObject:value];
	} else if([value isKindOfClass:[NSArray class]]) {
		vc = [[TCArrayViewerController alloc] initWithObject:value];
	}
	if(vc) {
		vc.title = key;
		[self.navigationController pushViewController:vc animated:YES];
	}
}
@end
