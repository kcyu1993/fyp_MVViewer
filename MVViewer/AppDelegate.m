//
//  AppDelegate.m
//  MVViewer
//
//  Created by Jack Yu on 7/1/2016.
//
//

/*#import "AppDelegate.h"
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

@end*/

#import "AppDelegate.h"
#import <CRToast/CRToast.h>

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [CRToastManager setDefaultOptions:@{kCRToastNotificationTypeKey : @(CRToastTypeNavigationBar),
                                        kCRToastFontKey             : [UIFont fontWithName:@"HelveticaNeue-Light" size:16],
                                        kCRToastTextColorKey        : [UIColor whiteColor],
                                        kCRToastBackgroundColorKey  : [UIColor blueColor],
                                        kCRToastAutorotateKey       : @(YES)}];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end