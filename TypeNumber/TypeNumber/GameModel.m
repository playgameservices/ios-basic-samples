//
//  GameModel.m
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

#import "GameModel.h"
#import "AchievementManager.h"
#import "LeaderboardManager.h"

@interface GameModel()

@property (nonatomic, strong) AchievementManager *achievementManager;
@property (nonatomic, strong) LeaderboardManager *leaderboardManager;
@end



// And our leaderboard IDs

@implementation GameModel

-(AchievementManager *)achievementManager {
  if (_achievementManager == nil) {
    _achievementManager = [[AchievementManager alloc] init];
  }
  return _achievementManager;
}

-(LeaderboardManager *)leaderboardManager {
  if (_leaderboardManager == nil) {
    _leaderboardManager = [[LeaderboardManager alloc] init];
  }
  return _leaderboardManager;
}


-(int)requestScore:(int)score withDifficultyLevel:(TNDifficultyLevel)level {
  // Manage any achievements that hinge on _requesting_ a score
  
  [self.achievementManager playerRequestedScore:score onDifficulty:level];
  
  // Return the score based on the difficulty level
  if (level == TNDifficultyLevelEasy) {
    self.gameScore = score;
  } else {
    self.gameScore = ceil(score / 2.0);
  }
  return self.gameScore;
}

//TODO: I should probably just trust the model's gamescore here instead
//of having it passed in from the VC.
-(void)gameOverWithScore:(int)score
      andDifficultyLevel:(TNDifficultyLevel)level
   withCompletionHandler:(SubmitScoreCompletionHandler)handler {
  // Manage any achievements that hinge on _receiving_ a score
  [self.achievementManager playerFinishedGameWithScore:score onDifficulty:level];
  
  // And submit your final score to leaderboards
  NSLog(@"Trying to submit to leaderboard...");
  [self.leaderboardManager playerFinishedGameWithScore:score onDifficulty:level withCompletionHandler:handler];
  
}


@end
