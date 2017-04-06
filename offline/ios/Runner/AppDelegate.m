#include "AppDelegate.h"

@implementation AppDelegate {
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    FlutterViewController* flutterController = (FlutterViewController*)self.window.rootViewController;
    return YES;
}

@end
