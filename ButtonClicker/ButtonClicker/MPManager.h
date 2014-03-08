//
//  MPManager.h
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

#import <Foundation/Foundation.h>

@protocol MPLobbyDelegate <GPGRealTimeRoomDelegate>


- (void)readyToStartMultiPlayerGame;
- (void)multiPlayerGameWasCanceled;
- (void)showInviteViewController:(UIViewController *)vcToShow;

@end

@protocol MPGameDelegate
- (void)playerWithId:(NSString *)playerId reportedScore:(int)score isFinal:(BOOL)final;
- (void)playerSetMayHaveChanged;
@end


@interface MPManager : NSObject <GPGRealTimeRoomDelegate>
@property (nonatomic, weak) id<MPLobbyDelegate> lobbyDelegate;
@property (nonatomic, weak) id<MPGameDelegate> gameDelegate;
@property (nonatomic, readonly) GPGRealTimeRoom *roomToTrack;

/**
 * Accessor method for the singleton instance
 */
+ (MPManager *)sharedInstance;

/**
 * Creates a quick match room. 
 *
 * @param totalPlayers All players to add to the match (local player included)
 */
- (void)startQuickMatchGameWithTotalPlayers:(int)totalPlayers;

/**
 * Creates an invitation controller and tells the lobbyDelegate to display it
 *
 * @param minPlayers Minimum number of other opponents host is allowed to invite
 * @param maxPlayers Maximum number of other opponents host is allowed to invite
 */
- (void)startInvitationGameWithMinPlayers:(int)minPlayers maxPlayers:(int)maxPlayers;

/**
 * Sends your player's score to everybody else in the room
 *
 * @param score Total score up to this point
 * @param isFinal Is this the player's final score? 
 */
- (void)sendPlayersMyScore:(int)score isFinal:(BOOL)isFinal;

/**
 * Safely leaves the room and alerts the other players. Typically called at the end of a 
 * match.
 */
- (void)leaveRoom;


/**
 * Find out if we have any invitations that are waiting our response
 *
 */
-(void)numberOfInvitesAwaitingResponse:(void (^)(int))returnBlock;


-(void)showIncomingInvitesScreen;
@end
