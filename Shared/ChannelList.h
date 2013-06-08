//
//  ChannelNames.h
//  Stetho
//
//  Created by rsargent on 12/19/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#ifndef __Stetho__ChannelNames__
#define __Stetho__ChannelNames__

#include <map>
#include <string>
#include <vector>

#include "Mutex.h"

class ChannelList {
public:
    ChannelList(const char *lst) {
        ScopedLock lock(mutex);
        std::map<std::string, int>::const_iterator i = ids.find(lst);
        index = (i == ids.end()) ? createList(lst) : i->second;
    }
    unsigned int getIndex() const {
        return index;
    }
    unsigned int size() const {
        return lists[index].size();
    }
    std::string get(unsigned int i) const {
        return lists[index][i];
    }
    
private:
    unsigned int index;
    
// Static
    static Mutex mutex;
    static std::map<std::string, int> ids;
    static std::vector<std::vector<std::string> > lists;
    static int createList(const char *lst);
};

#endif /* defined(__Stetho__ChannelNames__) */
