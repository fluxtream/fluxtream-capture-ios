//
//  ChannelNames.cpp
//  Stetho
//
//  Created by rsargent on 12/19/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#include "ChannelList.h"

// Not thread-safe;  caller must hold a lock on "mutex"

int ChannelList::createList(const char *lst) {
    int idx = lists.size();
    
    ids[lst] = idx;

    // Split on comma
    std::vector<std::string> channels;
    const char *comma;
    while ((comma = strchr(lst, ','))) {
        channels.push_back(std::string(lst, comma));
        lst = comma + 1;
    }
    channels.push_back(lst);
    lists.push_back(channels);
    return idx;
}

Mutex ChannelList::mutex;
std::map<std::string, int> ChannelList::ids;
std::vector<std::vector<std::string> > ChannelList::lists;

