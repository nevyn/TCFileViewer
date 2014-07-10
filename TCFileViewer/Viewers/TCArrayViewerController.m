//
//  TCDictionaryViewerController.m
//  TCFileViewer
//
//  Created by Joachim Bengtsson on 2014-07-10.
//  Copyright (c) 2014 ThirdCog. All rights reserved.
//

#import "TCArrayViewerController.h"
#import "TCDictionaryViewerController.h"

@interface TCArrayViewerController ()
@property(nonatomic) NSArray *object;
@end

@implementation TCArrayViewerController
- (id)initWithObject:(NSArray*)object
{
	if(!(self = [super initWithStyle:UITableViewStylePlain]))
		return nil;
	
	self.object = object;
	return self;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return _object.count;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	id value = _object[indexPath.row];
	
	UITableViewCell *cell = nil;
	if([value isKindOfClass:[NSDictionary class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"dictionaryCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"dictionaryCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		cell.textLabel.text = [NSString stringWithFormat:@"%lu key/value pair%@", (unsigned long)[value count], [value count] > 1 ? @"s" : @""];
	} else if([value isKindOfClass:[NSArray class]]) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"arrayCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"arrayCell"];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		cell.textLabel.text = [NSString stringWithFormat:@"%lu value%@", (unsigned long)[value count], [value count] > 1 ? @"s" : @""];

	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"descriptionCell"];
		if(!cell) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"descriptionCell"];
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
		}
		cell.textLabel.text = [value description];
	}
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	id value = _object[indexPath.row];
	UIViewController *vc = nil;
	if([value isKindOfClass:[NSDictionary class]]) {
		vc = [[TCDictionaryViewerController alloc] initWithObject:value];
	} else if([value isKindOfClass:[NSArray class]]) {
		vc = [[TCArrayViewerController alloc] initWithObject:value];
	}
	if(vc) {
		vc.title = [NSString stringWithFormat:@"%ld", (long)indexPath.row];
		[self.navigationController pushViewController:vc animated:YES];
	}

}
@end
