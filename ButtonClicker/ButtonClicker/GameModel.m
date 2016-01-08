//
//  GameModel.m
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

#import "GameModel.h"
#import "MPManager.h"
#import "ButtonClickerPlayer.h"

@interface GameModel () {
  CFTimeInterval _startTime;
  NSString *_localPlayerId;
  CFTimeInterval _gameOverTimeoutTime;
}
@property (nonatomic) NSMutableDictionary *allPlayers;
@end

static const double kTotalGameTime = 20.0;


@implementation GameModel

- (id)init {
  self = [super init];
  if (self) {
    // Custom intiialization here
  }
  return self;
}


- (void)createPracticeGame {
  // Practice game.
  _allPlayers = [[NSMutableDictionary alloc] initWithCapacity:1];
  ButtonClickerPlayer *localPlayer = [[ButtonClickerPlayer alloc] init];

  localPlayer.participantId = @"a12345";
  localPlayer.displayName = @"Practice dude";
  localPlayer.score = 0;
  localPlayer.scoreIsFinal = NO;
  [self.allPlayers setObject:localPlayer forKey:localPlayer.participantId];
  _localPlayerId = [localPlayer.participantId copy];
  _gameState = BCGameStateWaitingToStart;
}

- (void)prepareToStart {
  if (![[MPManager sharedInstance] roomToTrack]) {
    [self createPracticeGame];
    return;
  }


  NSInteger numPlayers = [[[[MPManager sharedInstance] roomToTrack] participants] count] + 1;
  _allPlayers = [[NSMutableDictionary alloc] initWithCapacity:numPlayers];

  // Let's populate our player list from the room. This now includes the local player
  GPGRealTimeRoom *room = [[MPManager sharedInstance] roomToTrack];

  [room enumerateParticipantsUsingBlock:^(GPGRealTimeParticipant *roomPlayer) {
    ButtonClickerPlayer *nextPlayer = [[ButtonClickerPlayer alloc] init];
    nextPlayer.participantId = roomPlayer.participantId;
    nextPlayer.displayName = roomPlayer.displayName;
    [self.allPlayers setObject:nextPlayer forKey:nextPlayer.participantId];
    NSLog(@"Adding player %@ -- %@", nextPlayer.displayName, nextPlayer.participantId);

  }];

  _localPlayerId = [room.localParticipant.participantId copy];
  _gameState = BCGameStateWaitingToStart;
}

- (void)startGame {
  if (_gameState == BCGameStateWaitingToStart) {
    _gameState = BCGameStatePlaying;
    _startTime = CACurrentMediaTime();
  }
}

- (void)playerWithId:(NSString *)participantId reportedScore:(int)newScore isFinal:(BOOL)isFinal {
  if ([self.allPlayers objectForKey:participantId]) {
    ButtonClickerPlayer *opponent =
        (ButtonClickerPlayer *)[self.allPlayers objectForKey:participantId];
    // Some commands could arrive out of order, so we can probably ignore any case where the
    // score has gone down.
    if (newScore > opponent.score) {
      opponent.score = newScore;
    }
    if (isFinal) {
      opponent.scoreIsFinal = YES;
    }
  } else {
    NSLog(@"This is odd. Received a score updated for a player not on my list?!");
  }
}

// Sort players in descending order
- (NSArray *)getListOfPlayersSortedByScore {
  NSArray *sortedPlayers = [[self.allPlayers allValues] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
      if ([(ButtonClickerPlayer *)obj1 score] < [(ButtonClickerPlayer *)obj2 score]) {
        return NSOrderedDescending;
      } else if ([(ButtonClickerPlayer *)obj1 score] > [(ButtonClickerPlayer *)obj2 score]) {
        return NSOrderedAscending;
      } else {
        return NSOrderedSame;
      }
  }];

  return sortedPlayers;
}

- (CFTimeInterval)timeLeft {
  CFTimeInterval timeLeft = MAX(0, kTotalGameTime - (CACurrentMediaTime() - _startTime));
  return timeLeft;
}

- (void)refreshPlayerSet {
  [[[MPManager sharedInstance] roomToTrack]
      enumerateParticipantsUsingBlock:^(GPGRealTimeParticipant *nextPlayer) {
          NSLog(@"I have participant %@ with status %ld", nextPlayer.displayName, nextPlayer.status);
          if (nextPlayer.status == GPGRealTimeParticipantStatusLeft) {
            ((ButtonClickerPlayer *)[self.allPlayers objectForKey:nextPlayer.participantId])
                .scoreIsFinal = YES;
          } else if (nextPlayer.status == GPGRealTimeParticipantStatusJoined &&
                     [self.allPlayers objectForKey:nextPlayer.participantId] == nil) {
            NSLog(@"Looks like we added a player late.");
            ButtonClickerPlayer *newlyJoinedPlayer = [[ButtonClickerPlayer alloc] init];
            newlyJoinedPlayer.participantId = nextPlayer.participantId;
            newlyJoinedPlayer.displayName = nextPlayer.displayName;
            [self.allPlayers setObject:newlyJoinedPlayer forKey:newlyJoinedPlayer.participantId];
          }
        }];
  [self updateStateIfNeeded];
}

- (void)updateStateIfNeeded {
  if (_gameState == BCGameStatePlaying) {
    if (self.timeLeft <= 0) {
      ButtonClickerPlayer *me =
          (ButtonClickerPlayer *)[self.allPlayers objectForKey:_localPlayerId];
      me.scoreIsFinal = YES;
      [[MPManager sharedInstance] sendPlayersMyScore:me.score isFinal:YES];
      _gameState = BCGameStateWaitingToFinish;
      // We could probably be more sophisticated here
      _gameOverTimeoutTime = CACurrentMediaTime() + 10.0;
    }
  } else if (_gameState == BCGameStateWaitingToFinish) {
    // Timed out! Let's mark everybody else as finished
    if (CACurrentMediaTime() >= _gameOverTimeoutTime) {
      for (ButtonClickerPlayer *nextPlayer in [self.allPlayers allValues]) {
        nextPlayer.scoreIsFinal = YES;
        NSLog(@"Marking score as final");
      }
    }

    BOOL allFinished = YES;
    for (ButtonClickerPlayer *nextPlayer in [self.allPlayers allValues]) {
      if (!nextPlayer.scoreIsFinal) {
        allFinished = NO;
      }
    }
    if (allFinished) {
      _gameState = BCGameStateDone;
    }
  }

}

- (void)playerDidClick {
  [self updateStateIfNeeded];
  if (_gameState != BCGameStatePlaying)
    return;
  ButtonClickerPlayer *me = (ButtonClickerPlayer *)[self.allPlayers objectForKey:_localPlayerId];
  me.score++;
  [[MPManager sharedInstance] sendPlayersMyScore:me.score isFinal:NO];
}


@end
