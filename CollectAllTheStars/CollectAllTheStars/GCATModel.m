//
//  GCATModel.m
//  CollectAllTheStars
//
//  Originally created by Todd Kerpelman on 5/7/13.
//  Updated for Snapshots by Gus Class and Todd Kerpelman on 6/23/14.
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
//

#import "GCATModel.h"
#import "GCATStarInventory.h"
#import "GCATViewController.h"

#define DEFAULT_SAVE_NAME @"snapshotTemp"



@interface GCATModel ()

@property (nonatomic, strong) NSNumber *starSaveSlot;
@property (nonatomic, copy) DataUpdatedHandler updatedHandler;
@property (nonatomic, strong) GCATStarInventory *inventory;
@property (nonatomic, strong)GPGSnapshotMetadata* currentSnapshotMetadata;
@property (nonatomic, weak) GCATViewController* screenViewController;
@end

@implementation GCATModel

- (id)init {
  self = [super init];
  if (self) {
    self.starSaveSlot = [NSNumber numberWithInt:0];
    self.inventory = [GCATStarInventory emptyInventory];
  }
return self;
}

  // Used to update starts after model changes, model-view.
- (void) setViewController: (GCATViewController*) screenViewController{
  self.screenViewController = screenViewController;
}


/**
 * Loads the snapshot given metadata. Otherwise, either loads the current snapshot or default.
 */
- (void)loadSnapshot:(GPGSnapshotMetadata *)snapshotMetadata {

  if (snapshotMetadata != nil) {
    self.currentSnapshotMetadata = snapshotMetadata;
  }
  NSString *filename =
      (self.currentSnapshotMetadata) ? self.currentSnapshotMetadata.fileName : DEFAULT_SAVE_NAME;

  /** Open snapshot for reading. */
  NSLog(@"Opening our snapshot...");
  [GPGSnapshotMetadata openWithFileName:filename
                         conflictPolicy:GPGSnapshotConflictPolicyManual
   completionHandler:^(GPGSnapshotMetadata *snapshot,
                                           NSString *conflictId,
                                           GPGSnapshotMetadata *conflictingSnapshotBase,
                                           GPGSnapshotMetadata *conflictingSnapshotRemote,
                                           NSError *error) {
    if (error != nil) {
      NSLog(@"Error: %@", error);
      if (error.code == GPGServiceMethodFailedError) {
        // Missing permissions is a common issue. Double check you are requesting snapshot access.
      }
      return;
    }

    // If conflict ID is present, use the base and remote snapshots to create a new, resolved one.
    if (conflictId) {
      NSLog(@"Received a conflict! Let's resolve it.");
      [self resolveSnapshotWithBaseMetadata:conflictingSnapshotBase
                             remoteMetaData:conflictingSnapshotRemote
                                 conflictId:conflictId];
    } else {
      // If the conflict ID is not present, the snapshot has successfully been opened.
      NSLog(@"Snapshot: %@, %@, %@, %d", [snapshot description], [snapshot debugDescription],
            [snapshot fileName], (int)[snapshot playedTime]);
      self.currentSnapshotMetadata = snapshot;
      [self readCurrentSnapshot];
    }
  }];
}

- (void)readCurrentSnapshot {
  [self.currentSnapshotMetadata readWithCompletionHandler:^(NSData *data, NSError *error) {
    if (!error) {
      NSLog(@"Successfully read %d blocks", data.length);
      self.inventory = [GCATStarInventory starInventoryFromCloudData:data];
      [self.screenViewController allDoneWithCloud];

    } else {
      NSLog(@"Error while loading snapshot data: %@", error);
      NSLog(@"Error description: %@", [error description]);
    }
  }];
}


- (void)saveSnapshotWithImage:(UIImage *)snapshotImage {
  NSLog(@"Saving snapshot");

  if (self.currentSnapshotMetadata.isOpen) {
    [self commitCurrentSnapshotWithImage:snapshotImage];
  } else {
    NSLog(@"** Error: You really should load before you can save");
  }
}

/**
 * If you want to attempt a manual merge, this would be the way to do it.
 * Note that in general, manual merges work best if you have "union" type of merges where taking
 * the highest value is the best resolution (i.e. high scores on a level, stars per level, 
 * unlocked levels, etc.)
 */
- (void)resolveSnapshotWithBaseMetadata :(GPGSnapshotMetadata*)conflictingSnapshotBase
                          remoteMetaData:(GPGSnapshotMetadata*)conflictingSnapshotRemote
                              conflictId:(NSString*)conflictId {

  NSLog(@"Resolving snapshot conflicts: %@ >> %@",
        conflictingSnapshotBase, conflictingSnapshotRemote);

  GPGSnapshotMetadata *base = conflictingSnapshotBase;

  [conflictingSnapshotBase readWithCompletionHandler:^(NSData *baseData, NSError *error) {
    if (!error) {
      [conflictingSnapshotRemote readWithCompletionHandler:^(NSData *remoteData, NSError *error) {
        if (!error) {
          // We are going to attempt a manual resolution here by taking the two data sets and picking
          // the highest star value from both
          GCATStarInventory *baseInv = [GCATStarInventory starInventoryFromCloudData:baseData];
          GCATStarInventory *remoteInv = [GCATStarInventory starInventoryFromCloudData:remoteData];
          GCATStarInventory *mergedStars = [GCATStarInventory emptyInventory];
          for (int world=1; world<=20; world++) {
            for (int level=1; level<=12; level++) {
              int baseStars = [baseInv getStarsForWorld:world andLevel:level];
              int remoteStars = [remoteInv getStarsForWorld:world andLevel:level];
              int maxStars = MAX(baseStars, remoteStars);
              if (maxStars > 0) {
                NSLog(@"Level %d-%d had %d stars on base, %d stars on remote. Merging to %d",
                      world, level, baseStars, remoteStars, maxStars);
                [mergedStars setStars:maxStars forWorld:world andLevel:level];
              }
            }
          }

          // We have a merged data set, we need to create a merged metadata change
          GPGSnapshotMetadataChange *change = [[GPGSnapshotMetadataChange alloc] init];
          change.snapshotDescription = @"Merged save data";
          // Just an estimate, not entirely accurate.
          change.playedTime = MAX(conflictingSnapshotBase.playedTime, conflictingSnapshotRemote.playedTime);
          // By not setting the cover image, we're going to continue to use what base already had.
          NSData *mergedData = [mergedStars getCloudSaveData];
          [base resolveWithMetadataChange:change conflictId:conflictId data:mergedData completionHandler:^(GPGSnapshotMetadata *snapshotMetadata, NSError *error) {
            if (!error) {
              // Once we're done, we need to re-read the returned snapshot in case there are further
              // conflicts waiting to be merged
              [self loadSnapshot:snapshotMetadata];
            }
          }];
        }
      }];
    }                                                                          
  }];
}


- (void)commitCurrentSnapshotWithImage:(UIImage *)snapshotImage
                           description:(NSString *)description
                         savedGameData:(NSData *)gameData {
  if (!self.currentSnapshotMetadata.isOpen) {
    // Perhaps we could be harsher here and make this an assertion
    NSLog(@"Error trying to commit a snapshot. You must always open it first");
    return;
  }

  // Create a snapshot change to be committed with a description,
  // cover image, and play time.
  GPGSnapshotMetadataChange *dataChange = [[GPGSnapshotMetadataChange alloc] init];
  dataChange.snapshotDescription = description;
  // Done for simplicity, but this should really record the time since you last
  // opened a snapshot
  int millsSinceaPreviousSnapshotWasOpened = 10000;
  dataChange.playedTime =
      self.currentSnapshotMetadata.playedTime + millsSinceaPreviousSnapshotWasOpened;
  dataChange.coverImage = [[GPGSnapshotMetadataChangeCoverImage alloc] initWithImage:snapshotImage];

  [self.currentSnapshotMetadata commitWithMetadataChange:dataChange
                                                    data:gameData
                                       completionHandler:^(GPGSnapshotMetadata *snapshotMetadata, NSError *error) {
    if (!error) {
      NSLog(@"Successfully saved %@", snapshotMetadata);
      // Once our game has been saved, we should re-open it, so it's ready for saving again.
      [self loadSnapshot:snapshotMetadata];
    } else {
      NSLog(@"** Error while saving: %@", error);
    }
  }];

}

/** Saves the current Snapshot object. */
- (void)commitCurrentSnapshotWithImage:(UIImage *)snapshotImage {

  [self commitCurrentSnapshotWithImage:snapshotImage
                           description:@"Saved via iOS Sample app"
                         savedGameData:[self.inventory getCloudSaveData]];
}


- (void)setStars:(int)stars forWorld:(int)world andLevel:(int)level {
  [self.inventory setStars:stars forWorld:world andLevel:level];
}

- (int)getStarsForWorld:(int)world andLevel:(int)level {
  return [self.inventory getStarsForWorld:world andLevel:level];
}


@end
