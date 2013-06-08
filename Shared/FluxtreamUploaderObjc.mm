//
//  FluxtreamUploaderObjc.mm
//  HeartRateMonitor
//
//  Created by bodytrack on 10/13/12.
//

#import "FluxtreamUploaderObjc.h"
#include "NSUtils.h"
#include "Utils.h"
#include "Samples.h"
#import "Constants.h"

#include <algorithm>
#include <libkern/OSAtomic.h>

@implementation FluxtreamUploaderObjc

- (id)init
{
    if (self = [super init]) {
        samplesPtr = new Samples();
        uploadTimer = nil;
        self.maximumAge = 60.0;
        self.maximumUploadSampleCount = 10000;
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        self.serverPrefix = [defaults objectForKey:DEFAULTS_SERVER];
        lastUploadTime = 0;
        uploadScheduled = 0;
        lastResult = @"";
        self.logSamples = NO;
    }
    return self;
}

-(void)dealloc {
    delete (Samples*)samplesPtr;
    samplesPtr = NULL;
}

- (Samples*)samples
{
    return (Samples*)samplesPtr;
}

- (void)uploadNow
{
    OSAtomicTestAndClear(7, &uploadScheduled);
    uploadTimer = nil;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *urlString = [NSString
                     stringWithFormat:@"http://%@/api/bodytrack/jupload?dev_nickname=%@",
                     self.serverPrefix, self.deviceNickname];
    NSURL *url = [NSURL URLWithString:urlString];
    [request setURL:url];

    size_t uploadCount = std::min([self samples]->size(), _maximumUploadSampleCount);
    size_t nextSequence; // set by getJSON
    std::string json = [self samples]->getJSON(uploadCount, nextSequence);
        
    NSData *body = [NSData dataWithBytes: json.c_str() length: json.length()];
    NSString *bodyLength = [NSString stringWithFormat:@"%ld", (long)[body length]];
    [request setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
    
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64encode(authData)];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    [request setHTTPBody:body];

    NSLog(@"%@ about to post %ld samples", self.deviceNickname, uploadCount);
    
    lastResult = @"Connecting to server for upload...";
    
    // Delete cookies to force authentication from scratch each time
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray *cookies = [cookieStorage cookies];
    for (NSHTTPCookie *cookie in cookies) {
        [cookieStorage deleteCookie:cookie];
    }
    
    // to get HTTP status on error, consider something like
    // initWithRequest:delegate: and didReceiveResponse
    [NSURLConnection sendAsynchronousRequest:request
                     queue:[NSOperationQueue mainQueue]
                     completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                         NSLog(@"%@ got %@", self.deviceNickname, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                         if (error) {
                             NSLog(@"%@ got error code %d", self.deviceNickname, [error code]);
                             switch ([error code]) {
                                 case NSURLErrorUserCancelledAuthentication:
                                 case NSURLErrorUserAuthenticationRequired:
                                     NSLog(@"Authentication error");
                                     [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_AUTH_FAILED object:self];
                                     lastResult = @"%Incorrect username or password.";
                                     break;
                                 default:
                                     lastResult = @"Unable to contact server.";
                                     [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_NETWORK_ERROR object:self];
                                     [self scheduleUpload];
                                     break;
                             }
                         } else {
                             int statusCode = [(NSHTTPURLResponse*) response statusCode];
                             NSLog(@"%@ success with HTTP status %d", self.deviceNickname, statusCode);
                             lastResult = @"";
                             [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_SUCCEEDED object:self];
                             if (uploadCount) {
                                 [self samples]->deleteUntilSequence(nextSequence);
                                 lastUploadTime = doubletime();
                             }
                         }
                     }];
}

- (double) timeSinceLastUpload
{
    if (lastUploadTime == 0) return -1;
    return doubletime() - lastUploadTime;
}

- (NSString*) getStatus
{
    double age = [self timeSinceLastUpload];
    NSString *status;
    if (age < 0) {
        status = [NSString stringWithFormat: @"%@\nNo data uploaded.", lastResult];
    } else {
        status = [NSString stringWithFormat: @"%@\nLast data uploaded %@ ago.", lastResult, printDuration(age)];
    }
    return status;
}

- (void) clearStatus
{
    lastResult = @"";
}

- (void) addChannel: (NSString*)name
{
    [self samples]->addChannel([name UTF8String]);
}

- (void) addStringChannel: (NSString*)name
{
    [self samples]->addStringChannel([name UTF8String]);
}

- (void) addSample:(double)time ch0:(double)ch0
{
    double values[] = {ch0};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1
{
    double values[] = {ch0, ch1};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2
{
    double values[] = {ch0, ch1, ch2};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3
{
    double values[] = {ch0, ch1, ch2, ch3};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4
{
    double values[] = {ch0, ch1, ch2, ch3, ch4};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5
{
    double values[] = {ch0, ch1, ch2, ch3, ch4, ch5};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6
{
    double values[] = {ch0, ch1, ch2, ch3, ch4, ch5, ch6};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7
{
    double values[] = {ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7 ch8:(double)ch8
{
    double values[] = {ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7 ch8:(double)ch8 ch9:(double)ch9
{
    double values[] = {ch0, ch1, ch2, ch3, ch4, ch5, ch6, ch7, ch8, ch9};
    [self addSample:time values:values count:sizeof(values)/sizeof(values[0])];
}

- (void) addSample:(double)time values:(double*)values count:(unsigned int)count
{
    [self addSample:time numericValues:values numericCount:count stringValues:nil];
}

- (void) addSample:(double)time numericValues:(double[]) numericValues numericCount:(unsigned int)numericCount stringValues:(NSArray *)stringValues
{
    size_t sequence;
    if (stringValues == nil) {
        sequence = [self samples]->addSample(time, numericValues, numericCount);
    } else {
        std::vector<std::string> stdStringValues([stringValues count]);
        for (unsigned i = 0; i < stdStringValues.size(); i++) {
            stdStringValues[i] = [stringValues[i] UTF8String];
        }
        sequence = [self samples]->addSample(time, numericValues, numericCount, &stdStringValues[0], stdStringValues.size());
    }
    if (self.logSamples) {
        NSLog(@"%s", [self samples]->getSampleJSON(sequence).c_str());
    }
    [self scheduleUpload];
}

- (void) scheduleUpload
{
    if (!OSAtomicTestAndSet(7, &uploadScheduled)) {
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            NSLog(@"%@ scheduling upload in %f seconds", self.deviceNickname, self.maximumAge);
            uploadTimer = [NSTimer scheduledTimerWithTimeInterval:self.maximumAge target:self selector:@selector(uploadNow) userInfo:nil repeats:NO];
        }];
    }
}

- (size_t) sampleCount
{
    return [self samples]->size();
}

+ (double)now
{
    return doubletime();
}

@end
