//
//  FluxtreamUploaderCpp.h
//  ZeoRelay
//
//  Created by rsargent on 10/23/12.
//  Copyright (c) 2012 rsargent. All rights reserved.
//

#ifndef __ZeoRelay__FluxtreamUploaderCpp__
#define __ZeoRelay__FluxtreamUploaderCpp__

#include <iostream>

class FluxtreamUploaderCpp {
protected:
    void *fluxtreamUploaderObjc;

public:
    FluxtreamUploaderCpp();
    ~FluxtreamUploaderCpp();
    
    std::string getUsername();
    void setUsername(const std::string &username);
    
    void setPassword(const std::string &password);
    
    void addChannel(const std::string &channelName);
    void addSample(double time, double channel0);
    void addSample(double time, double channel0, double channel1);
    void addSample(double time, double channel0, double channel1, double channel2);
    void addSample(double time, double channel0, double channel1, double channel2, double channel3);
    void addSample(double time, double channel0, double channel1, double channel2, double channel3,
                   double channel4);
    void addSampleFromArray(double time, double *channels, int channelCount);
    
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
};


#endif /* defined(__ZeoRelay__FluxtreamUploaderCpp__) */
