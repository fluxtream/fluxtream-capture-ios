//
//  Samples.h
//  HeartRateMonitor
//
//

#ifndef __HeartRateMonitor__Samples__
#define __HeartRateMonitor__Samples__

#include <assert.h>

#include <string>
#include <vector>
#include <deque>

#include "Mutex.h"

class Samples {
private:
    std::deque<double> sampleTimes;
    std::deque<double> numericValues;
    std::deque<std::string> stringValues;
    std::vector<std::string> numericChannelNames;
    std::vector<std::string> stringChannelNames;
    // Sequence number of first sample contained in values.
    // Starts as zero and increases as deleteUntilSequence is called
    size_t firstSequence;
    mutable Mutex lock;
    
public:
    Samples();
    // Add channel with given name
    // All channels must be added before first sample is added
    void addChannel(const std::string &name);
    void addStringChannel(const std::string &name);
    
    // Append new sample.  Returns sequence # for the sample
    size_t addSample(double time, const double *numericValues, unsigned int numericCount,
                   const std::string *stringValues = NULL, unsigned int stringCount = 0);
    
    size_t size() const;
    size_t columnCount() const;
    
    // Delete samples such that first sample contained in values is sequence
    // If sequence is beyond end of values, delete all samples and make the
    // next sequence captured be one plus the last sample deleted
    void deleteUntilSequence(size_t sequence);

    // Emit JSON for up to sampleCount samples.  Use (size_t)-1 to capture all samples.
    // Returns sequence of the first sample beyond that returned by getJSON, for
    // future call to deleteUntilSequence
    std::string getJSON(size_t sampleCount, size_t &returnNextSequence) const;
    
    // Emit JSON for single sample
    std::string getSampleJSON(size_t sequence) const;
};

#endif /* defined(__HeartRateMonitor__Samples__) */
