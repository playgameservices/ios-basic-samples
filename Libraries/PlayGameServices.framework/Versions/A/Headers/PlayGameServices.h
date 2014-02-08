//
// Google Play Games Platform Services
// Copyright 2013 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
     #if  __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
#pragma message "Google Play Game Services SDK requires iOS 6.0 or later."
#pragma message "If you must have Deployment Target lower than 6.0, weak link UIKit framework to prevent crashing."
#endif

#import <PlayGameServices/GPGEnums.h>
#import <PlayGameServices/GPGError.h>

#import <PlayGameServices/GPGAchievement.h>
#import <PlayGameServices/GPGAchievementController.h>
#import <PlayGameServices/GPGAchievementMetadata.h>
#import <PlayGameServices/GPGAchievementModel.h>
#import <PlayGameServices/GPGApplicationModel.h>
#import <PlayGameServices/GPGAppStateModel.h>
#import <PlayGameServices/GPGKeyedModel.h>
#import <PlayGameServices/GPGLeaderboard.h>
#import <PlayGameServices/GPGLeaderboardController.h>
#import <PlayGameServices/GPGLeaderboardMetadata.h>
#import <PlayGameServices/GPGLeaderboardModel.h>
#import <PlayGameServices/GPGLeaderboardsController.h>
#import <PlayGameServices/GPGLocalPlayerRank.h>
#import <PlayGameServices/GPGLocalPlayerScore.h>
#import <PlayGameServices/GPGManager.h>
#import <PlayGameServices/GPGPlayer.h>
#import <PlayGameServices/GPGPlayerModel.h>
#import <PlayGameServices/GPGScore.h>
#import <PlayGameServices/GPGScoreReport.h>
