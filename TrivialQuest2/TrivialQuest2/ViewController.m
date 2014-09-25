//
//  ViewController.m
//  TrivialQuest2
//
//  Created by Gus Class on 5/13/14.
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
#import "ViewController.h"
#import "Constants.h"

@interface ViewController()<GPGStatusDelegate>

@end

@implementation ViewController
/** Initializes all of the Google services when the view loads and signs the user in. */
- (void)viewDidLoad
{
  [super viewDidLoad];

  NSLog(@"Init");
  [GPGManager sharedInstance].statusDelegate = self;
  [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:YES];

  [self refreshButtons];
}

/** Show the Quest Chooser */
- (IBAction)ShowQuests:(id)sender {
  [[GPGLauncherController sharedInstance] presentQuestList];
}

/** Show a toast with Event details. */
- (IBAction)ShowEvents:(id)sender {
  NSLog(@"---- Showing Event Counts -----");
  NSArray* events = [NSArray arrayWithObjects:  BLUE_MONSTER_EVENT_ID, GREEN_MONSTER_EVENT_ID,
                     RED_MONSTER_EVENT_ID, YELLOW_MONSTER_EVENT_ID, nil];
  NSArray* labels = [NSArray arrayWithObjects: @"Blue", @"Green", @"Red", @"Yellow", nil];

  for (int i=0; i < 4; i++){
    [GPGEvent eventForId:events[i] completionHandler:^(GPGEvent *event, NSError *error) {
      if (event){
        int count = (int)event.count;
        NSLog(@"%@ Monster: %d", labels[i], count);
      }
    }];
  }
}
/** Simulates attacking a "blue" monster in-game.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)attackBlue:(id)sender {
  [GPGEvent eventForId:BLUE_MONSTER_EVENT_ID
     completionHandler:^(GPGEvent *event, NSError *error) {
       NSLog(@"Event: %@ Error: %@", event, error);
       if (event){
         [event increment];
         NSLog(@"BLUE count incremented, now: %llxl", event.count);
       }else{
         NSLog(@"Error while incrementing count: %@", error);
       }
     }];
  NSLog(@"Attacked a blue monster.");
}

/** Simulates attacking a "green" monster in-game.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)attackGreen:(id)sender {
  NSLog(@"Attacked a green monster.");

  [GPGEvent eventForId:GREEN_MONSTER_EVENT_ID
     completionHandler:^(GPGEvent *event, NSError *error) {
       if (event){
         NSLog(@"INCREMENTING GREEN BY 1");
         [event incrementBy:1];
         NSLog(@"GREEN count incremented now: %llxl", event.count);
       }else{
         NSLog(@"Error while incrementing count: %@", error);
       }
     }];
  NSLog(@"SENDER WAS %@", sender);
}


/** Simulates attacking a "red" monster in-game.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)attackRed:(id)sender {
  [GPGEvent eventForId:RED_MONSTER_EVENT_ID
     completionHandler:^(GPGEvent *event, NSError *error) {
       if (event){
         [event increment];
         NSLog(@"RED count incremented now: %llxl", event.count);
       }else{
         NSLog(@"Error while incrementing count: %@", error);
       }
     }];
  NSLog(@"Attacked a red monster.");
}

/** Simulates attacking a "yellow" monster in-game.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)attackYellow:(id)sender {
  [GPGEvent eventForId:YELLOW_MONSTER_EVENT_ID
     completionHandler:^(GPGEvent *event, NSError *error) {
       if (event){
         [event increment];
         NSLog(@"YELLOW count incremented now: %llxl", event.count);
       }else{
         NSLog(@"Error while incrementing count: %@", error);
       }
     }];
  NSLog(@"Attacked a yellow monster.");
}

/** Error handler for Play Games Services sign-in.
 *  @param error A message (if any) for the error returned from sign in.
 */
- (void)didFinishGamesSignInWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR during sign in: %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

/** Error handler for Play Games Services sign out.
 *  @param error A message (if any) containing the error from sign-out.
 */
- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR during sign out: %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

/** Performs any events before the user is signed in for Google+.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)signInClicked:(id)sender {
  NSLog(@"Signing the user in...");
  [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:NO];
}

/** Signs the user out of Google+ and shows the Sign in button.
 *  @param sender A reference for the object sending the message.
 */
- (IBAction)signOutUser:(id)sender {
  NSLog(@"Signing the user out.");
  [[GPPSignIn sharedInstance] signOut];
  [self refreshButtons];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

/** Updates UI components after the user sign-in status changes. */
-(void)refreshButtons {
  BOOL signedIn = [GPGManager sharedInstance].isSignedIn;
  // The user is signed in.
  self.signInButton.hidden = signedIn;
  self.signOutButton.hidden = !signedIn;
  self.attackBlueButton.hidden = !signedIn;
  self.attackGreenButton.hidden = !signedIn;
  self.attackRedButton.hidden = !signedIn;
  self.attackYellowButton.hidden = !signedIn;
  self.showQuestsButton.hidden = !signedIn;
  self.showEventsButton.hidden = !signedIn;
}

@end
