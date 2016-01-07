//
//  AppDelegate.m
//  TrivialQuest2
//
//  Copyright (c) 2014 Google. All rights reserved.
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

#import "AppDelegate.h"
#import "ViewController.h"
#import <GoogleSignIn.h>
#import "gpg/GooglePlayGames.h"

@interface AppDelegate ()<GPGQuestDelegate, GPGQuestListLauncherDelegate, GPGLauncherDelegate>

@end

@implementation AppDelegate
/** Handles the URL for Sign-In.
 *  @param application The app receiving the URL.
 *  @param url The URL passed to the app.
 *  @param sourceApplication The
 */
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    NSLog(@"URL received");
    return [[GIDSignIn sharedInstance] handleURL:url sourceApplication:sourceApplication annotation:annotation];
}

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GPGLauncherController sharedInstance].launcherDelegate = self;
  [GPGLauncherController sharedInstance].questListLauncherDelegate = self;
    // Override point for customization after application launch.
    return YES;
}

/** Message handler for when a user accepts a quest from the quest list.
 *  @param quest The quest that the user accepted.
 */
-(void)questListLauncherDidAcceptQuest:(GPGQuest *)quest {
  NSLog(@"The \"%@\" quest with id %@ has been accepted.", quest.name,
        quest.questId);
}

/** Message handler for when the player accepts a reward for a quest.
 *  @param questMilestone An object representing an important progression point within the quest.
 */
- (void)questListLauncherDidClaimRewardsForQuestMilestone:(GPGQuestMilestone *)questMilestone {
  [questMilestone claimWithCompletionHandler:^(NSError *error) {
    NSLog(@"Quest reward with id %@ has been claimed.", questMilestone.questMilestoneId);
  }];
}

/** Handler for when the Play Games quest picker is present.
 *  @param launcherController The controller that is managing the view.
 *  @return The ViewController with the launcher controller and this ViewController's View.
 */
- (UIViewController *)presentingViewControllerForLauncher {
  return self.window.rootViewController;
}

@end
