//
//  AppDelegate.m
//  TypeNumber
//
//  Created by Todd Kerpelman on 9/24/12.
//  Copyright (c) 2012 Google. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import <GoogleOpenSource/GoogleOpenSource.h>
#import <GoogleOpenSource/GTLBase64.h>
#import "AppDelegate.h"
#import "Constants.h"


@implementation AppDelegate

 - (void)didReceiveDeepLink: (GPPDeepLink *)deepLink
{
  NSString *deepLinkID = [deepLink deepLinkID];
  NSData *decodedData = GTLDecodeWebSafeBase64(deepLinkID);
  if (!decodedData) return;
  
  self.deepLinkParams = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:decodedData options:0 error:nil];
  NSLog(@"Deep link ID is %@",deepLinkID);
  
  NSLog(@"This is my dictionary %@",self.deepLinkParams);
  if( self.challengeReceivedHandler != nil )
    self.challengeReceivedHandler();

}

-(BOOL)application:(UIApplication *)application
           openURL:(NSURL *)url
 sourceApplication:(NSString *)sourceApplication
        annotation:(id)annotation
{
  NSLog(@"I am receiving the URL %@", [url absoluteString]);
  BOOL canRespond = [GPPURLHandler handleURL:url sourceApplication:sourceApplication annotation:annotation];
  if (canRespond) {
    return YES;
  } else {
    // There might be other things you'd want to do here
    return NO;
  }
  
}

# pragma mark - Standard app delegate methods


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
  // Check and see if I can sign in "silently" beause I've signed in before,
  // and/or there's a saved token in our keychain. If so, go for it.
  // This will call our finishedWithAuth delegate if true.
  [GPPDeepLink setDelegate:self];
  [GPPDeepLink readDeepLinkAfterInstall];
  
  return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
  // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
  // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
  // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
  // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
  // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
  // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
  // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
