//
//  AdminViewController.m
//  TypeNumber
//
//  Created by Todd Kerpelman on 2/19/14.
//  Copyright (c) 2014 Google. All rights reserved.
//

#import "AdminViewController.h"
#import "Constants.h"

@interface AdminViewController ()

@end

@implementation AdminViewController


- (void)showActionCompleteAlertWithError:(NSError *)error gerund:(NSString *)gerund {
  NSString *alertMessage;
  NSString *alertTitle;
  if (error) {
    alertMessage =
        [NSString stringWithFormat:@"Error %@: %@", gerund, [error localizedDescription]];
    alertTitle = @"Error";
  } else {
    alertMessage = [NSString stringWithFormat:@"All done %@! You may need to restart your "
                                               "application to see the changes take effect.",
        gerund];
    alertTitle = @"Done!";
  }
  [[[UIAlertView alloc] initWithTitle:alertTitle
                              message:alertMessage
                             delegate:nil
                    cancelButtonTitle:@"Okay"
                    otherButtonTitles:nil] show];

}

- (IBAction)resetAllAchievements:(id)sender {
  [GPGAchievement resetAllAchievementsWithCompletionHandler:^(NSError *error) {
    [self showActionCompleteAlertWithError:error gerund:@"resetting achievements"];
  }];
}


- (IBAction)resetEasyLeaderboard:(id)sender {
  GPGLeaderboard *easyLeaderboard = [GPGLeaderboard leaderboardWithId:LEAD_EASY];
  [easyLeaderboard resetScoreWithCompletionHandler:^(NSError *error) {
    [self showActionCompleteAlertWithError:error gerund:@"resetting the Easy leaderboard"];
  }];
}

- (IBAction)resetHardLeaderboard:(id)sender {
  GPGLeaderboard *easyLeaderboard = [GPGLeaderboard leaderboardWithId:LEAD_HARD];
  [easyLeaderboard resetScoreWithCompletionHandler:^(NSError *error) {
    [self showActionCompleteAlertWithError:error gerund:@"resetting the Hard leaderboard"];
  }];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
