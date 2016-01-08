//
//  LeaderboardManager.m
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

#import "LeaderboardManager.h"
#import "Constants.h"


@implementation LeaderboardManager
+(NSString *)getLeaderboardForDifficultyLevel:(TNDifficultyLevel)level {
    return (level == TNDifficultyLevelEasy) ? LEAD_EASY : LEAD_HARD;
}

-(void)playerFinishedGameWithScore:(int)score
                      onDifficulty:(TNDifficultyLevel)level
             withCompletionHandler:(SubmitScoreCompletionHandler)handler {
  NSString *myLeaderboardId = [LeaderboardManager getLeaderboardForDifficultyLevel:level];
  self.scoreCompletionHandler = handler;

  GPGScore *submitMe = [GPGScore scoreWithLeaderboardId:myLeaderboardId];
  submitMe.value = score;

  [submitMe submitScoreWithCompletionHandler:^(GPGScoreReport *report, NSError *error) {
    if (error) {
      NSLog(@"Received an error attempting to add to leaderboard %@: %@", submitMe, error);
    } else {
      if (report.isHighScoreForLocalPlayerToday) {
        NSLog(@"Woo hoo! Daily high score!");
      }

      self.scoreCompletionHandler(report);
    }
  }];
}

-(void)dealloc {
  self.scoreCompletionHandler = nil;
}
@end
