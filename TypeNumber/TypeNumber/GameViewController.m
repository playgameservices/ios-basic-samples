//
//  GameViewController.m
//  TypeNumber
//
//  Created by Todd Kerpelman on 9/25/12.
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
#import <GoogleOpenSource/GTLBase64.h>
#import "AppDelegate.h"
#import "Constants.h"
#import "GameViewController.h"
#import "LeaderboardManager.h"

@interface GameViewController () <GPPShareDelegate>
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerMessage;
@property (weak, nonatomic) IBOutlet UILabel *finalScoreLabel;
@property (weak, nonatomic) IBOutlet UITextField *scoreRequestTextField;
@property (weak, nonatomic) IBOutlet UIButton *bigActionButton;
@property (weak, nonatomic) IBOutlet UIButton *seeHighScoresButton;
@property (weak, nonatomic) IBOutlet UIButton *bragButton;
@property (weak, nonatomic) IBOutlet UILabel *highScoreLabel;
@property (weak, nonatomic) IBOutlet UILabel *incomingChallengeLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waitingForHighScore;
@property (nonatomic) BOOL gameOver;
@property (strong, nonatomic) GameModel *gameModel;
@end

@implementation GameViewController

-(GameModel *)gameModel
{
  if (_gameModel == nil) {
    _gameModel = [[GameModel alloc] init];
  }
  return _gameModel;
}

-(void)reportOnHighScore:(GPGScoreReport *)scoreReport
{
  [self.waitingForHighScore stopAnimating];
  if ([scoreReport isHighScoreForLocalPlayerThisWeek] && self.gameOver) {
    self.highScoreLabel.text = @"New high score for this week!";
    self.highScoreLabel.hidden = NO;
    self.bragButton.hidden = NO;
  } else {
    self.highScoreLabel.text = [NSString stringWithFormat: @"This weeks high score: %@", [[scoreReport highScoreForLocalPlayerThisWeek] formattedScore]];
    self.highScoreLabel.hidden = NO;
    self.bragButton.hidden = YES;
  }

}

- (void)finishedSharing: (BOOL)shared {
  if (shared) {
    NSLog(@"User successfully shared!");
  } else {
    NSLog(@"User didn't share.");
  }
}


-(void)presentGameOverWithScore:(int)finalScore
{
  if (self.gameOver) {
    self.finalScoreLabel.text = [NSString stringWithFormat:@"%i",finalScore];
    self.finalScoreLabel.hidden = NO;
    self.scoreRequestTextField.hidden = YES;
    if (self.difficulty == TNDifficultyLevelEasy) {
      self.playerMessage.text = @"Good choice! Your final score is...";
    } else {
      self.playerMessage.text = @"What, you thought it would be that easy? Your final score is...";
    }
    if (self.incomingChallenge != nil) {
      if (finalScore > [(NSNumber *)[self.incomingChallenge valueForKey:@"scoreToBeat"] intValue] ) {
        self.incomingChallengeLabel.text = @"Challenge beaten! Good work!";
      } else {
        self.incomingChallengeLabel.text = @"Challenge not beaten.";
      }
    }

    [self.bigActionButton setTitle:@"New Game" forState:UIControlStateNormal];
    [self.waitingForHighScore startAnimating];
    [self.gameModel gameOverWithScore:finalScore andDifficultyLevel:self.difficulty withCompletionHandler:^(GPGScoreReport *report) {
      [self reportOnHighScore:report];
    }];
    self.seeHighScoresButton.hidden = NO;
  }
}

-(void)presentNewGame
{
  // Fix the title
  self.titleLabel.text = (self.difficulty == TNDifficultyLevelEasy) ? @"Type-a-Number: Easy" : @"Type-a-Number: Hard";

  if (! self.gameOver) {
    self.highScoreLabel.hidden = YES;
    self.finalScoreLabel.hidden = YES;
    self.bragButton.hidden = YES;
    self.scoreRequestTextField.hidden = NO;
    self.playerMessage.text = @"What score do you think you deserve?";
    self.scoreRequestTextField.text = @"";
    [self.bigActionButton setTitle:@"Request" forState:UIControlStateNormal];
    self.seeHighScoresButton.hidden = YES;

    if (self.incomingChallenge == nil) {
      self.incomingChallengeLabel.hidden = YES;
    } else {
      self.incomingChallengeLabel.text = [NSString stringWithFormat:@"Incoming challenge! Beat %@'s score of %@",
                                          [self.incomingChallenge valueForKey:@"challenger"],
                                          [self.incomingChallenge valueForKey:@"scoreToBeat"]];
      self.incomingChallengeLabel.hidden = NO;
    }
  }

}


- (IBAction)bigButtonClicked:(id)sender {
  if (! self.gameOver) {
    NSNumberFormatter *nsnf = [[NSNumberFormatter alloc] init];
    int userScore = [(NSNumber *)[nsnf numberFromString:self.scoreRequestTextField.text] intValue];

    // Just to be sure
    userScore = MIN(MAX(0, userScore), 9999);

    int finalScore = [self.gameModel requestScore:userScore withDifficultyLevel:self.difficulty];
    self.gameOver = YES;
    [self presentGameOverWithScore:finalScore];
  } else {
    self.gameOver = NO;
    [self presentNewGame];
  }

}

- (IBAction)bragButtonClicked:(id)sender {


  // Let's initiate a share object.

  NSString *difficultyString = (self.difficulty == TNDifficultyLevelEasy) ? @"Easy" : @"Hard";
  NSString *prefillText = [NSString stringWithFormat:@"I just got a score of %d on the %@ level of the Type-a-Number Challenge. Can you beat it?", self.gameModel.gameScore, difficultyString];

  // All of your data is going to be passed in through a URL that look something like
  // com.example.mygame://google/link/?deep_link_id=xxxxx&gplus_source=stream
  // There are lots of ways to encode this. I'm going to go for url-encoded JSON, which is
  // pretty well established and has nice library support.

  [GPGPlayer localPlayerWithCompletionHandler:^(GPGPlayer *player, NSError *error) {
    NSString *playerName = [player displayName];
    NSDictionary *parameters = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSNumber numberWithInt:self.difficulty], @"difficulty",
                                playerName, @"challenger",
                                [NSNumber numberWithInt:self.gameModel.gameScore], @"scoreToBeat", nil];

    NSData *jsonified = [NSJSONSerialization dataWithJSONObject:parameters options:0 error:nil];
    NSString *deepLinkID =[[NSString alloc] initWithData:jsonified encoding:NSUTF8StringEncoding];
    NSString *encodedID = GTLEncodeWebSafeBase64([deepLinkID dataUsingEncoding:NSUTF8StringEncoding]);
    NSLog(@"Deeplink id is %@ \nEncoded it looks like %@",deepLinkID,encodedID);

    // If you're on a platform that doesn't support deep-linking, you can
    // try adding a link to the web version of your game (if you have one), or
    // a product marketing page (if you don't). I'm going to be optimistic and
    // assume we'll eventually have this working on the Type-a-number web sample
    NSURL *webLink = [NSURL URLWithString:[NSString stringWithFormat:@"%@?gamedata=%@", WEB_GAME_URL, encodedID]];


    GPPShare *share = [GPPShare sharedInstance];
    [GPPShare sharedInstance].delegate = self;

    // Let's create the share dialog now!
    id<GPPShareBuilder> shareDialog = [share nativeShareDialog];

    //[shareDialog setPrefillText:prefillText];
    [shareDialog setContentDeepLinkID:encodedID];
    // This line is unused
    [shareDialog setTitle:@"Oh yeah" description:@"You will never see this" thumbnailURL:nil];
    [shareDialog setPrefillText:prefillText];
    [shareDialog setURLToShare:webLink];
    [shareDialog setCallToActionButtonWithLabel:@"PLAY" URL:webLink deepLinkID:encodedID];
    [shareDialog open];
  }];
}

- (IBAction)seeHighScoresClicked:(UIButton *)sender {
  NSString *targetLeaderboardId = [LeaderboardManager getLeaderboardForDifficultyLevel:self.difficulty];

  [[GPGLauncherController sharedInstance] presentLeaderboardWithLeaderboardId:targetLeaderboardId];
}


# pragma mark - TextField utility functions


// Code to limit our text field to 4 characters. Thanks, stackoverflow!
#define MAXLENGTH 4

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

  NSUInteger oldLength = [textField.text length];
  NSUInteger replacementLength = [string length];
  NSUInteger rangeLength = range.length;
  NSUInteger newLength = oldLength - rangeLength + replacementLength;

  BOOL returnKey = [string rangeOfString: @"\n"].location != NSNotFound;

  return newLength <= MAXLENGTH || returnKey;
}


-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self.scoreRequestTextField resignFirstResponder];
}

# pragma mark - Standard lifecycle stuff

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    // Custom initialization
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.gameOver = NO;
  self.scoreRequestTextField.delegate = self;

  // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self presentNewGame];

}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
