//
// Google Play Games Platform Services
// Copyright 2013 Google Inc. All rights reserved.
//


#pragma mark - Achievements

// Achievement types.
typedef enum {
  GPGAchievementTypeUnknown = -1,
  // Standard achievement.
  GPGAchievementTypeStandard,
  // Incremental achievement.
  GPGAchievementTypeIncremental,
} GPGAchievementType;

// Achievement states.
typedef enum {
  GPGAchievementStateUnknown = -1,
  // Achievement is hidden.
  GPGAchievementStateHidden,
  // Achievement is revealed.
  GPGAchievementStateRevealed,
  // Achievement is unlocked.
  GPGAchievementStateUnlocked,
} GPGAchievementState;

#pragma mark - Leaderboards

// Leaderboard time scopes.
typedef enum {
  GPGLeaderboardTimeScopeUnknown = -1,
  // Custom values to match enum values from PlayLog event
  // Today's leaderboard scores.
  GPGLeaderboardTimeScopeToday = 1,
  // This week's leaderboard scores.
  GPGLeaderboardTimeScopeThisWeek = 2,
  // All time leaderboard scores.
  GPGLeaderboardTimeScopeAllTime = 3
} GPGLeaderboardTimeScope;

typedef enum {
  GPGLeaderboardOrderUnknown = -1,
  GPGLeaderboardOrderLargerIsBetter,
  GPGLeaderboardOrderSmallerIsBetter,
} GPGLeaderboardOrder;


#pragma mark - App State

// Status returned when a client tries to load app state data.
typedef enum {
  // Unknown error
  GPGAppStateLoadStatusUnknownError = -1,
  // App State loaded successfully.
  GPGAppStateLoadStatusSuccess,
  // No data stored for key
  GPGAppStateLoadStatusNotFound,
} GPGAppStateLoadStatus;

// Status returned when a client tries to update app state.
typedef enum {
  // Unknown error.
  GPGAppStateWriteStatusUnknownError = -1,
  // App State updated successfully.
  GPGAppStateWriteStatusSuccess,
  // Key, data, or version string invalid or missing
  GPGAppStateWriteStatusBadKeyDataOrVersion,
  // Need to create new key but number of keys allowed is exceeded
  GPGAppStateWriteStatusKeysQuotaExceeded,
  // Data not found for clear action
  GPGAppStateWriteStatusNotFound,
  // Tried to update with older version than on server,
  // or no existing version on server
  GPGAppStateWriteStatusConflict,
  // Key or data oversized.
  GPGAppStateWriteStatusSizeExceeded,
} GPGAppStateWriteStatus;

// Toast view placement.
typedef enum {
  kGPGToastPlacementTop,
  kGPGToastPlacementBottom,
  kGPGToastPlacementCenter,
} GPGToastPlacement;

#pragma mark - Revision status

// SDK revision check status
typedef enum {
  GPGRevisionStatusUnknown = -1,
  // Revision is up-to-date
  GPGRevisionStatusOK,
  // Revision is deprecated and should upgrade soon.
  GPGRevisionStatusDeprecated,
  // Revision is invalid and will not work.
  GPGRevisionStatusInvalid,
} GPGRevisionStatus;


