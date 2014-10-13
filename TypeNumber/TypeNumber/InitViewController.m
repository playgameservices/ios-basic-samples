//
//  InitViewController.m
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
#import <GooglePlus/GooglePlus.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "GameModel.h"
#import "GameViewController.h"
#import "InitViewController.h"

@interface InitViewController () <GPGStatusDelegate, GPGStatusDelegate>
@property (weak, nonatomic) IBOutlet UIButton *achButton;
@property (weak, nonatomic) IBOutlet UIButton *adminButton;
@property (weak, nonatomic) IBOutlet UIButton *leadsButton;
@property (weak, nonatomic) IBOutlet UIButton *easyButton;
@property (weak, nonatomic) IBOutlet UIButton *hardButton;
@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIButton *peopleListButton;
@property (weak, nonatomic) IBOutlet UIView *gameIcons;
@property (nonatomic) TNDifficultyLevel desiredDifficulty;
@property (nonatomic, strong) NSDictionary *incomingChallenge;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signingIn;

@property (nonatomic) BOOL currentlySigningIn;
@property (nonatomic, strong) GPGLeaderboard *testLeaderboard;
@end

@implementation InitViewController

#pragma mark - Google+ sign-in elements

-(void)refreshInterface
{
  BOOL signedIn = [GPGManager sharedInstance].isSignedIn;

  // We update most of our game interface when game services sign-in is totally complete. In an
  // actual game, you probably will want to allow basic gameplay even if the user isn't signed
  // in to Google Play Games.
  NSArray *buttonsToManage = @[self.achButton, self.leadsButton, self.easyButton, self.hardButton,
                                self.peopleListButton, self.adminButton];
  for (UIButton *flipMe in buttonsToManage) {
    flipMe.enabled = signedIn;
    flipMe.hidden = !signedIn;
  }
  
  [self.signingIn stopAnimating];
  self.gameIcons.hidden = !signedIn;

  self.signInButton.hidden = signedIn;
  self.signInButton.enabled = !signedIn;
  self.signOutButton.hidden = !signedIn;
  self.signOutButton.enabled = signedIn;
  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  
  // This catches the case where we're not signed in, but the service is in the
  // process of signing us in.
  if (self.currentlySigningIn) {
    self.signInButton.enabled = false;
    self.signInButton.alpha = 0.4;
    [self.signingIn startAnimating];
  } else {
    self.signInButton.enabled = true;
    self.signInButton.alpha = 1.0;
  }
  
  // This would also be a good time to jump directly into our game
  // if we got here from a deep link
  if (signedIn) {
    self.currentlySigningIn = NO;
    [self.signingIn stopAnimating];
    NSDictionary *deepLinkParams = [appDelegate.deepLinkParams copy];
    if (deepLinkParams && [deepLinkParams objectForKey:@"difficulty"]) {
      // So we don't jump muliple times
      self.incomingChallenge = deepLinkParams;
      appDelegate.deepLinkParams = nil;
      [self setDifficultyAndStartGame:[(NSNumber *)[deepLinkParams objectForKey:@"difficulty"] intValue]];
    }
  }

}

- (void)didFinishGamesSignInWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR during sign in: %@", [error localizedDescription]);
  }
  [self refreshInterface];
  self.currentlySigningIn = NO;
}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR during sign out: %@", [error localizedDescription]);
  }
  [self refreshInterface];
  self.currentlySigningIn = NO;
}

- (IBAction)signInClicked:(id)sender {
  [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:NO];
}

- (IBAction)signOutClicked:(id)sender {
  [[GPGManager sharedInstance] signOut];
}

# pragma mark - Picking difficulty level and transitioning

-(void)setDifficultyAndStartGame:(TNDifficultyLevel)level
{
  self.desiredDifficulty = level;
  [self performSegueWithIdentifier:@"playGame" sender:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([segue.identifier isEqualToString:@"playGame"]) {
    ((GameViewController *)segue.destinationViewController).difficulty = self.desiredDifficulty;
    if (self.incomingChallenge) {
      ((GameViewController *)segue.destinationViewController).incomingChallenge = self.incomingChallenge;
      self.incomingChallenge = nil;
    }
  }
}

- (IBAction)testButtonClicked:(id)sender {
  self.testLeaderboard = [GPGLeaderboard leaderboardWithId:LEAD_EASY];
  [self.testLeaderboard  loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
    NSLog(@"In the callback");
    for (GPGScore *nextScore in scores) {
      NSLog(@"Player %@ has a score of %@", nextScore.player.displayName, nextScore.formattedScore);
    }
  }];
}

- (IBAction)testAdminButtonClicked:(UIButton *)sender {
  [GPGAchievement resetAllAchievementsWithCompletionHandler:^(NSError *error) {
    if (error) {
      NSLog(@"***ERROR resetting achievements: %@ ***", [error localizedDescription]);
    } else {
      NSLog(@"Done! Restart the app to view your new data");
    }
  }];
}

- (IBAction)peopleListButtonClicked:(UIButton *)sender {
  // Nothing to do here, really...
}

- (IBAction)easyButtonClicked:(UIButton *)sender {
  [self setDifficultyAndStartGame:TNDifficultyLevelEasy];
}

- (IBAction)hardButtonClicked:(id)sender {
  [self setDifficultyAndStartGame:TNDifficultyLevelHard];
}

# pragma mark - Achievement handling

- (IBAction)showAchievements:(UIButton *)sender {
  [[GPGLauncherController sharedInstance] presentAchievementList];
}

# pragma mark - Leaderboards handling

- (IBAction)showAllLeaderboards:(UIButton *)sender {
  [[GPGLauncherController sharedInstance] presentLeaderboardList];
}

# pragma mark - Standard lifecycle functions

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
  NSLog(@"In view did appear!");
  [super viewDidAppear:animated];
}

-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self refreshInterface];
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  [GPGManager sharedInstance].statusDelegate = self;
  self.currentlySigningIn  =   [[GPGManager sharedInstance] signInWithClientID:CLIENT_ID silently:YES];

  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  [appDelegate setChallengeReceivedHandler:^{
    [self refreshInterface];
  }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end



