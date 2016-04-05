//
//  AppDelegate.m
//  MVViewer
//
//  Created by Jack Yu on 7/1/2016.
//
//

#import "AppDelegate.h"
#import "ARViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

@synthesize window;
@synthesize viewController;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
    // Override point for customization after app launch
    
    // Set working directory so that camera parameters, models etc. can be loaded using relative paths.
    arUtilChangeToResourcesDirectory(AR_UTIL_RESOURCES_DIRECTORY_BEHAVIOR_BEST, NULL);
    
    [self.window setRootViewController:self.viewController];
    [window makeKeyAndVisible];
}

// Application has been interrupted, by e.g. a phone call.
- (void)applicationWillResignActive:(UIApplication *)application {
    viewController.paused = TRUE;
}

// The interruption ended.
- (void)applicationDidBecomeActive:(UIApplication *)application {
    viewController.paused = FALSE;
}

// User pushed home button. Save state etc.
- (void)applicationWillTerminate:(UIApplication *)application {
    //
}

- (void)dealloc {
}

@end