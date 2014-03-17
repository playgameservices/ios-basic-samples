//
//  MPManager.m
//  ButtonClicker
//
//  Created by Todd Kerpelman on 12/11/13.
//  Copyright (c) 2013 Google. All rights reserved.
//
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

#import "AppDelegate.h"
#import "MPManager.h"

@interface MPManager()
@end

@implementation MPManager 
static MPManager *_instance = nil;

+ (MPManager *)sharedInstance {
  @synchronized(self) {
    if (nil == _instance) {
      _instance = [[self alloc] init];
    }
  }
  return _instance;
}

- (void)startQuickMatchGameWithTotalPlayers:(int)totalPlayers {
  GPGMultiplayerConfig *config = [[GPGMultiplayerConfig alloc] init];
  config.minAutoMatchingPlayers = totalPlayers - 1;
  config.maxAutoMatchingPlayers = totalPlayers - 1;

  // Could also include variants or exclusive bitmasks here

  GPGRealTimeRoomViewController *roomViewController = [[GPGRealTimeRoomViewController alloc] initAndCreateRoomWithConfig:config];
  [self.lobbyDelegate showInviteViewController:roomViewController];

}

- (void)startInvitationGameWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers {
  // 2-4 player invitation UI
  NSLog(@"Showing a RTRVC with max players of %d", maxPlayers);
  GPGRealTimeRoomViewController *roomViewController =
      [[GPGRealTimeRoomViewController alloc] initWithMinPlayers:minPlayers maxPlayers:maxPlayers];
  NSLog(@"I am ready to show a room view controller %@", roomViewController);
  [self.lobbyDelegate showInviteViewController:roomViewController];

}

- (void)showIncomingInvitesScreen {
  [GPGRealTimeRoomMaker listRoomsWithMaxResults:50 completionHandler:^(NSArray *rooms, NSError *error) {
    NSMutableArray *roomsWithInvites = [NSMutableArray array];
    for (GPGRealTimeRoomData *roomData in rooms) {
      NSLog(@"Found a room %@", roomData);
      if (roomData.status == GPGRealTimeRoomStatusInviting) {
        [roomsWithInvites addObject:roomData];
      }
    }
    
    GPGRealTimeRoomViewController *invitesRoom = [[GPGRealTimeRoomViewController alloc] initWithRoomDataList:roomsWithInvites];
    [self.lobbyDelegate showInviteViewController:invitesRoom];
  }];
}

- (void)leaveRoom {
  if (self.roomToTrack && self.roomToTrack.status != GPGRealTimeRoomStatusDeleted) {
    [self.roomToTrack leave];
  }
}

- (void)didReceiveRealTimeInviteForRoom:(GPGRealTimeRoomData *)room {
  // Let's check and see if we're in the middle of a game
  
  // The following code will bring up the in-game RoomViewController UI with the current
  // invitation listed as a match invite
  NSMutableArray *roomDataList = [NSMutableArray arrayWithObject:room];
  GPGRealTimeRoomViewController *roomViewController =
  [[GPGRealTimeRoomViewController alloc] initWithRoomDataList:roomDataList];

  NSLog(@"I received an invite from our room...");
  
  if ( [((AppDelegate *)[UIApplication sharedApplication].delegate).window.rootViewController.presentedViewController
      isEqual:self.lobbyDelegate]) {
    NSLog(@"And it looks like our lobby delegate is on top right now");
    // Looks like our lobby delegate is on top right now
    [self.lobbyDelegate showInviteViewController:roomViewController];

  }

}

- (void)numberOfInvitesAwaitingResponse:(void (^)(int))returnBlock {
  [GPGRealTimeRoomMaker listRoomsWithMaxResults:50 completionHandler:^(NSArray *rooms, NSError *error) {
    int incomingInvitesCount = 0;
    for (GPGRealTimeRoomData *roomData in rooms) {
      NSLog(@"Found a room %@", roomData);
      if (roomData.status == GPGRealTimeRoomStatusInviting) {
        incomingInvitesCount += 1;
      }
    }
    returnBlock(incomingInvitesCount);
  }];
}



# pragma mark - GPGRealTimeRoomDelegate methods

- (void)room:(GPGRealTimeRoom *)room didChangeStatus:(GPGRealTimeRoomStatus)status {
  if (status == GPGRealTimeRoomStatusDeleted) {
    NSLog(@"RoomStatusDeleted");
    [self.lobbyDelegate multiPlayerGameWasCanceled];
    _roomToTrack = nil;
  } else if (status == GPGRealTimeRoomStatusConnecting) {
    NSLog(@"RoomStatusConnecting");
  } else if (status == GPGRealTimeRoomStatusActive) {
    NSLog(@"RoomStatusActive! Game is ready to go");
    _roomToTrack = room;

    // We may have a view controller up on screen if we're using the
    // invite UI
    [self.lobbyDelegate readyToStartMultiPlayerGame];
  } else if (status == GPGRealTimeRoomStatusAutoMatching) {
    NSLog(@"RoomStatusAutoMatching! Waiting for auto-matching to take place");
    _roomToTrack = room;
  } else if (status == GPGRealTimeRoomStatusInviting) {
    NSLog(@"RoomStatusInviting! Waiting for invites to get accepted");
  } else {
    NSLog(@"Unknown room status %d", status);
  }
}

- (void)room:(GPGRealTimeRoom *)room
        participant:(GPGRealTimeParticipant *)participant
    didChangeStatus:(GPGRealTimeParticipantStatus)status {
  // Not super-efficient here. Don't do this for real.
  NSString *statusString =
      @[ @"Invited", @"Joined", @"Declined", @"Left", @"Connection Made" ][status];

    NSLog(@"Room %@ participant %@ (%@) status changed to %@", room.roomDescription,
          participant.displayName, participant.participantId, statusString);
  [self.gameDelegate playerSetMayHaveChanged];
}

- (void)room:(GPGRealTimeRoom *)room didChangeConnectedSet:(BOOL)connected {
  NSLog(@"Did change connected set %@", connected ? @"Yes":@"No");
}

- (void)room:(GPGRealTimeRoom *)room didFailWithError:(NSError *)error {
  NSLog(@"*** ERROR: Room failed with error %@", [error localizedDescription]);
}

- (void)room:(GPGRealTimeRoom *)room
     didReceiveData:(NSData *)data
    fromParticipant:(GPGRealTimeParticipant *)participant
           dataMode:(GPGRealTimeDataMode)dataMode {

  unsigned char instruction;
  [data getBytes:&instruction length:sizeof(unsigned char)];
  int bufferIndex = sizeof(unsigned char);

  if (instruction == 'U' || instruction == 'F') {
    Byte score;
    [data getBytes:&score range:NSMakeRange(bufferIndex, sizeof(Byte))];
    bufferIndex += sizeof(Byte);
    [self.gameDelegate playerWithId:participant.participantId
                      reportedScore:(int) score
                            isFinal:(instruction == 'F')];
  } else {
    NSLog(@"Unknown instruction %c. Ignoring.", instruction);
  }

}

- (void)roomViewControllerDidClose:(GPGRealTimeRoomViewController *)roomViewController {
  // You get this when a user clicks cancel during the "Invite" screen
  [self.lobbyDelegate multiPlayerGameWasCanceled];
}

- (void)sendPlayersMyScore:(int)score isFinal:(BOOL)isFinal {
  NSMutableData *scoreMessage = [[NSMutableData alloc] init];
  unsigned char instruction = (isFinal) ? 'F' : 'U';
  [scoreMessage appendBytes:&instruction length:sizeof(unsigned char)];
  // Turns out the Android version sends this as a byte.
  Byte tinyScore = (Byte)(score & 0xFF);
  [scoreMessage appendBytes:&tinyScore length:sizeof(Byte)];

  if (isFinal) {
    [self.roomToTrack sendReliableDataToAll:[scoreMessage copy]];
  } else {
    [self.roomToTrack sendUnreliableDataToAll:[scoreMessage copy]];
  }
}






@end
