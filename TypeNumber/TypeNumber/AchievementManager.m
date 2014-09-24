//
//  AchievementManager.m
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

#import "AchievementManager.h"
#import "Constants.h"


@implementation AchievementManager


-(void)unlockAchievement:(NSString *)achievementId;
{
  GPGAchievement *unlockMe = [GPGAchievement achievementWithId:achievementId];

  [unlockMe unlockAchievementWithCompletionHandler:^(BOOL newlyUnlocked, NSError *error) {
    if (error) {
      NSLog(@"Received an error attempting to unlock an achievement %@: %@", unlockMe, error);
    }
  }];
}

-(void)makeIncrementalProgress:(NSString *)achievementId withSteps:(NSInteger)progressAmount
{
  NSLog(@"Your progress amount is %i", (int32_t)progressAmount );

  GPGAchievement *incrementMe = [GPGAchievement achievementWithId:achievementId];

  [incrementMe incrementAchievementNumSteps:progressAmount completionHandler:^(BOOL newlyUnlocked, int currentSteps, NSError *error) {
    if (error) {
      NSLog(@"Received an error attempting to increment achievement %@: %@",incrementMe, error);
    } else if (newlyUnlocked) {
      NSLog(@"Incremental achievement unlocked!");
    } else {
      NSLog(@"You've completed %i steps total", currentSteps);
    }
  }];
}


-(void)playerRequestedScore:(int)score onDifficulty:(TNDifficultyLevel)level
{
  if (score == 0) {
    [self unlockAchievement:ACH_HUMBLE];
  } else if (score == 9999) {
    [self unlockAchievement:ACH_COCKY];
  }

}

-(BOOL)isPrime:(int)checkMe
{
  if (checkMe == 1) return NO;

  int checkMax = floor(sqrt(checkMe));
  for (int i =2; i<=checkMax; i++) {
    if (checkMe % i == 0) return NO;
  }
  return YES;
}


-(void)playerFinishedGameWithScore:(int)score onDifficulty:(TNDifficultyLevel)level
{
  if (score == 1337) {
    [self unlockAchievement:ACH_LEET];
  } else if ([self isPrime:score]) {
    [self unlockAchievement:ACH_PRIME];
  }
  [self makeIncrementalProgress:ACH_BORED withSteps:1];
  [self makeIncrementalProgress:ACH_REALLY_BORED withSteps:1];
}

@end
