//
//  FluxtreamUploaderObjc.h
//  HeartRateMonitor
//
//  Created by bodytrack on 10/13/12.
//

#import <Foundation/Foundation.h>

#define BT_NOTIFICATION_UPLOAD_AUTH_FAILED @"bt_upload_auth_failed"
#define BT_NOTIFICATION_UPLOAD_NETWORK_ERROR @"bt_upload_network_error"
#define BT_NOTIFICATION_UPLOAD_SUCCEEDED @"bt_upload_succeeded"

@interface FluxtreamUploaderObjc : NSObject
{
    void *samplesPtr;
    NSTimer *uploadTimer;
    double lastUploadTime;
    NSString *lastResult;
    unsigned char uploadScheduled;
}

- (void) addChannel:(NSString*)name; // adds numeric channel
- (void) addStringChannel:(NSString*)name;

- (void) addSample:(double)time ch0:(double)ch0;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7 ch8:(double)ch8;
- (void) addSample:(double)time ch0:(double)ch0 ch1:(double)ch1 ch2:(double)ch2 ch3:(double)ch3 ch4:(double)ch4 ch5:(double)ch5 ch6:(double)ch6 ch7:(double)ch7 ch8:(double)ch8 ch9:(double)ch9;

- (void) addSample:(double)time values:(double[])values count:(unsigned int)count;
- (void) addSample:(double)time numericValues:(double[])numericValues numericCount:(unsigned int)numericCount stringValues:(NSArray *)stringValues;


- (void) uploadNow;
- (size_t) sampleCount;
// Returns -1 if never uploaded
- (double) timeSinceLastUpload;
- (NSString*) getStatus;
+ (double) now;

@property (strong) NSString *deviceNickname;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (strong) NSString *serverPrefix;
@property double maximumAge;
@property size_t maximumUploadSampleCount;
@property BOOL logSamples;

@end
