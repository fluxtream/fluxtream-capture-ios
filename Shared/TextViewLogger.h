//
//  TextViewLogger.h
//  Stetho
//
//  Created by rsargent on 10/27/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import "Logger.h"

@interface TextViewLogger : Logger

@property (weak, nonatomic) UITextView *textView;
@property (nonatomic) LogVerbosity maxDisplayedVerbosity;

-(void) logWithVerbosity:(LogVerbosity)verbosity msg:(NSString*)msg;

@end
