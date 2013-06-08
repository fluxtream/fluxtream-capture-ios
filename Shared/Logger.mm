// System
#include <stdarg.h>

// Self
#import "Logger.h"

@implementation Logger

-(Logger*) init
{
    if (self = [super init]) {
        self.debugLog = YES;
    }
    return self;
}

-(void) log:format, ...
{
    va_list args;
    va_start(args, format);
    [self logWithVerbosity: kLogNormal format: format args: args];
    va_end(args);
}

-(void) logVerbose:format, ...
{
    va_list args;
    va_start(args, format);
    [self logWithVerbosity: kLogVerbose format: format args: args];
    va_end(args);
}

-(void) logWithVerbosity:(LogVerbosity)verbosity format:(NSString*)format args:(va_list)args
{
    [self logWithVerbosity:verbosity msg:[[NSString alloc] initWithFormat:format arguments:args]];
}

-(void) logWithVerbosity:(LogVerbosity)verbosity msg:(NSString*)msg
{
    if (self.debugLog) NSLog(@"%@", msg);
}


@end
