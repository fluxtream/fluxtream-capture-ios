//
//  FluxtreamUploader.cpp
//  Stetho
//
//  Created by rsargent on 12/19/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#include <assert.h>

#import <Foundation/Foundation.h>

#include "Mutex.h"
#include "Samples.h"
#include "Utils.h"

#include "FluxtreamUploader.h"

const char *FluxtreamUploader::DEFAULT_SERVER_BASE_URL = "http://flxtest.bodytrack.org";

FluxtreamUploader::FluxtreamUploader() :
serverBaseURL(DEFAULT_SERVER_BASE_URL),
maximumAge(DEFAULT_MAXIMUM_AGE),
maximumUploadSampleCount(DEFAULT_MAXIMUM_UPLOAD_SAMPLE_COUNT),
uploadScheduled(false) {
}

void FluxtreamUploader::setUsername(const char *newUsername) {
    ScopedLock l(mutex);
    username = newUsername;
}

std::string FluxtreamUploader::getUsername() {
    return username;
}

void FluxtreamUploader::setPassword(const char *newPassword) {
    ScopedLock l(mutex);
    password = newPassword;
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0) {
    double values[] = {v0};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1) {
    scheduleUpload();
    double values[] = {v0, v1};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2) {
    double values[] = {v0, v1, v2};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3) {
    double values[] = {v0, v1, v2, v3};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4) {
    double values[] = {v0, v1, v2, v3, v4};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5) {
    double values[] = {v0, v1, v2, v3, v4, v5};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6) {
    double values[] = {v0, v1, v2, v3, v4, v5, v6};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7) {
    double values[] = {v0, v1, v2, v3, v4, v5, v6, v7};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7, double v8) {
    double values[] = {v0, v1, v2, v3, v4, v5, v6, v7, v8};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7, double v8, double v9) {
    double values[] = {v0, v1, v2, v3, v4, v5, v6, v7, v8, v9};
    addSample(channels, time, values, sizeof(values)/sizeof(values[0]));
}

void FluxtreamUploader::addSample(ChannelList channels, double time, double *channelValues, unsigned int channelCount) {
    {
        ScopedLock l(mutex);
        getSamples(channels)->addSample(time, channelValues, channelCount);
    }
    scheduleUpload();
}

void FluxtreamUploader::setServerBaseURL(const char *newServerBaseURL) {
    serverBaseURL = newServerBaseURL;
}

std::string FluxtreamUploader::getServerBaseURL() {
    return serverBaseURL;
}

void FluxtreamUploader::setMaximumAge(double seconds) {
    maximumAge = seconds;
}

double FluxtreamUploader::getMaximumAge() {
    return maximumAge;
}

void FluxtreamUploader::setMaximumUploadSampleCount(unsigned int sampleCount) {
    maximumUploadSampleCount = sampleCount;
}

unsigned int FluxtreamUploader::getMaximumUploadSampleCount() {
    return maximumUploadSampleCount;
}

double FluxtreamUploader::now() {
    return doubletime();
}

/////////////// Private

// Not thread-safe;  caller must hold lock on "mutex"
Samples *FluxtreamUploader::getSamples(ChannelList channels) {
    int idx = channels.getIndex();
    if (idx >= samples.size()) {
        samples.resize(idx + 1);
    }
    if (samples[idx] == NULL) {
        samples[idx] = new Samples();
        for (unsigned i = 0; i < channels.size(); i++) {
            samples[idx]->addChannel(channels.get(i));
        }
    }
    return samples[idx];
}

void FluxtreamUploader::uploadNow() {
    {
        ScopedLock l(&uploadScheduleMutex);
        uploadScheduled = false;
    }
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSString *deviceNickname = @"PolarStrap";
    NSString *urlString = [NSString
                           stringWithFormat:@"%@/api/bodytrack/jupload?dev_nickname=%@",
                           self.serverPrefix, deviceNickname];
    NSURL *url = [NSURL URLWithString:urlString];
    [request setURL:url];
        
        size_t uploadCount = std::min(samples.size(), _maximumUploadSampleCount);
        size_t nextSequence; // set by getJSON
        std::string json = samples.getJSON(uploadCount, nextSequence);
        
        NSData *body = [NSData dataWithBytes: json.c_str() length: json.length()];
        NSString *bodyLength = [NSString stringWithFormat:@"%ld", (long)[body length]];
        [request setValue:bodyLength forHTTPHeaderField:@"Content-Length"];
        
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", self.username, self.password];
        
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64encode(authData)];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        [request setHTTPBody:body];
        
        NSLog(@"about to post %ld samples", uploadCount);
        
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
         NSLog(@"got %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
         long errorCode = [error code];
         long statusCode = [(NSHTTPURLResponse*) response statusCode];
         NSLog(@"error code %ld", errorCode);
         NSLog(@"status code %ld", statusCode);
         NSString *text = [[NSString alloc] initWithData: data encoding:NSUTF8StringEncoding];
         if (errorCode == 0) {
         lastResult = @"";
         [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_SUCCEEDED object:self];
         if (uploadCount) {
         samples.deleteUntilSequence(nextSequence);
         lastUploadTime = doubletime();
         }
         } else if ([text rangeOfString:@"Bad credentials"].location != NSNotFound) {
         [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_AUTH_FAILED object:self];
         lastResult = @"Incorrect username or password.";
         } else {
         [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_UPLOAD_NETWORK_ERROR object:self];
         lastResult = @"Unable to contact server.";
         [self scheduleUpload];
         }
         }];
    }

    
    
}

void FluxtreamUploader::scheduleUpload() {
    ScopedLock l(uploadScheduleMutex);
    if (uploadScheduled) return;
    uploadScheduled = true;
    [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
     [NSTimer scheduledTimerWithTimeInterval:maximumAge
              target:[NSBlockOperation blockOperationWithBlock:^{
                      uploadNow();
                      }]
                                    selector:@selector(main) userInfo:nil repeats:NO
      ];
     }];
}

/*
 Start timer in main thread: use addOperationWithBlock

 Timer fires in main thread: use
 
 NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.7
 target:[NSBlockOperation blockOperationWithBlock:^{  }]
selector:@selector(main)
userInfo:nil
repeats:NO
];


 */
 
 
 




