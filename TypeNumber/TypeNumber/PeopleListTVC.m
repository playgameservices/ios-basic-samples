//
//  PeopleListTVC.m
//  TypeNumber
//
//  Created by Todd Kerpelman on 2/6/13.
//  Copyright (c) 2013 Google. All rights reserved.
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
#import <GoogleOpenSource/GoogleOpenSource.h>
#import "AppDelegate.h"
#import "PeopleListTVC.h"

@interface PeopleListTVC ()

@property (nonatomic, strong) NSArray *myPeeps;

@end

@implementation PeopleListTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  GTLServicePlus* plusService = [[GPPSignIn sharedInstance] plusService];


  // Let's just find my friends who have this app installed!
  GTLQueryPlus *query = [GTLQueryPlus queryForPeopleListWithUserId:@"me"
                                                        collection:@"connected"];
  
  query.maxResults = 20;
  
  
  [plusService executeQuery:query
          completionHandler:^(GTLServiceTicket *ticket,
                              GTLPlusPeopleFeed *peopleFeed,
                              NSError *error) {
            if (error) {
              NSLog(@"Error: %@", error);
            } else {
              // Get an array of people from GTLPlusPeopleFeed
              NSLog(@"Query results: %@", peopleFeed);
              if (peopleFeed.nextPageToken) {
                NSLog(@"Wow! There's more than our maxResults here. That's a lot of people");
              }
              self.myPeeps = peopleFeed.items;
              NSLog(@"People list is %@",self.myPeeps);
              [self.tableView reloadData];
            }
          }
   ];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
  self.myPeeps = nil;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.myPeeps count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *CellIdentifier = @"personCell";
  GTLPlusPerson *personToShow = (GTLPlusPerson *)[self.myPeeps objectAtIndex:indexPath.row];

  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
  }
  if (personToShow.image) {
    cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:personToShow.image.url]]];
  }

  NSLog(@"Person image is %@", personToShow.image.url);

  cell.textLabel.text = personToShow.displayName;
  
  
  
  return cell;
}




@end
