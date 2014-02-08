//
//  GameModel.h
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

#import <Foundation/Foundation.h>
typedef enum
{
  TNDifficultyLevelEasy,
  TNDifficultyLevelHard
}TNDifficultyLevel;


typedef void(^SubmitScoreCompletionHandler)(GPGScoreReport *report);


@interface GameModel : NSObject
-(int)requestScore:(int)score withDifficultyLevel:(TNDifficultyLevel)level;
-(void)gameOverWithScore:(int)score andDifficultyLevel:(TNDifficultyLevel)level withCompletionHandler:(SubmitScoreCompletionHandler)handler;

@property (nonatomic) int gameScore;

@end
