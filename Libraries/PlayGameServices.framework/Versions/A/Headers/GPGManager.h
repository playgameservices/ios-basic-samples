//
// Google Play Games Platform Services
// Copyright 2013 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "GPGEnums.h"

typedef void (^GPGReAuthenticationBlock)(BOOL requiresKeychainWipe, NSError *error);
typedef void (^GPGRevisionCheckBlock)(GPGRevisionStatus revisionStatus, NSError *error);

@class GPGApplicationModel;
@class GPPSignIn;

extern NSString * const GPGUserDidSignOutNotification;

@interface GPGManager : NSObject

+ (GPGManager *)sharedInstance;

#pragma mark Application State 

- (GPGApplicationModel *)applicationModel;
- (NSString *)applicationId;

#pragma mark Authentication 
- (BOOL)hasAuthorizer;

- (void)signout;

- (void)signIn:(GPPSignIn *)signIn
    reauthorizeHandler:(GPGReAuthenticationBlock)reauthenticationBlock;


#pragma mark Device Orientation 
@property(nonatomic, readwrite, assign) NSUInteger validOrientationFlags;

@property(nonatomic, readwrite, assign) NSUInteger welcomeBackOffset;

@property(nonatomic, readwrite, assign) GPGToastPlacement welcomeBackToastPlacement;

@property(nonatomic, readwrite, assign) NSUInteger achievementUnlockedOffset;

@property(nonatomic, readwrite, assign) GPGToastPlacement achievementUnlockedToastPlacement;

@property(nonatomic, readwrite, assign) NSUInteger sdkTag;

#pragma mark - SDK Deprecation Check

- (void)refreshRevisionStatus:(GPGRevisionCheckBlock)revisionCheckHandler;

- (GPGRevisionStatus)revisionStatus;

- (BOOL)isRevisionValid;

@end
