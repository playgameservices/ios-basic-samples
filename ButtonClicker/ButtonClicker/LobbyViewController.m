//
//  ViewController.m
//  ButtonClicker
//
//  Created by Todd Kerpelman on 12/9/13.
//  Copyright (c) 2013 Google. All rights reserved.
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

#import "LobbyViewController.h"
#import "MPManager.h"
#import "Constants.h"

@interface LobbyViewController ()<UIAlertViewDelegate, MPLobbyDelegate,
                                  GPGStatusDelegate> {
  BOOL _currentlySigningIn;
}
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *incomingInvitesButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchTwoPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *quickMatchFourPlayerButton;
@property (weak, nonatomic) IBOutlet UIButton *inviteFriendsButton;
@end

@implementation LobbyViewController

#pragma mark - Multi-player stuff


- (void)startQuickMatchGameWithTotalPlayers:(int)totalPlayers {
  if (![[GPGManager sharedInstance] hasAuthorizer]) {
    [self requestSignIn];
    return;
  }

  [[MPManager sharedInstance] startQuickMatchGameWithTotalPlayers:totalPlayers];

}

- (IBAction)quickFourPlayerWasPressed:(id)sender {
  [self startQuickMatchGameWithTotalPlayers:4];
}

- (IBAction)quickTwoPlayerWasPressed:(id)sender {
  [self startQuickMatchGameWithTotalPlayers:2];
}

- (IBAction)inviteFriendsWasPressed:(id)sender {
  if (![[GPGManager sharedInstance] hasAuthorizer]) {
    [self requestSignIn];
    return;
  }

  [[MPManager sharedInstance] startInvitationGameWithMinPlayers:2 maxPlayers:4];
}

- (IBAction)viewIncomingInvitesWasPressed:(id)sender {
  [[MPManager sharedInstance] showIncomingInvitesScreen];
}

- (void)showInviteViewController:(UIViewController *)vcToShow {
  NSLog(@"Okay! Lobby is ready to show invite VC!");
  [self presentViewController:vcToShow animated:YES completion:nil];

}

- (void)multiPlayerGameWasCanceled {
  if (self.presentedViewController != nil) {
    [self dismissViewControllerAnimated:YES completion:nil];
  }
}

- (void)readyToStartMultiPlayerGame {
  // I can still sometimes receive this if we're in the middle of a game
  if (![[self.navigationController.viewControllers lastObject] isEqual:self]) {
    return;
  }
    
  if (self.presentedViewController != nil) {
    [self dismissViewControllerAnimated:YES completion:^{
        [self performSegueWithIdentifier:@"SegueToGame" sender:self];
    }];
  } else {
    [self performSegueWithIdentifier:@"SegueToGame" sender:self];
  }
}


# pragma mark - Sign in methods

- (void)requestSignIn {
  UIAlertView *askToSignIn =
      [[UIAlertView alloc] initWithTitle:@"Sign in?"
                                 message:@"You must sign in to Google Play Games in order to use "
                                          "multiplayer features. Sign in now?"
                                delegate:self
                       cancelButtonTitle:@"No"
                       otherButtonTitles:@"Yes!",
          nil];
  [askToSignIn show];

}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  if (buttonIndex == 0) {
    // Okay, chose not to sign in. Their loss
  } else {
    [[GPPSignIn sharedInstance] authenticate];
  }

}


- (void)startGoogleGamesSignIn {
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
  
  // Let's also ask if it's okay to send push notifciations
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)];

  
}

- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error {
  NSLog(@"Finished with auth.");
  _currentlySigningIn = NO;

  if (error == nil && auth) {
    NSLog(@"Success signing in to Google! Auth object is %@", auth);
    [self startGoogleGamesSignIn];
    
  } else {
    NSLog(@"Failed to log into Google\n\tError=%@\n\tAuthObj=%@", error, auth);
  }
  [self refreshButtons];
}

- (void)refreshButtons {
  // Two different types of sign-in now! This asks whether or not we've received an auth token
  BOOL signedIn = [[GPGManager sharedInstance] hasAuthorizer];
  self.signInButton.hidden = signedIn;
  self.signOutButton.hidden = !signedIn;
  self.signInButton.enabled = !_currentlySigningIn;


  // But then the following checks whether or not we've finished signing in to game services
  BOOL gamesSignedIn = [[GPGManager sharedInstance] isSignedIn];
  // Let's check out our incoming invites
  [self.incomingInvitesButton setTitle:@"Incoming Invites" forState:UIControlStateNormal];
  self.incomingInvitesButton.enabled = NO;
  if (gamesSignedIn) {
    [[MPManager sharedInstance] numberOfInvitesAwaitingResponse:^(int numberOfInvites) {
      [self.incomingInvitesButton setTitle:[NSString stringWithFormat:@"Incoming Invites (%d)", numberOfInvites] forState:UIControlStateNormal];
      self.incomingInvitesButton.enabled = (numberOfInvites > 0);
    }];
  }
  self.quickMatchTwoPlayerButton.enabled = gamesSignedIn;
  self.quickMatchFourPlayerButton.enabled = gamesSignedIn;
  self.inviteFriendsButton.enabled = gamesSignedIn;
}

- (IBAction)signInButtonWasPressed:(id)sender {
  [[GPPSignIn sharedInstance] authenticate];
}

- (IBAction)signOutButtonWasPressed:(id)sender {
  [[GPGManager sharedInstance] signOut];
}

# pragma mark -- GPGStatusDelegate methods

- (void)didFinishGamesSignInWithError:(NSError *)error {
  NSLog(@"GooglePlayGames finished signing in!");
  if (error) {
    NSLog(@"***Error signing in! %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"***Error signing out! %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

#pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self refreshButtons];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  signIn.clientID = CLIENT_ID;
  signIn.scopes = [NSArray arrayWithObjects:@"https://www.googleapis.com/auth/games", nil];
  signIn.language = [NSLocale preferredLanguages][0];
  signIn.delegate = self;
  signIn.shouldFetchGoogleUserID = YES;

  [GPGManager sharedInstance].statusDelegate = self;
  [[MPManager sharedInstance] setLobbyDelegate:self];

  _currentlySigningIn = [[GPPSignIn sharedInstance] trySilentAuthentication];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
