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
  if (![GPGManager sharedInstance].isSignedIn) {
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
  if (![GPGManager sharedInstance].isSignedIn) {
    [self requestSignIn];
    return;
  }

  [[MPManager sharedInstance] startInvitationGameWithMinPlayers:2 maxPlayers:4];
}

- (IBAction)viewIncomingInvitesWasPressed:(id)sender {
  [[MPManager sharedInstance] showIncomingInvitesScreen];
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

- (void)refreshButtons {
  BOOL signedIn = [GPGManager sharedInstance].isSignedIn;
  self.signInButton.hidden = signedIn;
  self.signOutButton.hidden = !signedIn;
  self.signInButton.enabled = !_currentlySigningIn;

  // Let's check out our incoming invites
  [self.incomingInvitesButton setTitle:@"Incoming Invites" forState:UIControlStateNormal];
  self.incomingInvitesButton.enabled = NO;
  if (signedIn) {
    [[MPManager sharedInstance] numberOfInvitesAwaitingResponse:^(int numberOfInvites) {
      [self.incomingInvitesButton setTitle:[NSString stringWithFormat:@"Incoming Invites (%d)", numberOfInvites] forState:UIControlStateNormal];
      self.incomingInvitesButton.enabled = (numberOfInvites > 0);
    }];
  }
  self.quickMatchTwoPlayerButton.enabled = signedIn;
  self.quickMatchFourPlayerButton.enabled = signedIn;
  self.inviteFriendsButton.enabled = signedIn;
}

- (IBAction)signInButtonWasPressed:(id)sender {
  [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:NO];
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

  // Let's also ask if it's okay to send push notifciations
  [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
   (UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert)];

  _currentlySigningIn = NO;
}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"***Error signing out! %@", [error localizedDescription]);
  }
  [self refreshButtons];

  _currentlySigningIn = NO;
}

#pragma mark - Lifecycle methods

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  [self refreshButtons];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  [GPGManager sharedInstance].statusDelegate = self;
  [[MPManager sharedInstance] setLobbyDelegate:self];

  _currentlySigningIn =   [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:YES];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

@end
