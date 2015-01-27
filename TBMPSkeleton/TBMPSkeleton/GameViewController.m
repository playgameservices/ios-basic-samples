//
//  GameViewController.m
//  TBMPTest
//
//  Created by Todd Kerpelman on 1/27/14.
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

#import "GameViewController.h"
#import "GameData.h"
#import <GooglePlayGames/GooglePlayGames.h>

@interface GameViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UISwitch *leaveSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *playerLostSwitch;
@property (weak, nonatomic) IBOutlet UIButton *takeTurnButton;
@property (weak, nonatomic) IBOutlet UILabel *turnNumberLabel;
@property (weak, nonatomic) IBOutlet UITextField *turnTextField;
@property (weak, nonatomic) IBOutlet UISwitch *winGameSwitch;

@property (nonatomic) GameData *gameData;
@property (nonatomic) NSString *nextParticipantId;
@end

@implementation GameViewController

static const int TOO_MANY_LOOPS = 20;

- (void)setMatch:(GPGTurnBasedMatch *)match {
  if (_match != match) {
    _match = match;
  }

  NSLog(@"Setting a match -- the pending participant is %@", match.pendingParticipant.participantId);

  if (_match.isMyTurn) {
    self.nextParticipantId = [self determineWhoGoesNext];
  }

  if (_match.data) {
    self.gameData = [[GameData alloc] initWitDataFromGPG:_match.data];
  } else {
    self.gameData = [[GameData alloc] init];
    self.gameData.turnCounter = 1;
  }

}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (IBAction)playerMadeSomeTextFieldEdit:(id)sender {
  self.takeTurnButton.enabled = YES;
}

- (IBAction)switchWasChanged:(id)sender {
  // Can't more than one of 'em on at the same time.
  [self.playerLostSwitch setOn:(sender == self.playerLostSwitch) animated:YES];
  [self.leaveSwitch setOn:(sender == self.leaveSwitch) animated:YES];
  [self.winGameSwitch setOn:(sender == self.winGameSwitch) animated:YES];
}


- (GPGTurnBasedParticipantResult *)findResultForParticipant:(NSString *)participantId {
  NSUInteger foundIndex = [self.match.results indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
    return [((GPGTurnBasedParticipantResult *)obj).participantId isEqualToString:participantId];
  }];
  if (foundIndex == NSNotFound)
    return nil;
  return [self.match.results objectAtIndex:foundIndex];

}

- (BOOL)isPlayerStillInGame:(GPGTurnBasedParticipant *)participantToCheck {

  // First, is the player in the game? (i.e. Have they quit?)
  if (participantToCheck.status == GPGTurnBasedParticipantStatusInvited ||
      participantToCheck.status == GPGTurnBasedParticipantStatusJoined ||
      participantToCheck.status == GPGTurnBasedParticipantStatusNotInvited) {
    // Next, are they in the results array? (i.e. Have they lost?)
    if (! [self findResultForParticipant:participantToCheck.participantId]) {
      return YES;
    }
  }
  return NO;
}


- (NSString *)determineWhoGoesNext {
  if (self.match) {
    // Determine who goes first. Match.participants will be in the same order across all games
    // so it's okay to simple pick the next person in this array.
    NSUInteger myIndex = [self.match.participants indexOfObject:self.match.localParticipant];
    if (myIndex == NSNotFound) {
      [NSException raise:@"GPGMatchSelfNotFound"
                  format:@"I couldn't find myself in the participant list."];
      return nil;
    }
    NSLog(@"According to my logs, you currently have %lu players, awaiting %d more auto-matched",
          (unsigned long) self.match.participants.count,
          self.match.matchConfig.minAutoMatchingPlayers);

    int totalPlayers =
        (int) self.match.participants.count + self.match.matchConfig.minAutoMatchingPlayers;
    NSLog(@"Or %d total players", totalPlayers);
    NSString *nextParticipantId;
    NSUInteger playerToGoNext = myIndex;
    BOOL foundValidPlayer = NO;
    int loopCheck = 0;

    do {
    playerToGoNext = (playerToGoNext + 1) % totalPlayers;
      if (playerToGoNext < self.match.participants.count) {
        GPGTurnBasedParticipant *nextParticipant = (GPGTurnBasedParticipant *)self.match.participants[playerToGoNext];
        if ([self isPlayerStillInGame:nextParticipant]) {
          nextParticipantId = nextParticipant.participantId;
          foundValidPlayer = YES;
        }
      } else {
        // We found a valid auto-match player
        nextParticipantId = nil;
        foundValidPlayer = YES;
      }
      loopCheck++;
    } while (!foundValidPlayer && loopCheck < TOO_MANY_LOOPS);

    if (loopCheck >= TOO_MANY_LOOPS) {
      [[[UIAlertView alloc] initWithTitle:@"Error"
                                  message:@"We seem to be in a game where all participants are "
        "done already. How did that happen?"
                                 delegate:nil
                        cancelButtonTitle:@"Okay"
                        otherButtonTitles:nil] show];
      return nil;
    }

    NSLog(@"Therefore our next player will be %@", nextParticipantId);

    if ([nextParticipantId isEqualToString:self.match.localParticipantId]) {
      [[[UIAlertView alloc] initWithTitle:@"You won!"
                                  message:@"All other players have been eliminated! You win!"
                                 delegate:self
                        cancelButtonTitle:@"Hooray!"
                        otherButtonTitles:nil] show];
    }
    return nextParticipantId;
  }
  return nil;
}


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
  // Let's just confirm, but I believe I'm getting this because we've determine that I'm the
  // only player left in the game
  if ([self.nextParticipantId isEqualToString:self.match.localParticipantId]) {
    [self takeWinningTurn];
  }
}

- (void)enableInterfaceIfMyTurn {
  NSArray *controlsToEnable = @[self.leaveSwitch, self.playerLostSwitch, self.takeTurnButton,
                                self.turnTextField, self.winGameSwitch];
  for (UIControl *shouldEnable in controlsToEnable) {
    shouldEnable.enabled = [self.match isMyTurn];
  }


}


- (void)refreshInterfaceFromMatchData {
  // Populate our data with the turn data
  self.turnTextField.text = self.gameData.stringToPassAround;
  self.turnNumberLabel.text = [NSString stringWithFormat:@"Turn %d", self.gameData.turnCounter];

  [self enableInterfaceIfMyTurn];
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
  [self.turnTextField resignFirstResponder];
}

- (void)takeNormalTurn {
  [self.match takeTurnWithNextParticipantId:self.nextParticipantId
                                       data:self.gameData.jsonifyAndConvertToData
                                    results:self.match.results
                          completionHandler:^(NSError *error) {
    if (error) {
      NSLog(@"I got an error! %@", [error localizedDescription]);
    } else {
      NSLog(@"Turn was taken.");
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];
}

/*
 * This is called when a player really wants to stand up from the table and leave the game, and
 * not for a typical "I have been eliminated" scenario. Call takeLosingTurn for that.
 *
 * Note that any changes the player has made to the gameData will NOT be saved. It you want
 * to do that, take a turn with the localParticipantId as the next player. Then, in the 
 * completion handler, you can call leaveInTurn.
 *
 * One other side effect here, the game will be silently cancelled if all but one player has left. 
 * If you want to avoid this, you should call finishWithData and declare the remaining player the 
 * winner.
 */

- (void)playerQuits {
  [self.match leaveDuringTurnWithNextParticipantId:self.nextParticipantId completionHandler:^(NSError *error) {
    if (error) {
      NSLog(@"I got an error! %@", [error localizedDescription]);
    } else {
      NSLog(@"Player has left the table.");
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];
}

- (void)takeLosingTurn {
  NSMutableArray *resultsToSend = [self.match.results mutableCopy];
  if ([self findResultForParticipant:self.match.localParticipantId]) {
    NSLog(@"**ERROR: Why am I calling this? It looks like I'm already in the results array");
  }
  GPGTurnBasedParticipantResult *myResult = [[GPGTurnBasedParticipantResult alloc] init];
  myResult.participantId = self.match.localParticipantId;
  myResult.result = GPGTurnBasedParticipantResultStatusLoss;

  [resultsToSend addObject:myResult];

  [self.match takeTurnWithNextParticipantId:self.nextParticipantId
                                       data:self.gameData.jsonifyAndConvertToData
                                    results:resultsToSend
                          completionHandler:^(NSError *error) {
    if (error) {
      NSLog(@"I got an error! %@", [error localizedDescription]);
    } else {
      NSLog(@"Losing turn was taken.");
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];

}
- (void)takeWinningTurn {
  NSMutableArray *resultsToSend = [NSMutableArray array];
  for (GPGTurnBasedParticipant *participant in self.match.participants) {
    GPGTurnBasedParticipantResult *playerResult = [[GPGTurnBasedParticipantResult alloc] init];
    playerResult.participantId = participant.participantId;
    if (participant == self.match.localParticipant) {
      playerResult.result = GPGTurnBasedParticipantResultStatusWin;
    } else {
      playerResult.result = GPGTurnBasedParticipantResultStatusLoss;
    }
    [resultsToSend addObject:playerResult];
  }

  [self.match finishWithData:self.gameData.jsonifyAndConvertToData
                     results:resultsToSend
           completionHandler:^(NSError *error) {
    if (error) {
      NSLog(@"I got an error! %@", [error localizedDescription]);
    } else {
      NSLog(@"Game has ended.");
      [self.navigationController popViewControllerAnimated:YES];
    }
  }];
}

- (IBAction)takeTurnWasPressed:(id)sender {
  self.gameData.stringToPassAround = self.turnTextField.text;
  self.gameData.turnCounter++;
  
  // Did the player click "win game?", or have all other players been eliminated?
  if (self.winGameSwitch.on || self.nextParticipantId == self.match.localParticipantId) {
    [self takeWinningTurn];
  } else if (self.playerLostSwitch.on){
    [self takeLosingTurn];
  } else if (self.leaveSwitch.on) {
    [self playerQuits];
  } else {
    NSLog(@"Taking normal turn");
    [self takeNormalTurn];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];

  // Let's diable the take turn button. Require you to edit something first.
  self.takeTurnButton.enabled = NO;
  [self.winGameSwitch setOn:NO];

  [self refreshInterfaceFromMatchData];

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
