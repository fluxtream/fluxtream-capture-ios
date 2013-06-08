//
//  logger.h
//  Stetho
//
//  Created by rsargent on 10/27/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#include <stdarg.h>

#import <Foundation/Foundation.h>

typedef enum {
    kLogNormal = 30,
    kLogVerbose = 40
} LogVerbosity;

@interface Logger : NSObject
-(void) log:format, ...;
-(void) logVerbose:format, ...;
-(void) logWithVerbosity:(LogVerbosity)verbosity format:(NSString*)format args:(va_list)args;
-(void) logWithVerbosity:(LogVerbosity)verbosity msg:(NSString*)msg;
@property BOOL debugLog;
@end

