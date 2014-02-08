//
//  GCATModel.m
//  CollectAllTheStars
//
//  Created by Todd Kerpelman on 5/7/13.
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
//

#import "GCATModel.h"
#import "GCATStarInventory.h"

@interface GCATModel ()

@property (nonatomic, strong) NSNumber *starSaveSlot;
@property (nonatomic, copy) DataUpdatedHandler updatedHandler;
@property (nonatomic, strong) GCATStarInventory *inventory;
@end

@implementation GCATModel

- (id)init {
  self = [super init];
  if (self) {
    _starSaveSlot = [NSNumber numberWithInt:0];
    _inventory = [GCATStarInventory emptyInventory];
  }
return self;
}

- (void)loadDataFromCloudWithCompletionHandler:(DataUpdatedHandler)handler {
  
  self.updatedHandler = handler;
  GPGAppStateModel *model = [GPGManager sharedInstance].applicationModel.appState;
  
  [model loadForKey:self.starSaveSlot completionHandler:^(GPGAppStateLoadStatus status, NSError *error) {
    if (status == GPGAppStateLoadStatusNotFound) {
      // "Not found" = "No data has ever been saved for this player yet"
      // Usually this means we have a brand new player.
      self.inventory = [GCATStarInventory emptyInventory];
    } else if (status == GPGAppStateLoadStatusSuccess) {
      self.inventory = [GCATStarInventory starInventoryFromCloudData:[model stateDataForKey:self.starSaveSlot]];
    }
    handler();
  } conflictHandler:^NSData *(NSNumber *key, NSData *localState, NSData *remoteState) {
    // This is really a "heads up" handler to let us know that some other device
    // besides this one wrote to the cloud since our last save. In our case,
    // we'll just let the remoteState overwrite what we had before, which is
    // usually the right way to respond.
    NSLog(@"Ran into a conflict during load. \nLocal state: %@\nRemote state: %@",
          [[NSString alloc] initWithData:localState encoding:NSUTF8StringEncoding],
          [[NSString alloc] initWithData:remoteState encoding:NSUTF8StringEncoding]);
    return remoteState;
  }];
}


- (void)saveToCloudWithCompletionHandler:(DataUpdatedHandler)handler {
  
  self.updatedHandler = handler;
  GPGAppStateModel *model = [GPGManager sharedInstance].applicationModel.appState;
  [model setStateData:[self.inventory getCloudSaveData] forKey:self.starSaveSlot];
  
  [model updateForKey:self.starSaveSlot completionHandler:^(GPGAppStateWriteStatus status, NSError *error) {
    // In case anything changed during the conflict handler, I should reload my data
    if (error) {
      [[[UIAlertView alloc] initWithTitle:@"OMG! Error!" message:[error localizedDescription] delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles: nil] show];
    } else {
      self.inventory = [GCATStarInventory starInventoryFromCloudData:[model stateDataForKey:self.starSaveSlot]];
      handler();
    }
  } conflictHandler:^NSData *(NSNumber *key, NSData *localState, NSData *remoteState) {
    // Oops. Somebody else wrote to the cloud since our last load. No problem.
    // we can logically merge it
 
    NSLog(@"Ran into a conflict during save. \nLocal state: %@\nRemote state: %@",
          [[NSString alloc] initWithData:localState encoding:NSUTF8StringEncoding],
          [[NSString alloc] initWithData:remoteState encoding:NSUTF8StringEncoding]);
    return [self resolveState:localState andSecondState:remoteState];
  }];
  
}

// We're going to resolve our two sets of data simply by taking the max stars from
// each level, which will make our users happy.
// This is assuming a user's star level would never decrease, which
// accurately reflects most mobile games, although technically not our test app.
- (NSData *)resolveState:(NSData *)firstState andSecondState:(NSData *)secondState
{
  GCATStarInventory *mergedStars = [GCATStarInventory emptyInventory];
  GCATStarInventory *invA = [GCATStarInventory starInventoryFromCloudData:firstState];
  GCATStarInventory *invB = [GCATStarInventory starInventoryFromCloudData:secondState];
  for (int world=1; world<=20; world++) {
    for (int level=1; level<=12; level++) {
      int maxStars = MAX([invA getStarsForWorld:world andLevel:level],
                         [invB getStarsForWorld:world andLevel:level]);
      if (maxStars > 0) {
        [mergedStars setStars:maxStars forWorld:world andLevel:level];
      }
    }
  }
  return [mergedStars getCloudSaveData];  
  
  
}

- (void)setStars:(int)stars forWorld:(int)world andLevel:(int)level {
  [self.inventory setStars:stars forWorld:world andLevel:level];
}

- (int)getStarsForWorld:(int)world andLevel:(int)level {
  return [self.inventory getStarsForWorld:world andLevel:level];
}


@end
