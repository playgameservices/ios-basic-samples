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

@interface LobbyViewController ()<GPPSignInDelegate, GPGTurnBasedMatchViewControllerDelegate,
                                  GPGPeoplePickerViewControllerDelegate, UIAlertViewDelegate,
                                  GPGStatusDelegate> {
  BOOL _tryingSilentSignin;
}

typedef NS_ENUM(NSInteger, LobbyAlertViewType) {
  LobbyAlertItsYourTurn,
  LobbyAlertYouveBeenInvited,
  LobbyAlertGameOver
};


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

static NSString * const kDeclinedGooglePreviously = @"UserDidDeclineGoogleSignIn";
static NSInteger const kErrorCodeFromUserDecliningSignIn = -1;

@implementation LobbyViewController


# pragma mark - Sign in stuff
- (void)startGoogleGamesSignIn {
  NSLog(@"Starting google games signin");
  // The GPPSignIn object has an auth token now. Pass it to the GPGManager.
  [[GPGManager sharedInstance] signIn:[GPPSignIn sharedInstance]
                   reauthorizeHandler:^(BOOL requiresKeychainWipe, NSError *error) {
    // If you hit this, auth has failed and you need to authenticate.
    // Most likely you can refresh behind the scenes
    if (requiresKeychainWipe) {
      [[GPPSignIn sharedInstance] signOut];
    }
    [[GPPSignIn sharedInstance] authenticate];
  }];

  // Register for push notifications
  NSLog(@"Registering for push notifications");
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert |
    UIRemoteNotificationTypeSound)];
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
  NSLog(@"Finished with auth.");
  _tryingSilentSignin = NO;
  if (error == nil && auth) {
    NSLog(@"Success signing in to Google! Auth object is %@", auth);
    [self startGoogleGamesSignIn];
  } else {
    NSLog(@"Failed to log into Google\n\tError=%@\n\tAuthObj=%@", [error localizedDescription],
          auth);
    if ([error code] == kErrorCodeFromUserDecliningSignIn) {
      // We'll assume the user clicked cancel? Wish there were a better way.
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeclinedGooglePreviously];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
  }
  [self refreshButtons];


}

-(void)refreshButtons
{
  // Step 1: Do we have our auth token from G+?
  BOOL signedIn = [[GPGManager sharedInstance] hasAuthorizer];
  NSLog(@"Refreshing our buttons. Has authorizer is %@", (signedIn) ? @"Yes" : @"No");
  self.signInButton.hidden = signedIn;
  self.signOutButton.hidden = !signedIn;
  // Don't enable the sign in button if we're trying to sign the user in
  // already.
  self.signInButton.enabled = !_tryingSilentSignin;

  // Step 2: Are we completely signed in to Game services?
  BOOL signedInToGames = [GPGManager sharedInstance].signedIn;
  NSLog(@"Signed in to games services is %@", (signedIn) ? @"Yes" : @"No");
  self.quickMatchButton.enabled = signedInToGames;
  self.inviteFriendsButton.enabled = signedInToGames;
  self.viewMyMatchesButton.enabled = signedInToGames;
  if (signedInToGames) {
    [self refreshPendingGames];
  }
}

- (IBAction)signInWasClicked:(id)sender {
  [[GPPSignIn sharedInstance] authenticate];
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
}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"***ERROR signing out from Google Play Games %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

# pragma mark - Matchmaking methods


- (IBAction)inviteMyFriends:(id)sender {

  // This can be a 2-4 player game
  GPGPeoplePickerViewController *findFriendsVC = [[GPGPeoplePickerViewController alloc] init];
  findFriendsVC.minPlayersToPick = 1;
  findFriendsVC.maxPlayersToPick = 3;

  findFriendsVC.peoplePickerDelegate = self;
  [self presentViewController:findFriendsVC animated:YES completion:nil];

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
  GPGTurnBasedMatchViewController *matchViewController =
      [[GPGTurnBasedMatchViewController alloc] init];
  matchViewController.matchDelegate = self;
  self.justCameFromMatchVC = YES;
  [self presentViewController:matchViewController animated:YES completion:nil];
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

# pragma mark PeoplePickerViewControllerDelegate methods

- (void)peoplePickerViewController:(GPGPeoplePickerViewController *)viewController
                     didPickPeople:(NSArray *)people
               autoPickPlayerCount:(int)autoPickPlayerCount {

  [self dismissViewControllerAnimated:YES completion:nil];
  for (NSString *nextPlayerId in people) {
    NSLog(@"This is who we picked %@", nextPlayerId);
  }

  GPGMultiplayerConfig *matchConfigForCreation = [[GPGMultiplayerConfig alloc] init];
  matchConfigForCreation.invitedPlayerIds = people;
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

- (void)peoplePickerViewControllerDidCancel:(GPGPeoplePickerViewController *)controller {
  [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)updateNumberOfGamesNeedingAttention {
  NSInteger invitedGamesCount = [[GPGManager sharedInstance].applicationModel.turnBased
                                 matchesForUserMatchStatus:GPGTurnBasedUserMatchStatusInvited].count;
  NSInteger myTurnGamesCount = [[GPGManager sharedInstance].applicationModel.turnBased
                                matchesForUserMatchStatus:GPGTurnBasedUserMatchStatusTurn].count;
  NSInteger gamesToRespondTo = invitedGamesCount + myTurnGamesCount;

  NSString *buttonText;
  if (gamesToRespondTo > 0) {
    buttonText = [NSString stringWithFormat:@"All my matches (%ld)", (long) gamesToRespondTo];
  } else {
    buttonText = @"All my matches";
  }
  // If this were a real app, I might use a library to add a nice badge to my button instead.
  [self.viewMyMatchesButton setTitle:buttonText forState:UIControlStateNormal];

}

- (void)refreshPendingGames {
  // If we just came from our TurnBasedMatchViewController, it might be safer to reload this
  // data when refreshing. However, if we just got here from our TBMVC, all that data has
  // just been loaded, and the reloadDataForKey step is unnecessary.

  if (!self.justCameFromMatchVC) {
    // Perform a network call
    [[GPGManager sharedInstance].applicationModel reloadDataForKey:GPGModelAllMatchesKey completionHandler:^(NSError *error) {
      [self updateNumberOfGamesNeedingAttention];
     }];
  } else {
    // Skip the network call!
    [self updateNumberOfGamesNeedingAttention];
  }
  self.justCameFromMatchVC = NO;
}

- (NSInteger)numberOfGamesNeedingPlayersAttention {
  NSInteger __block gamesToRespondTo;
  [[GPGManager sharedInstance].applicationModel reloadDataForKey:GPGModelAllMatchesKey completionHandler:^(NSError *error) {
    GPGTurnBasedModel *turnModel = [GPGManager sharedInstance].applicationModel.turnBased;
    NSInteger invitedGamesCount = [turnModel matchesForUserMatchStatus:GPGTurnBasedUserMatchStatusInvited].count;
    NSInteger myTurnGamesCount = [turnModel matchesForUserMatchStatus:GPGTurnBasedUserMatchStatusTurn].count;
    gamesToRespondTo = invitedGamesCount + myTurnGamesCount;

  }];
  return gamesToRespondTo;
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
              @"%@ just took their turn in a match. " @"Would you like to jump to that game now?",
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

# pragma mark TurnBasedRoomControllerDelegate methods


- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                didTakeTurnWithMatch:(GPGTurnBasedMatch *)match {
  NSLog(@"Clicking didTakeTurnWithMathc");
  // Indicates that yes, I want to take my turn in this game
  [self dismissViewControllerAnimated:YES completion:nil];
  [self takeTurnInMatch:match];
}

- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                   didTapMyTurnMatch:(GPGTurnBasedMatch *)match {
  // This is used when a user clicks elsewhere in the match view controller that's NOT the
  // crossed-swords "Take turn" button.
  NSLog(@"Clicking didTapMyTurnMatch");

  // This might be a good time to bring up an alert sheet, or a dialog box that shows you something
  // about the match. Or we could just take a turn as if the player had clicked the takeTurn button.
  // It's really up to you.

  // Let's bring up a UIAlert. Because we can.
  NSString *matchInfo =
      [NSString stringWithFormat:@"Created by %@. Last turn by %@ on %@",
          match.creationParticipant.player.displayName,
          match.lastUpdateParticipant.player.displayName,
       [NSDate dateWithTimeIntervalSince1970:match.lastUpdateTimestamp / 1000]];

  [[[UIAlertView alloc] initWithTitle:@"Match info"
                              message:matchInfo
                             delegate:nil
                    cancelButtonTitle:@"Okay"
                    otherButtonTitles:nil] show];

}


- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                        didJoinMatch:(GPGTurnBasedMatch *)match {
  NSLog(@"Did join match called");
  // Indicates that yes, I do want to play this game I was invited to. In this case, we'll
  // just jump right into a turn
  [self dismissViewControllerAnimated:YES completion:nil];
  [self takeTurnInMatch:match];
}

- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                     didDeclineMatch:(GPGTurnBasedMatch *)match {
    NSLog(@"Did decline match called. No further action required.");
}

- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                          didRematch:(GPGTurnBasedMatch *)match {
  NSLog(@"Did rematch called.");
  // This really looks like we're just creating a new match.
  [self dismissViewControllerAnimated:YES completion:nil];
  [self takeTurnInMatch:match];
}


- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                didTapTheirTurnMatch:(GPGTurnBasedMatch *)match {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self viewMatchNotMyTurn:match];
}

- (void)turnBasedMatchViewController:(GPGTurnBasedMatchViewController *)controller
                didTapCompletedMatch:(GPGTurnBasedMatch *)match {
  [self dismissViewControllerAnimated:YES completion:nil];
  [self viewMatchNotMyTurn:match];
}


- (void)turnBasedMatchViewControllerDidFinish:(GPGTurnBasedMatchViewController *)controller {
  NSLog(@"Match VC did finish called");
  [self dismissViewControllerAnimated:YES completion:nil];
}

# pragma mark - Lifecycle methods

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  // You set kClientID in a previous step
  signIn.clientID = CLIENT_ID;
  signIn.scopes = [NSArray arrayWithObjects:
                   @"https://www.googleapis.com/auth/games",
                   nil];
  signIn.language = [[NSLocale preferredLanguages] objectAtIndex:0];
  signIn.delegate = self;
  signIn.shouldFetchGoogleUserID =YES;

  [GPGManager sharedInstance].statusDelegate = self;

  _tryingSilentSignin = [signIn trySilentAuthentication];

  if (!_tryingSilentSignin) {
    // Have we tried signing the user in before?
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDeclinedGooglePreviously]) {
      // They've said no previously. Let's just show the sign in button
    } else {
      [[GPPSignIn sharedInstance] authenticate];
    }

  }
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
