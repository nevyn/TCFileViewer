/*
     File: DirectoryWatcher.h 
 Abstract: 
 Object used to monitor the contents of a given directory by using
 "kqueue": a kernel event notification mechanism.
  
  Version: 1.4 
  
 */

#import <Foundation/Foundation.h>
@protocol DirectoryWatcherDelegate;

@interface TCDVDirectoryWatcher : NSObject
@property(nonatomic,weak) id <DirectoryWatcherDelegate> delegate;
+ (TCDVDirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id<DirectoryWatcherDelegate>)watchDelegate;
- (void)invalidate;
@end

@protocol DirectoryWatcherDelegate <NSObject>
@required
- (void)directoryDidChange:(TCDVDirectoryWatcher *)folderWatcher;
@end