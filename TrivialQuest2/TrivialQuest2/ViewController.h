//
//  ViewController.h
//  TrivialQuest2
//
//  Copyright (c) 2014 Google. All rights reserved.
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

#import <UIKit/UIKit.h>
#import <GooglePlus/GooglePlus.h>
#import <GooglePlayGames.h>
@class GPPSignInButton;


@interface ViewController : UIViewController

// Sign in and Sign out buttons.
@property(weak, nonatomic) IBOutlet GPPSignInButton *signInButton;
@property(weak, nonatomic) IBOutlet UIButton *signOutButton;

// Buttons used for events.
@property(weak, nonatomic) IBOutlet UIButton *attackBlueButton;
@property(weak, nonatomic) IBOutlet UIButton *attackRedButton;
@property(weak, nonatomic) IBOutlet UIButton *attackGreenButton;
@property(weak, nonatomic) IBOutlet UIButton *attackYellowButton;
@property(weak, nonatomic) IBOutlet UIButton *showQuestsButton;
@property(weak, nonatomic) IBOutlet UIButton *showEventsButton;

@end
