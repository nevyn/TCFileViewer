#import "TCDirectoryViewController.h"

@interface TCDirectoryViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UIActionSheetDelegate>
@end
@interface TCDirectoryCollectionViewCell : UICollectionViewCell
@property(strong) UILabel *textLabel;
@property(strong) UIImageView *imageView;
@end

// Forwarded like this because we only want to use it if it's compiled into the host app
@interface TCDVDirectoryWatcher : NSObject
@property(nonatomic,weak) id delegate;
+ (TCDVDirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id)watchDelegate;
- (void)invalidate;
@end


static NSString *const kTCDirectoryCellIdentifier = @"DirectoryCell";

@implementation TCDirectoryViewController {
    NSArray *_contents;
    TCDVDirectoryWatcher *_watcher;
    NSURL *_path;
    NSURL *_pathToDelete;
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
    
    _path = path;
    
    NSFileManager *nfm = [NSFileManager defaultManager];
    _contents = [nfm contentsOfDirectoryAtURL:path includingPropertiesForKeys:nil options:0 error:err];
    if(!_contents)
        return nil;
    
    if([TCDVDirectoryWatcher class])
        _watcher = [TCDVDirectoryWatcher watchFolderWithPath:path.path delegate:self];
    
    self.title = [path lastPathComponent];
    
    return self;
}
- (void)dealloc
{
    [_watcher invalidate];
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

- (void)directoryDidChange:(TCDVDirectoryWatcher *)folderWatcher
{
    NSFileManager *nfm = [NSFileManager defaultManager];
    _contents = [nfm contentsOfDirectoryAtURL:_path includingPropertiesForKeys:nil options:0 error:NULL];

    [(UITableView*)self.view reloadData];
}

- (unsigned long long int)folderSize:(NSURL *)parent
{
    NSDictionary *parentAttrs = [[NSFileManager defaultManager] attributesOfItemAtPath:parent.path error:NULL];
    if(![parentAttrs.fileType isEqual:NSFileTypeDirectory])
        return parentAttrs.fileSize;
    
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:parent.path error:nil];
    unsigned long long int fileSize = 0;
    for(NSString *fileName in filesArray) {
        NSURL *fullPath = [parent URLByAppendingPathComponent:fileName];
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:fullPath.path error:NULL];
        fileSize += [fileDictionary fileSize];
    }

    return fileSize;
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

// http://stackoverflow.com/a/572623/48125
static NSString *stringFromFileSize(unsigned long long theSize)
{
    double floatSize = theSize;
    if (theSize<1023)
        return([NSString stringWithFormat:@"%lli bytes",theSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f KB",floatSize]);
    floatSize = floatSize / 1024;
    if (floatSize<1023)
        return([NSString stringWithFormat:@"%1.1f MB",floatSize]);
    floatSize = floatSize / 1024;

    return([NSString stringWithFormat:@"%1.1f GB",floatSize]);
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kTCDirectoryCellIdentifier];
    if(!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kTCDirectoryCellIdentifier];
    
    NSURL *item = [_contents objectAtIndex:indexPath.row];
    cell.textLabel.text = [item lastPathComponent];
    
    NSDate *modified = [[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:NULL].fileModificationDate;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", stringFromFileSize([self folderSize:item]), modified];
    
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
    
    if([viewer isKindOfClass:[self class]]) {
        [viewer setDelegate:self.delegate];
    }
    
    if(viewer) {
        if(!_delegate || [_delegate directoryViewer:self shouldPresentContentViewController:viewer]) {
            [self.navigationController pushViewController:viewer animated:YES];
        }
    } else {
        [collectionView deselectItemAtIndexPath:indexPath animated:YES];
        if(matchingViewers.count == 0)
            err = [[NSError alloc] initWithDomain:@"TCDirectoryViewer" code:1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"There's no viewer registered for documents like %@.", item.lastPathComponent]}];
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Can't show document" message:err.localizedDescription delegate:nil cancelButtonTitle:@"Cancel" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    _pathToDelete = [_contents objectAtIndex:indexPath.row];
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"Delete %@?", [_pathToDelete lastPathComponent]] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"Delete" otherButtonTitles: nil];
    [sheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
    if(buttonIndex != [actionSheet destructiveButtonIndex])
        return;
    
    NSError *err;
    if(![[NSFileManager defaultManager] removeItemAtURL:_pathToDelete error:&err])
        [[[UIAlertView alloc] initWithTitle:@"Failed to delete" message:err.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return action == @selector(cut:);
}
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    [self tableView:nil commitEditingStyle:0 forRowAtIndexPath:indexPath];
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
    
    return self;
}
@end

