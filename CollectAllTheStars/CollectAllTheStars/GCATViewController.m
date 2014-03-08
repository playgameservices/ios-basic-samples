//
//  GCATViewController.m
//  CollectAllTheStars
//
//  Created by Todd Kerpelman on 5/7/13.
//  Copyright (c) 2013 Google. All rights reserved.
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
//

#import <GooglePlus/GooglePlus.h>
#import "GCATConstants.h"
#import "GCATViewController.h"
#import "GCATModel.h"

@interface GCATViewController () <GPPSignInDelegate, GPGStatusDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIActionSheetDelegate>
@property (nonatomic) BOOL currentlySigningIn;
@property (nonatomic) int currentWorld;
@property (nonatomic) int pickerSelectedRow;
@property (nonatomic, strong) GCATModel *gameModel;


@property (weak, nonatomic) IBOutlet UIButton *signInButton;
@property (weak, nonatomic) IBOutlet UIButton *signOutButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *signInIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicator;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *savingIndicator;
@property (weak, nonatomic) IBOutlet UIButton *loadButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *changeWorldButton;
@property (weak, nonatomic) IBOutlet UILabel *worldLabel;
@property (weak, nonatomic) IBOutlet UILabel *signInLabel;

// All of our buttons! HOoray
@property (weak, nonatomic) IBOutlet UIButton *level1Button;
@property (weak, nonatomic) IBOutlet UIButton *level2Button;
@property (weak, nonatomic) IBOutlet UIButton *level3Button;
@property (weak, nonatomic) IBOutlet UIButton *level4Button;
@property (weak, nonatomic) IBOutlet UIButton *level5Button;
@property (weak, nonatomic) IBOutlet UIButton *level6Button;
@property (weak, nonatomic) IBOutlet UIButton *level7Button;
@property (weak, nonatomic) IBOutlet UIButton *level8Button;
@property (weak, nonatomic) IBOutlet UIButton *level9Button;
@property (weak, nonatomic) IBOutlet UIButton *level10Button;
@property (weak, nonatomic) IBOutlet UIButton *level11Button;
@property (weak, nonatomic) IBOutlet UIButton *level12Button;
@property (nonatomic, strong) NSArray *levelButtons;
@end


static NSString * const kDeclinedGooglePreviously = @"UserDidDeclineGoogleSignIn";
static NSInteger const kErrorCodeFromUserDecliningSignIn = -1;

@implementation GCATViewController

# pragma mark - Sign-in functions
-(void)startGoogleGamesSignIn
{
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
  
//  [self loadFromTheCloud];

}

// Hooray! The user has finished the sign-in process.
- (void)finishedWithAuth:(GTMOAuth2Authentication *)auth error:(NSError *)error
{
  NSLog(@"Finished with auth.");
  self.currentlySigningIn = NO;
  if (error == nil && auth) {
    NSLog(@"Success signing in to Google! Auth object is %@", auth);
    // Tell your GPGManager that you're ready to go.
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
  [self refreshButtons];
}

- (void)didFinishGamesSignInWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR signing in: %@", [error localizedDescription]);
  }
  [self refreshButtons];
  [self refreshStarDisplay];

}

- (void)didFinishGamesSignOutWithError:(NSError *)error {
  if (error) {
    NSLog(@"ERROR signing out: %@", [error localizedDescription]);
  }
  [self refreshButtons];
}

// Refresh our buttons depending on whether or not the user has signed in to
// Play Games
-(void)refreshButtons
{
  BOOL haveAuthToken = [[GPGManager sharedInstance] hasAuthorizer];
  self.signInButton.hidden = haveAuthToken;
  self.signInLabel.hidden = haveAuthToken;
  self.signOutButton.hidden = !haveAuthToken;


  BOOL signedIn = [[GPGManager sharedInstance] isSignedIn];
  for (UIButton *hideMe in self.levelButtons) {
    hideMe.hidden = !signedIn;
  }
  self.worldLabel.hidden = !signedIn;
  self.changeWorldButton.hidden = !signedIn;
  self.loadButton.hidden = !signedIn;
  self.saveButton.hidden = !signedIn;
  
  // Don't enable the sign in button if we're trying to sign the user in
  // already.
  if (self.currentlySigningIn) {
    self.signInButton.enabled = NO;
    [self.signInIndicator startAnimating];
    self.signInLabel.text = @"Please wait...";
  } else {
    self.signInButton.enabled = YES;
    [self.signInIndicator stopAnimating];
    self.signInLabel.text = @"Please Sign-In To Begin";

  }
  // Consider showing a "Loading" animation here as well.
}

- (IBAction)signInWasPressed:(id)sender {
  [[GPPSignIn sharedInstance] authenticate];
}

- (IBAction)signOutWasPressed:(id)sender {
  [[GPGManager sharedInstance] signOut];
}



# pragma mark - Actual game stuff

// We'll let every click increment the button a bit
- (IBAction)levelButtonClicked:(id)sender {
  int levelNum = [self.levelButtons indexOfObject:sender] + 1;
  int starNum = [self.gameModel getStarsForWorld:self.currentWorld andLevel:levelNum] + 1;
  if (starNum > 5) starNum = 0;
  [self.gameModel setStars:starNum forWorld:self.currentWorld andLevel:levelNum];
  [self.saveButton setTitle:@"Save*" forState:UIControlStateNormal];
  [self refreshStarDisplay];
}

// Update our level buttons
- (void)refreshStarDisplay {
  unichar blackStar = 0x2605;
  NSString *fullStar = [NSString stringWithCharacters:&blackStar length:1];
  unichar whitestar = 0x2606;
  NSString *emptyStar = [NSString stringWithCharacters:&whitestar length:1];

  
  for (int i=0; i<[self.levelButtons count]; i++) {
    int level = i+1;
    int starCount = [self.gameModel getStarsForWorld:self.currentWorld andLevel:level];
    NSString *blackStarText = [@"" stringByPaddingToLength:starCount withString:fullStar startingAtIndex:0];
    NSString *starText = [blackStarText stringByPaddingToLength:5 withString:emptyStar startingAtIndex:0];
    NSString *buttonText = [NSString stringWithFormat:@"%d-%d\n%@", self.currentWorld, level, starText];
    UIButton *buttonToUpdate = [self.levelButtons objectAtIndex:i];
    buttonToUpdate.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    buttonToUpdate.titleLabel.textAlignment = NSTextAlignmentCenter;
    [buttonToUpdate setTitle:buttonText forState:UIControlStateNormal];
  }
  self.worldLabel.text = [NSString stringWithFormat:@"World %d",self.currentWorld];  
}


- (IBAction)loadWasPressed:(id)sender {
  [self loadFromTheCloud];
}
- (IBAction)saveWasPressed:(id)sender {
  [self saveToTheCloud];
}


// In a real game, we'd probably want to save and load behind the scenes.
// Here we're calling these explicitly through buttons so you can try out
// different scenarios.
-(void)saveToTheCloud {
  [self.view bringSubviewToFront:self.savingIndicator];
  [self.savingIndicator startAnimating];
  self.loadButton.enabled = NO;
  self.saveButton.enabled = NO;

  [self.gameModel saveToCloudWithCompletionHandler:^{
    [self.savingIndicator stopAnimating];
    [self refreshStarDisplay];
    [self.saveButton setTitle:@"Save" forState:UIControlStateNormal];
    self.loadButton.enabled = YES;
    self.saveButton.enabled = YES;

  }];
}

- (void)loadFromTheCloud {
  [self.view bringSubviewToFront:self.loadingIndicator];
  [self.loadingIndicator startAnimating];
  self.loadButton.enabled = NO;
  self.saveButton.enabled = NO;
  [self.gameModel loadDataFromCloudWithCompletionHandler:^{
    [self.loadingIndicator stopAnimating];
    [self refreshStarDisplay];
    self.loadButton.enabled = YES;
    self.saveButton.enabled = YES;
  }];
}

# pragma mark - PickerView methods
- (IBAction)changeWorldClicked:(id)sender {
  
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
  return 20;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
  return [NSString stringWithFormat:@"World %d",row+1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
  self.pickerSelectedRow = row;
}

- (IBAction)changeWorld:(id)sender {
  UIActionSheet *menu = [[UIActionSheet alloc] initWithTitle:@"Choose World"
                                                    delegate:self
                                           cancelButtonTitle:@"Done"
                                      destructiveButtonTitle:@"Cancel"
                                           otherButtonTitles:nil];
  // Add the picker
  UIPickerView *pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0,185,0,0)];
  pickerView.delegate = self;
  pickerView.showsSelectionIndicator = YES;    // note this is default to NO
  [pickerView selectRow:self.currentWorld - 1 inComponent:0 animated:YES];
  
  [menu addSubview:pickerView];
  [menu showInView:self.view];
  [menu setBounds:CGRectMake(0,0,320, 700)];

}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (buttonIndex == 1) { //Done
    self.currentWorld = self.pickerSelectedRow + 1;
    [self refreshStarDisplay];
  }
}


# pragma mark - Standard lifecycle functions

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.levelButtons = [NSArray arrayWithObjects:self.level1Button,
                        self.level2Button, self.level3Button,
                        self.level4Button, self.level5Button,
                        self.level6Button, self.level7Button,
                        self.level8Button, self.level9Button,
                        self.level10Button, self.level11Button,
                        self.level12Button, nil];
  self.currentWorld = 1;
  self.gameModel = [[GCATModel alloc] init];
  
  GPPSignIn *signIn = [GPPSignIn sharedInstance];
  // You set kClientID in a previous step
  signIn.clientID = CLIENT_ID;
  signIn.scopes = [NSArray arrayWithObjects:
                   @"https://www.googleapis.com/auth/games",
                   @"https://www.googleapis.com/auth/appstate",
                   nil];
  signIn.language = [[NSLocale preferredLanguages] objectAtIndex:0];
  signIn.delegate = self;
  signIn.shouldFetchGoogleUserID =YES;

  [GPGManager sharedInstance].statusDelegate = self;
  self.currentlySigningIn = [signIn trySilentAuthentication];

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

}


-(void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self refreshButtons];
  [self refreshStarDisplay];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
