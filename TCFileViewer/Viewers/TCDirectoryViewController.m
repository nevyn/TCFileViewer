#import "TCDirectoryViewController.h"

@interface TCDirectoryViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>
@end
@interface TCDirectoryCollectionViewCell : UICollectionViewCell
@property(strong) UILabel *textLabel;
@property(strong) UIImageView *imageView;
@end



static NSString *const kTCDirectoryCellIdentifier = @"DirectoryCell";

@implementation TCDirectoryViewController {
    NSArray *_contents;
}
+ (NSArray*)viewControllersForPathComponentsInURL:(NSURL*)url
{
    NSMutableArray *superPathsToBundle = [NSMutableArray array];
    NSMutableArray *vcs = [NSMutableArray array];
    
    for(NSString *subPath in [url pathComponents])
        if (superPathsToBundle.count == 0)
            [superPathsToBundle addObject:[NSURL fileURLWithPath:subPath]];
        else
            [superPathsToBundle addObject:[[superPathsToBundle lastObject] URLByAppendingPathComponent:subPath]];
    
    for(NSURL *path in superPathsToBundle) {
        id vc = [[TCDirectoryViewController alloc] initWithURL:path error:NULL];
        if (vc)
            [vcs addObject:vc];
    }
    return vcs;
}
- (id)initWithURL:(NSURL*)path error:(__autoreleasing NSError**)err
{
    if(!(self = [super init]))
        return nil;
    
    NSFileManager *nfm = [NSFileManager defaultManager];
    
    _contents = [nfm contentsOfDirectoryAtURL:path includingPropertiesForKeys:nil options:0 error:err];
    if(!_contents)
        return nil;
    
    self.title = [path lastPathComponent];
    
    return self;
}
- (void)loadView
{
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [UICollectionView class]) {
        UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
        layout.itemSize = CGSizeMake(110, 110);
        layout.minimumInteritemSpacing = 32;
        layout.minimumLineSpacing = 32;
        layout.sectionInset = UIEdgeInsetsMake(20, 32, 20, 32);
        UICollectionView *cv = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        cv.dataSource = self;
        cv.delegate = self;
        [cv registerClass:[TCDirectoryCollectionViewCell class] forCellWithReuseIdentifier:kTCDirectoryCellIdentifier];
        cv.backgroundColor = [UIColor whiteColor];
        self.view = cv;
    } else {
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero];
        tv.dataSource = self;
        tv.delegate = self;
        self.view = tv;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
        return YES;
    else
        return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewDidAppear:(BOOL)animated;
{
    if([self.view isKindOfClass:[UITableView class]])
        [(UITableView*)self.view deselectRowAtIndexPath:[(UITableView*)self.view indexPathForSelectedRow] animated:animated];
    else
        [(UICollectionView*)self.view deselectItemAtIndexPath:[(UICollectionView*)self.view indexPathsForSelectedItems].lastObject animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _contents.count;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _contents.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTCDirectoryCellIdentifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kTCDirectoryCellIdentifier];
    
    NSURL *item = [_contents objectAtIndex:indexPath.row];
    cell.textLabel.text = [item lastPathComponent];
    
    NSArray *viewers = [self viewersForURL:item];
    cell.imageView.image = viewers.count ? [viewers.lastObject thumbIcon] : [UIImage imageNamed:@"GenericDocumentIcon"];
    
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:item.path isDirectory:&isDir];
    cell.accessoryType = isDir ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}
- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *item = [_contents objectAtIndex:indexPath.row];
    
    TCDirectoryCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kTCDirectoryCellIdentifier forIndexPath:indexPath];
    cell.textLabel.text = [item lastPathComponent];
    
    NSArray *viewers = [self viewersForURL:item];
    cell.imageView.image = viewers.count ? [viewers.lastObject thumbIcon] : [UIImage imageNamed:@"GenericDocumentIcon"];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *item = [_contents objectAtIndex:indexPath.row];
    
    NSArray *matchingViewers = [self viewersForURL:item];

    NSError *err = NULL;
    id viewer = [[[matchingViewers lastObject] alloc] initWithURL:item error:&err];
    if(viewer) {
        [self.navigationController pushViewController:viewer animated:YES];
    } else {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if(matchingViewers.count == 0)
            err = [[NSError alloc] initWithDomain:@"TCDirectoryViewer" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"There's no viewer registered for documents like %@.", item.lastPathComponent]}];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't show document" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    NSURL *item = [_contents objectAtIndex:indexPath.row];
    
    NSArray *matchingViewers = [self viewersForURL:item];

    NSError *err = NULL;
    id viewer = [[[matchingViewers lastObject] alloc] initWithURL:item error:&err];
    if(viewer) {
        [self.navigationController pushViewController:viewer animated:YES];
    } else {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        if(matchingViewers.count == 0)
            err = [[NSError alloc] initWithDomain:@"TCDirectoryViewer" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"There's no viewer registered for documents like %@.", item.lastPathComponent]}];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't show document" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark
+ (BOOL)canViewDocumentAtURL:(NSURL*)url
{
    BOOL isDir = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:url.path isDirectory:&isDir];
    return isDir;
}

+ (UIImage*)thumbIcon;
{
    return [UIImage imageNamed:@"GenericFolderIcon"];
}


@end


@implementation TCDirectoryCollectionViewCell
- (id)initWithFrame:(CGRect)frame // 110, 110
{
    if(!(self = [super initWithFrame:frame]))
        return self;
    
    CGRect imageFrame = CGRectMake((110-64)/2, 0, 64, 64);
    CGRect textFrame  = CGRectMake(0, 64, 110, 110-64);
    
    self.imageView = [[UIImageView alloc] initWithFrame:imageFrame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.imageView];
    self.textLabel = [[UILabel alloc] initWithFrame:textFrame];
    self.textLabel.textAlignment = UITextAlignmentCenter;
    self.textLabel.font = [UIFont systemFontOfSize:14];
    self.textLabel.numberOfLines = 2;
    [self.contentView addSubview:self.textLabel];
    
    NSLog(@":: %@", [self performSelector:@selector(recursiveDescription)]);
    
    return self;
}
@end

