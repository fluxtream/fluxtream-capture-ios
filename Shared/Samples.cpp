//
//  Samples.cpp
//  HeartRateMonitor
//
//  Created by bodytrack on 10/13/12.
//

#include <algorithm>

#include "Utils.h"
#include "Samples.h"

Samples::Samples() : firstSequence(0) {}

void Samples::addChannel(const std::string &name) {
    ScopedLock l(lock);
    assert(numericValues.empty());
    assert(stringValues.empty());
    numericChannelNames.push_back(name);
}

void Samples::addStringChannel(const std::string &name) {
    ScopedLock l(lock);
    assert(numericValues.empty());
    assert(stringValues.empty());
    stringChannelNames.push_back(name);
}

// Returns sequence # of sample added
size_t Samples::addSample(double time, const double *numericVals, unsigned int numericCount,
                        const std::string *stringVals, unsigned int stringCount) {
    ScopedLock l(lock);
    assert(numericChannelNames.size() == numericCount);
    assert(stringChannelNames.size() == stringCount);
    size_t sequence = firstSequence + sampleTimes.size();
    sampleTimes.push_back(time);
    numericValues.insert(numericValues.end(), numericVals, numericVals + numericCount);
    stringValues.insert(stringValues.end(), stringVals, stringVals + stringCount);
    return sequence;
}

size_t Samples::size() const {
    return sampleTimes.size();
}

void Samples::deleteUntilSequence(size_t sequence) {
    ScopedLock l(lock);
    if (sequence > firstSequence) {
        size_t samplesToDelete = std::min(sequence - firstSequence, size());
        sampleTimes.erase(sampleTimes.begin(), sampleTimes.begin() + samplesToDelete);
        numericValues.erase(numericValues.begin(), numericValues.begin() + samplesToDelete * numericChannelNames.size());
        stringValues.erase(stringValues.begin(), stringValues.begin() + samplesToDelete * stringChannelNames.size());
        firstSequence += samplesToDelete;
    }
}

std::string Samples::getJSON(size_t sampleCount,
                             size_t &returnNextSequence) const {
    ScopedLock l(lock);
    sampleCount = std::min(sampleCount, size());
    returnNextSequence = firstSequence + sampleCount;
    std::string ret = "{";
    ret += "\"channel_names\": [";
    int col = 0;
    for (unsigned i = 0; i < numericChannelNames.size(); i++) {
        if (col++) ret += ",";
        ret += string_printf("\"%s\"", numericChannelNames[i].c_str());
    }
    for (unsigned i = 0; i < stringChannelNames.size(); i++) {
        if (col++) ret += ",";
        ret += string_printf("\"%s\"", stringChannelNames[i].c_str());
    }
    ret += "]";
    ret += ",";
    ret += "\"data\":[";
    for (unsigned row = 0; row < sampleCount; row++) {
        
        if (row) ret += ",";
        ret += string_printf("[%.3f", sampleTimes[row]);
        for (unsigned i = 0; i < numericChannelNames.size(); i++) {
            // TODO(rsargent): don't hardcode the precision here
            ret += string_printf(",%.3f", numericValues[row * numericChannelNames.size() + i]);
        }
        for (unsigned i = 0; i < stringChannelNames.size(); i++) {
            // TODO(rsargent): quote string JSON-style
            ret += ",\"" + stringValues[row * stringChannelNames.size() + i] + "\"";
        }
        ret += "]";
    }
    ret += "]";
    ret += "}";
    return ret;
}

std::string Samples::getSampleJSON(size_t sequence) const {
    ScopedLock l(lock);
    int index = sequence - firstSequence;
    std::string ret = "{";
    int col = 0;
    // TODO(rsargent): quote field name?
    for (unsigned i = 0; i < numericChannelNames.size(); i++) {
        if (col++) ret += ",";
        ret += string_printf("%s:%g", numericChannelNames[i].c_str(), numericValues[index * numericChannelNames.size() + i]);
    }
    for (unsigned i = 0; i < stringChannelNames.size(); i++) {
        if (col++) ret += ",";
        // TODO(rsargent): quote string JSON-style
        ret += string_printf("%s:\"%s\"", stringChannelNames[i].c_str(), stringValues[index * stringChannelNames.size() + i].c_str());
    }
    ret += "}";
    return ret;
}
