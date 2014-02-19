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

@interface InitViewController () <GPPSignInDelegate>
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

static NSString * const kDeclinedGooglePreviously = @"UserDidDeclineGoogleSignIn";
static NSInteger const kErrorCodeFromUserDecliningSignIn = -1;


@implementation InitViewController

#pragma mark - Google+ sign-in elements


-(void)initializeSignIn
{
  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  
  signIn.clientID = CLIENT_ID;
  signIn.scopes = [NSArray arrayWithObjects:
                   @"https://www.googleapis.com/auth/games",
                   nil];
  signIn.language = [[NSLocale preferredLanguages] objectAtIndex:0];
  signIn.delegate=self;
  signIn.shouldFetchGoogleUserID =YES;
}

-(void)startGoogleGamesSignIn
{
  // Our GPPSignIn object has an auth token now. Pass it to the GPGManager.
  [[GPGManager sharedInstance] signIn:[GPPSignIn sharedInstance] reauthorizeHandler:^(BOOL requiresKeychainWipe, NSError *error) {
    // If we hit this, auth has failed and we need to authenticate.
    // Most likely we can refresh behind the scenes
    if (requiresKeychainWipe) {
      [[GPPSignIn sharedInstance] signOut];
    }
    [[GPPSignIn sharedInstance] authenticate];
  }];
    [self refreshInterface];
}

-(void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
  self.currentlySigningIn = NO;
  
  if (error.code == 0 && auth) {
    NSLog(@"Success signing in to Google! Auth is %@", auth);
    // Tell our GPGManager that we're ready to go.
    [self startGoogleGamesSignIn];
  } else {
    NSLog(@"Failed to log into Google\n\tError=%@\n\tAuthObj=%@", [error localizedDescription],
          auth);
    if ([error code] == kErrorCodeFromUserDecliningSignIn) {
      // This error code is actually pretty vague, but we can generally assume it's because
      // the user clicked cancel. Let's to the right thing and remember this choice.
      [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDeclinedGooglePreviously];
      [[NSUserDefaults standardUserDefaults] synchronize];
    }
  }
}


-(void)refreshInterface
{
  
  BOOL shouldEnable = [[GPGManager sharedInstance] hasAuthorizer];
  
  NSArray *buttonsToManage = @[self.achButton, self.leadsButton, self.easyButton, self.hardButton,
                               self.signOutButton, self.peopleListButton, self.adminButton];
  for (UIButton *flipMe in buttonsToManage) {
    flipMe.enabled = shouldEnable;
    flipMe.hidden = ! shouldEnable;
  }
  
  [self.signingIn stopAnimating];
  self.gameIcons.hidden = !shouldEnable;
  self.signInButton.hidden = (shouldEnable);
  self.signInButton.enabled = !shouldEnable;
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
  if (shouldEnable) {
    NSDictionary *deepLinkParams = [appDelegate.deepLinkParams copy];
    if (deepLinkParams && [deepLinkParams objectForKey:@"difficulty"]) {
      // So we don't jump muliple times
      self.incomingChallenge = deepLinkParams;
      appDelegate.deepLinkParams = nil;
      [self setDifficultyAndStartGame:[(NSNumber *)[deepLinkParams objectForKey:@"difficulty"] intValue]];
    }
  }

}


- (IBAction)signInClicked:(id)sender {
  [[GPPSignIn sharedInstance] authenticate];
}

- (IBAction)signOutClicked:(id)sender {
  [[GPGManager sharedInstance] signout];
  [self refreshInterface];
  
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
      NSLog(@"Player %@ has a score of %@", nextScore.displayName, nextScore.formattedScore);
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

-(void)achievementViewControllerDidFinish:(GPGAchievementController *)viewController
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showAchievements:(UIButton *)sender {
  GPGAchievementController *achController = [[GPGAchievementController alloc] init];
  achController.achievementDelegate = self;
  [self presentViewController:achController animated:YES completion:nil];
  
}

# pragma mark - Leaderboards handling

-(void)leaderboardsViewControllerDidFinish:(GPGLeaderboardsController *)viewController
{
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)showAllLeaderboards:(UIButton *)sender {
  
  GPGLeaderboardsController *allLeadsController = [[GPGLeaderboardsController alloc] init];
  allLeadsController.leaderboardsDelegate = self;
  [self presentViewController:allLeadsController animated:YES completion:nil];
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
  [self initializeSignIn];
  self.currentlySigningIn  = [[GPPSignIn sharedInstance] trySilentAuthentication];

  if (!self.currentlySigningIn) {
    // Have we tried signing the user in before?
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kDeclinedGooglePreviously]) {
      // They've said no previously. Let's just show the sign in button
    } else {
      // In this case, we will just send the user to a sign-in screen right away.
      // You may want to show an alert or bring up a button instead, depending on your situation.
      [[GPPSignIn sharedInstance] authenticate];
    }
  }

  AppDelegate *appDelegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
  [appDelegate setChallengeReceivedHandler:^{
    [self refreshInterface];
  }];
  

}

- (void)viewDidUnload
{
  [self setAchButton:nil];
  [self setLeadsButton:nil];
  [self setEasyButton:nil];
  [self setHardButton:nil];
  [self setSignInButton:nil];
  [self setSignOutButton:nil];
  [self setPeopleListButton:nil];
  [self setSigningIn:nil];
  [self setGameIcons:nil];
  [super viewDidUnload];
   // Release any retained subviews of the main view.
  
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end



