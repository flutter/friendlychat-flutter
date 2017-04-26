#include "AppDelegate.h"
#include "FirebaseAnalyticsPlugin.h"
#include "FirebaseAuthPlugin.h"
#include "FirebaseDatabasePlugin.h"
#include "FirebaseStoragePlugin.h"
#include "GoogleSignInPlugin.h"
#include "ImagePickerPlugin.h"

@implementation AppDelegate {
  FirebaseAnalyticsPlugin *_firebaseAnalyticsPlugin;
  FirebaseAuthPlugin *_firebaseAuthPlugin;
  FirebaseDatabasePlugin *_firebaseDatabasePlugin;
  FirebaseStoragePlugin *_firebaseStoragePlugin;
  GoogleSignInPlugin *_googleSignInPlugin;
  ImagePickerPlugin *_imagePickerPlugin;
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  FlutterViewController *flutterController =
      (FlutterViewController *)self.window.rootViewController;
  _firebaseAnalyticsPlugin =
      [[FirebaseAnalyticsPlugin alloc] initWithController:flutterController];
  _firebaseAuthPlugin =
      [[FirebaseAuthPlugin alloc] initWithController:flutterController];
  _firebaseDatabasePlugin =
      [[FirebaseDatabasePlugin alloc] initWithController:flutterController];
  _firebaseStoragePlugin =
      [[FirebaseStoragePlugin alloc] initWithController:flutterController];
  _googleSignInPlugin =
      [[GoogleSignInPlugin alloc] initWithController:flutterController];
  _imagePickerPlugin =
      [[ImagePickerPlugin alloc] initWithController:flutterController];
  return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
  NSString *sourceApplication =
      options[UIApplicationOpenURLOptionsSourceApplicationKey];
  id annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
  return [_googleSignInPlugin handleURL:url
                      sourceApplication:sourceApplication
                             annotation:annotation];
}

@end
