#import "TCDVDirectoryWatcher.h"

#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>

#import <CoreFoundation/CoreFoundation.h>

@interface TCDVDirectoryWatcher ()
{
	int dirFD;
    int kq;

	CFFileDescriptorRef dirKQRef;
}
- (BOOL)startMonitoringDirectory:(NSString *)dirPath;
- (void)kqueueFired;
@end


#pragma mark -

@implementation TCDVDirectoryWatcher

- (id)init
{
	self= [super init];
	_delegate = NULL;

	dirFD = -1;
    kq = -1;
	dirKQRef = NULL;
	
	return self;
}

- (void)dealloc
{
	[self invalidate];
}

+ (TCDVDirectoryWatcher *)watchFolderWithPath:(NSString *)watchPath delegate:(id)watchDelegate
{
    TCDVDirectoryWatcher *tempManager = [[TCDVDirectoryWatcher alloc] init];
    tempManager.delegate = watchDelegate;		
    if ([tempManager startMonitoringDirectory: watchPath])
        return tempManager;
    return nil;
}

- (void)invalidate
{
	if (dirKQRef != NULL)
	{
		CFFileDescriptorInvalidate(dirKQRef);
		CFRelease(dirKQRef);
		dirKQRef = NULL;
		// We don't need to close the kq, CFFileDescriptorInvalidate closed it instead.
		// Change the value so no one thinks it's still live.
		kq = -1;
	}
	
	if(dirFD != -1)
	{
		close(dirFD);
		dirFD = -1;
	}
}

- (void)kqueueFired
{
    assert(kq >= 0);

    struct kevent   event;
    struct timespec timeout = {0, 0};
    int             eventCount;
	
    eventCount = kevent(kq, NULL, 0, &event, 1, &timeout);
    assert((eventCount >= 0) && (eventCount < 2));
    
	// call our delegate of the directory change
    [_delegate directoryDidChange:self];

    CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
}

static void KQCallback(CFFileDescriptorRef kqRef, CFOptionFlags callBackTypes, void *info)
{
    TCDVDirectoryWatcher *obj = (__bridge TCDVDirectoryWatcher *)info;
    assert([obj isKindOfClass:[TCDVDirectoryWatcher class]]);
    assert(kqRef == obj->dirKQRef);
    assert(callBackTypes == kCFFileDescriptorReadCallBack);
	
    [obj kqueueFired];
}

- (BOOL)startMonitoringDirectory:(NSString *)dirPath
{
	// Double initializing is not going to work...
	if ((dirKQRef == NULL) && (dirFD == -1) && (kq == -1))
	{
		// Open the directory we're going to watch
		dirFD = open([dirPath fileSystemRepresentation], O_EVTONLY);
		if (dirFD >= 0)
		{
			// Create a kqueue for our event messages...
			kq = kqueue();
			if (kq >= 0)
			{
				struct kevent eventToAdd;
				eventToAdd.ident  = dirFD;
				eventToAdd.filter = EVFILT_VNODE;
				eventToAdd.flags  = EV_ADD | EV_CLEAR;
				eventToAdd.fflags = NOTE_WRITE;
				eventToAdd.data   = 0;
				eventToAdd.udata  = NULL;
				
				int errNum = kevent(kq, &eventToAdd, 1, NULL, 0, NULL);
				if (errNum == 0)
				{
					CFFileDescriptorContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
					CFRunLoopSourceRef      rls;

					// Passing true in the third argument so CFFileDescriptorInvalidate will close kq.
					dirKQRef = CFFileDescriptorCreate(NULL, kq, true, KQCallback, &context);
					if (dirKQRef != NULL)
					{
						rls = CFFileDescriptorCreateRunLoopSource(NULL, dirKQRef, 0);
						if (rls != NULL)
						{
							CFRunLoopAddSource(CFRunLoopGetCurrent(), rls, kCFRunLoopDefaultMode);
							CFRelease(rls);
							CFFileDescriptorEnableCallBacks(dirKQRef, kCFFileDescriptorReadCallBack);
							
							// If everything worked, return early and bypass shutting things down
							return YES;
						}
						// Couldn't create a runloop source, invalidate and release the CFFileDescriptorRef
						CFFileDescriptorInvalidate(dirKQRef);
                        CFRelease(dirKQRef);
						dirKQRef = NULL;
					}
				}
				// kq is active, but something failed, close the handle...
				close(kq);
				kq = -1;
			}
			// file handle is open, but something failed, close the handle...
			close(dirFD);
			dirFD = -1;
		}
	}
	return NO;
}
@end
