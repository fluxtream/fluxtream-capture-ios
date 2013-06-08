//
//  TextViewLogger.m
//  Stetho
//
//  Created by rsargent on 10/27/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import "TextViewLogger.h"
#include <sys/time.h>

@implementation TextViewLogger
- (TextViewLogger *)init {
    self = [super init];
    if (self) {
        self.maxDisplayedVerbosity = kLogVerbose;
    }
    return self;
}
-(void) logWithVerbosity:(LogVerbosity)verbosity msg:(NSString*)msg
{
    [super logWithVerbosity:verbosity msg:msg];
    if (verbosity <= self.maxDisplayedVerbosity && self.textView) {
        time_t now;
        time(&now);
        struct tm *timeinfo = localtime(&now);
        msg = [NSString stringWithFormat:@"\n%02d:%02d:%02d %@",
               timeinfo->tm_hour,
               timeinfo->tm_min,
               timeinfo->tm_sec,
               msg];
        [self.textView setText:[self.textView.text stringByAppendingString:msg]];
    }
}
@end
