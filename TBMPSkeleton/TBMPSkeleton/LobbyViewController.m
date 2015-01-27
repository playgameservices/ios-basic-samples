//
//  ViewController.m
//  TBMPTest
//
//  Created by Todd Kerpelman on 1/23/14.
//  Copyright (c) 2014 Google. All rights reserved.
//
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

#import "Constants.h"
#import "GameData.h"
#import "GameViewController.h"
#import "LobbyViewController.h"
#import <GooglePlus/GooglePlus.h>
#import <GooglePlayGames/GooglePlayGames.h>

@interface LobbyViewController ()<GPGTurnBasedMatchListLauncherDelegate,
                                  GPGTurnBasedMatchDelegate,
                                  GPGPlayerPickerLauncherDelegate,
                                  UIAlertViewDelegate,
                                  GPGStatusDelegate> {
  BOOL _tryingSilentSignin;
}

typedef NS_ENUM(NSInteger, LobbyAlertViewType) {
  LobbyAlertItsYourTurn,
  LobbyAlertYouveBeenInvited,
  LobbyAlertGameOver
};

@property (nonatomic, weak) id <UIPageViewControllerDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteFriendsButton;
@property (weak, nonatomic) IBOutlet UIButton *viewMyMatchesButton;
@property (nonatomic) GPGTurnBasedMatch *matchToTransfer;
@property (nonatomic) GPGTurnBasedMatch *matchFromNotification;
@property (nonatomic) LobbyAlertViewType lobbyAlertType;
@property (nonatomic) BOOL justCameFromMatchVC;
@end

@implementation LobbyViewController

# pragma mark - Sign in stuff

-(void)refreshButtons
{
  BOOL signedIn = [GPGManager sharedInstance].isSignedIn;
  self.signInButton.hidden = signedIn;
  self.signOutButton.hidden = !signedIn;
  // Don't enable the sign in button if we're trying to sign the user in
  // already.
  self.signInButton.enabled = !_tryingSilentSignin;

  NSLog(@"Signed in to games services is %@", (signedIn) ? @"Yes" : @"No");
  self.quickMatchButton.enabled = signedIn;
  self.inviteFriendsButton.enabled = signedIn;
  self.viewMyMatchesButton.enabled = signedIn;
  if (signedIn) {
    [self refreshPendingGames];
  }
}

- (IBAction)signInWasClicked:(id)sender {
  [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:NO];
}

- (IBAction)signOutWasClicked:(id)sender {
  [[GPGManager sharedInstance] signOut];
}

# pragma mark - GPGSignInDelegate methods

- (void)didFinishGamesSignInWithError:(NSError *)error {
  NSLog(@"In my did finish delegate method");
  if (error) {
    NSLog(@"***ERROR signing in to Google Play Games %@", [error localizedDescription]);
  }
  [self refreshButtons];

  // Register for push notifications
  NSLog(@"Registering for push notifications");
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert |
    UIRemoteNotificationTypeSound)];

  _tryingSilentSignin = NO;
}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"***ERROR signing out from Google Play Games %@", [error localizedDescription]);
  }
  [self refreshButtons];
  _tryingSilentSignin = NO;
}

# pragma mark - Matchmaking methods

- (IBAction)inviteMyFriends:(id)sender {
  // This can be a 2-4 player game
  [GPGLauncherController sharedInstance].playerPickerLauncherDelegate = self;
  [[GPGLauncherController sharedInstance] presentPlayerPicker];
}

- (IBAction)quickMatchWasPressed:(id)sender {
  GPGMultiplayerConfig *gameConfigForAutoMatch = [[GPGMultiplayerConfig alloc] init];
  gameConfigForAutoMatch.minAutoMatchingPlayers = 1;
  gameConfigForAutoMatch.maxAutoMatchingPlayers = 1;

  [GPGTurnBasedMatch createMatchWithConfig:gameConfigForAutoMatch completionHandler:^(GPGTurnBasedMatch *match, NSError *error) {
    if (error) {
      NSLog(@"Received an error trying to create a match %@", [error localizedDescription]);
    } else {
      [self takeTurnInMatch: match];
    }
  }];
}

- (IBAction)seeMyMatches:(id)sender {
  self.justCameFromMatchVC = YES;
  [GPGLauncherController sharedInstance].turnBasedMatchListLauncherDelegate = self;
  [[GPGLauncherController sharedInstance] presentTurnBasedMatchList];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  // TODO: Boo! Tightly-coupled classes. I should use a protocol here.
  ((GameViewController *)[segue destinationViewController]).match = self.matchToTransfer;
}

- (void)takeTurnInMatch:(GPGTurnBasedMatch *)match {
  // Yeah, we're tightly coupling our classes here. Sorry.
  self.matchToTransfer = match;
  NSLog(@"I am about to take a turn in a match %@", match);
  [self performSegueWithIdentifier:@"segueToGamePlay" sender:self];
}

- (void)viewMatchNotMyTurn:(GPGTurnBasedMatch *)match {
  self.matchToTransfer = match;
  [self performSegueWithIdentifier:@"segueToGamePlay" sender:self];
}

# pragma mark GPGPlayerPickerLauncherDelegate methods
- (int)minPlayersForPlayerPickerLauncher {
  return 1;
}

- (int)maxPlayersForPlayerPickerLauncher {
  return 3;
}

- (void)playerPickerLauncherDidPickPlayers:(NSArray *)players
                       autoPickPlayerCount:(int)autoPickPlayerCount {
  if (players == NULL) return;

  for (NSString *nextPlayerId in players) {
    NSLog(@"This is who we picked %@", nextPlayerId);
  }

  GPGMultiplayerConfig *matchConfigForCreation = [[GPGMultiplayerConfig alloc] init];
  matchConfigForCreation.invitedPlayerIds = players;
  matchConfigForCreation.minAutoMatchingPlayers = autoPickPlayerCount;
  matchConfigForCreation.maxAutoMatchingPlayers = autoPickPlayerCount;

  [GPGTurnBasedMatch createMatchWithConfig:matchConfigForCreation completionHandler:^(GPGTurnBasedMatch *match, NSError *error) {
    if (error) {
      NSLog(@"Received an error trying to create a match %@", [error localizedDescription]);
    } else {
      [self takeTurnInMatch:match];
    }
  }];
}

- (void)refreshPendingGames {
  [GPGTurnBasedMatch allMatchesWithCompletionHandler:^(NSArray *matches, NSError *error){
    NSInteger gamesToRespondTo = 0;
    for (GPGTurnBasedMatch* match in matches )
    {
      if (match.status == GPGTurnBasedUserMatchStatusInvited
          ||match.status == GPGTurnBasedUserMatchStatusTurn)
        gamesToRespondTo++;
    }
    NSString *buttonText;
    if (gamesToRespondTo > 0) {
      buttonText = [NSString stringWithFormat:@"All my matches (%ld)", (long) gamesToRespondTo];
    } else {
      buttonText = @"All my matches";
    }
    // If this were a real app, I might use a library to add a nice badge to my button instead.
    [self.viewMyMatchesButton setTitle:buttonText forState:UIControlStateNormal];
  }];
  self.justCameFromMatchVC = NO;
}

#pragma mark - GPGLauncherDelegate
- (void)launcherDismissed {
  // In the case of launching from a push notification, |matchToLoad_| is not nil.
  // If the user dismissed launcher manually, |matchToLoad_| isn't needed any more.
}

# pragma mark GPGTurnBasedMatchDelegate methods

// TODO: This can get called from many places -- not just from a push notification.
// Probably only want to bring up the dialog if this is from a push notification.

- (void)didReceiveTurnBasedInviteForMatch:(GPGTurnBasedMatch *)match
                     fromPushNotification:(BOOL)fromPushNotification {
  // Only show an alert if you received this from a push notification
  if (fromPushNotification) {
    NSLog(@"Hooray! Received an invitation!");


    GPGTurnBasedParticipant *invitingParticipant =
    [match participantForId:match.lastUpdateParticipant.participantId];
    if ([match.pendingParticipant.participantId isEqualToString:match.localParticipantId]) {
      NSString *messageToShow = [NSString
                                 stringWithFormat:@"%@ just invited you to a game. " @"Would you like to play now?",
                                 invitingParticipant.player.displayName];
      [[[UIAlertView alloc] initWithTitle:@"You've been invited!"
                                  message:messageToShow
                                 delegate:self
                        cancelButtonTitle:@"Not now"
                        otherButtonTitles:@"Sure!",
        nil] show];
      self.matchFromNotification = match;
      self.lobbyAlertType = LobbyAlertYouveBeenInvited;
    }
  }
  [self refreshPendingGames];
}

- (void)didReceiveTurnEventForMatch:(GPGTurnBasedMatch *)match
                        participant:(GPGTurnBasedParticipant *)participant
               fromPushNotification:(BOOL)fromPushNotification {
  NSLog(@"Hooray! Received an event in a match! %@", match);
  if (fromPushNotification) {
    if ([match.pendingParticipant.participantId isEqualToString:match.localParticipantId]) {
      NSString *messageToShow = [NSString stringWithFormat:
                                 @"%@ just took their turn in a match.\nWould you like to jump to that game now?",
                                 participant.player.displayName];
      [[[UIAlertView alloc] initWithTitle:@"It's your turn!"
                                  message:messageToShow
                                 delegate:self
                        cancelButtonTitle:@"No"
                        otherButtonTitles:@"Sure!",
        nil] show];
      self.matchFromNotification = match;
      self.lobbyAlertType = LobbyAlertItsYourTurn;
    }
  }
  [self refreshPendingGames];

}

// This will get called whenever somebody else calls "Finish Game".
// I won't get a push notification, but still worth alerting the viewer
// In next version, this will change to have a fromPushNotification boolean as well
- (void)matchEnded:(GPGTurnBasedMatch *)match participant:(GPGTurnBasedParticipant *)participant fromPushNotification:(BOOL)fromPushNotification {
  if (fromPushNotification) {
    NSString *messageToShow = [NSString stringWithFormat:
                               @"%@ just finished a game you were in. "
                               @"Want to see the results?",
                               participant.player.displayName];
    [[[UIAlertView alloc] initWithTitle:@"Game over, man!"
                                message:messageToShow
                               delegate:self
                      cancelButtonTitle:@"No"
                      otherButtonTitles:@"Sure!",
      nil] show];
    self.matchFromNotification = match;
    self.lobbyAlertType = LobbyAlertGameOver;
  }
  [self refreshPendingGames];
}

- (void)matchEnded:(GPGTurnBasedMatch *)match withParticipant:(GPGTurnBasedParticipant *)participant {
  NSLog(@"Match has ended!");
  [self refreshPendingGames];
}

// This would be called if something weird happens. For instance, you call take turn while offline
// then, when you come back online, it turns out the state of the match had changed and the player's
// turn is no longer appropriate.
- (void)failedToProcessMatchUpdate:(GPGTurnBasedMatch *)match error:(NSError *)error {
  NSLog(@"I failed to process a match. When would I sue this?");
  [self refreshPendingGames];
}


# pragma mark UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (self.lobbyAlertType == LobbyAlertItsYourTurn) {
    // Responding to a "It's your turn" alert?
    if (buttonIndex == 1 && self.matchFromNotification) {
      [self takeTurnInMatch:self.matchFromNotification];
    }
  } else if (self.lobbyAlertType == LobbyAlertYouveBeenInvited) {
    // Responding to a "You've been invited" alert
    if (buttonIndex == 0 && self.matchFromNotification) {
      // I originally declined the invitation here. But I realized most players view
      // hitting no as "Not now" instead of "Reject". So I'll just do nothing instead.
    } else if (buttonIndex == 1 && self.matchFromNotification) {
      // Great! Let's join the match and then take a turn
      [self.matchFromNotification joinWithCompletionHandler:^(NSError *error) {
        if (error) {
          NSLog(@"Error joining a match: %@", [error localizedDescription]);
        } else {
          [self takeTurnInMatch:self.matchFromNotification];
        }
      }];
    }
  }
}

#pragma mark - GPGTurnBasedMatchListLauncherDelegate

- (void)turnBasedMatchListLauncherDidSelectMatch:(GPGTurnBasedMatch *)match {
  NSLog(@"Clicking turnBasedMatchListLauncherDidSelectMatch");

  NSString *matchInfo;
  switch (match.userMatchStatus)
  {
    case GPGTurnBasedUserMatchStatusTurn:         //My turn
      [self takeTurnInMatch:match];
      break;
    case GPGTurnBasedUserMatchStatusAwaitingTurn: //Their turn
      [self viewMatchNotMyTurn:match];
      break;
    case GPGTurnBasedUserMatchStatusInvited:
      // This might be a good time to bring up an alert sheet or a dialog box that shows you something
      // about the match. Or we could just take a turn as if the player had clicked the takeTurn button.
      // It's really up to you.

      // Let's bring up a UIAlert. Because we can.
      matchInfo =
      [NSString stringWithFormat:@"Created by %@. Last turn by %@ on %@",
       match.creationParticipant.player.displayName,
       match.lastUpdateParticipant.player.displayName,
       [NSDate dateWithTimeIntervalSince1970:match.lastUpdateTimestamp / 1000]];

      [[[UIAlertView alloc] initWithTitle:@"Match info"
                                  message:matchInfo
                                 delegate:nil
                        cancelButtonTitle:@"Okay"
                        otherButtonTitles:nil] show];
      break;
    case GPGTurnBasedUserMatchStatusMatchCompleted: //Completed match
      [self viewMatchNotMyTurn:match];
      break;
  }
}

- (void)turnBasedMatchListLauncherDidJoinMatch:(GPGTurnBasedMatch *)match {
  NSLog(@"Did join match called");
  // Indicates that yes, I do want to play this game I was invited to. In this case, we'll
  // just jump right into a turn
  [self dismissViewControllerAnimated:YES completion:nil];
  [self takeTurnInMatch:match];
}

- (void)turnBasedMatchListLauncherDidDeclineMatch:(GPGTurnBasedMatch *)match {
  NSLog(@"Did decline match called. No further action required.");
}

- (void)turnBasedMatchListLauncherDidRematch:(GPGTurnBasedMatch *)match {
  NSLog(@"Did rematch called.");
  // This really looks like we're just creating a new match.
  [self dismissViewControllerAnimated:YES completion:nil];
  [self takeTurnInMatch:match];
}

# pragma mark - Lifecycle methods

- (void)viewDidLoad
{
  [super viewDidLoad];

  [GPGManager sharedInstance].statusDelegate = self;

  _tryingSilentSignin = [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self refreshButtons];
}


- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}



@end
