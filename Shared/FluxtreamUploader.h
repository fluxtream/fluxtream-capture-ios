//
//  FluxtreamUploader.h
//  Stetho
//
//  Created by rsargent on 12/19/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#ifndef __Stetho__FluxtreamUploader__
#define __Stetho__FluxtreamUploader__

#include <vector>

#include "ChannelList.h"
#include "Mutex.h"
#include "Samples.h"

class FluxtreamUploader {
public:
    
    FluxtreamUploader();
    
    void setUsername(const char *username);
    void setPassword(const char *password);
    std::string getUsername();
    
    void addSample(ChannelList channels, double time, double v0);
    void addSample(ChannelList channels, double time, double v0, double v1);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7, double v8);
    void addSample(ChannelList channels, double time, double v0, double v1, double v2, double v3, double v4, double v5, double v6, double v7, double v8, double v9);
    void addSample(ChannelList channels, double time, double *channelValues, unsigned int channelCount);
    
    
    void setServerBaseURL(const char *serverBaseURL);
    std::string getServerBaseURL();
    
    void setMaximumAge(double seconds);
    double getMaximumAge();
    
    void setMaximumUploadSampleCount(unsigned int sampleCount);
    unsigned int getMaximumUploadSampleCount();
    
    static double now();
    
    enum {
        DEFAULT_MAXIMUM_AGE = 10,
        DEFAULT_MAXIMUM_UPLOAD_SAMPLE_COUNT = 1000
    };
    static const char *DEFAULT_SERVER_BASE_URL;
    
private:
    Mutex mutex;
    std::vector<Samples*> samples;
    std::string username;
    std::string password;
    std::string serverBaseURL; // e.g. http://flxtest.bodytrack.org
    double maximumAge; // in seconds
    unsigned int maximumUploadSampleCount;
    
    Samples *getSamples(ChannelList channels);
    
    Mutex uploadScheduleMutex;
    bool uploadScheduled;
    void scheduleUpload();
    void uploadNow();
};



#endif /* defined(__Stetho__FluxtreamUploader__) */
