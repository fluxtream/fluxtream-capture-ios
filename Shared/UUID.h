//
//  UUID.h
//  Stetho
//
//  Created by rsargent on 10/27/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#ifndef __Stetho__UUID__
#define __Stetho__UUID__

#include <iostream>

class UUID {
private:
    std::string uuid;
public:
    UUID();
    UUID(void *data, size_t len);
    static UUID fromHex(const std::string &hex);
    std::string toHex() const;
    std::string nickname() const;
    bool operator==(const UUID &rhs) const;
    bool operator!=(const UUID &rhs) const;
};

#endif /* defined(__Stetho__UUID__) */
