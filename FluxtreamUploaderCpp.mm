//
//  FluxtreamUploaderCpp.mm
//
//  Created by rsargent on 10/23/12.
//  Copyright (c) 2012 rsargent. All rights reserved.
//

#include "FluxtreamUploaderCpp.h"

#import "FluxtreamUploaderObjc.h"

FluxtreamUploaderCpp::FluxtreamUploaderCpp() {
    fluxtreamUploaderObjc = (void*) CFBridgingRetain([[FluxtreamUploaderObjc alloc] init]);
}

FluxtreamUploaderCpp::~FluxtreamUploaderCpp() {
    CFBridgingRelease(fluxtreamUploaderObjc);
    fluxtreamUploaderObjc = NULL;
}

#define getUploader() ((__bridge FluxtreamUploaderObjc*) fluxtreamUploaderObjc)

std::string FluxtreamUploaderCpp::getUsername() {
    return std::string([getUploader().username cStringUsingEncoding:NSUTF8StringEncoding]);
}

void FluxtreamUploaderCpp::setUsername(const std::string &username) {
    getUploader().username = [NSString stringWithUTF8String:username.c_str()];
}

void FluxtreamUploaderCpp::setPassword(const std::string &password) {
    getUploader().password = [NSString stringWithUTF8String:password.c_str()];
}

void FluxtreamUploaderCpp::addChannel(const std::string &channelName) {
    [getUploader() addChannel: [NSString stringWithUTF8String: channelName.c_str()]];
}

void FluxtreamUploaderCpp::addSample(double time, double ch0) {
    [getUploader() addSample:time ch0:ch0];
}

void FluxtreamUploaderCpp::addSample(double time, double ch0, double ch1) {
    [getUploader() addSample:time ch0:ch0 ch1:ch1];
}

void FluxtreamUploaderCpp::addSample(double time, double ch0, double ch1, double ch2) {
    [getUploader() addSample:time ch0:ch0 ch1:ch1 ch2:ch2];
}

void FluxtreamUploaderCpp::addSample(double time, double ch0, double ch1, double ch2, double ch3) {
    [getUploader() addSample:time ch0:ch0 ch1:ch1 ch2:ch2 ch3:ch3];
}

void FluxtreamUploaderCpp::addSample(double time, double ch0, double ch1, double ch2, double ch3, double ch4) {
    [getUploader() addSample:time ch0:ch0 ch1:ch1 ch2:ch2 ch3:ch3 ch4:ch4];
}

// Samples are queued when added, then uploaded in batches to minimize communication overhead
// and save battery life.  The batching behavior can be controlled by setting the
// "maximum upload age" and "maximum upload sample count", below
//
// Maximum upload age is the maximum age a sample can be, in seconds, before
// upload is automatically triggered.  Default is 30 seconds.  0 means send everything immediately.
void setMaximumUploadAge(double maxAge);
double getMaximumUploadAge();

// Maximum upload sample count is the maximum number of samples that can be uploaded in a single batch.
// (If the queue becomes larger than this count, its contents will be uploaded in multiple batches)
void setMaximumUploadSampleCount(int maximumUploadSampleCount);
int getMaximumUploadSampleCount();
