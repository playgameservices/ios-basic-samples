//
// Google Play Games Platform Services
// Copyright 2013 Google Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const GPGErrorDomain;

enum {
  GPGInvalidAuthenticationError = 1, // No valid authentication found. You must authenticate the user before executing the action that returned this error.

  GPGNetworkUnavailableError, // The network is offline, a network operation cannot be completed.

  GPGServiceMethodFailedError, // A method from the games service failed.

  GPGRevisionStaleError, // Current SDK version is either deprecated or invalid.

};

@interface GPGError : NSError
@end

