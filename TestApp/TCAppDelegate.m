#import "TCAppDelegate.h"
#import "TCDirectoryViewController.h"

@implementation TCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    NSURL *bundlePath = [[NSBundle mainBundle] bundleURL];

    UINavigationController *nav = [[UINavigationController alloc] init];
    nav.viewControllers = [TCDirectoryViewController viewControllersForPathComponentsInURL:bundlePath];
    _window.rootViewController = nav;
    [self.window makeKeyAndVisible];
    
    return YES;
}
@end
