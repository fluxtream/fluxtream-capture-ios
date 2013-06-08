//
//  UUID.cpp
//  Stetho
//
//  Created by rsargent on 10/27/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

// System
#include <assert.h>

// Project
#include "Nickname.h"

// Self
#include "UUID.h"

UUID::UUID() {}

UUID::UUID(void *data, size_t len) : uuid((const char*)data, len) {}

UUID UUID::fromHex(const std::string &hex) {
    // TODO(rsargent): implement me
    assert(false);
}

std::string UUID::toHex() const {
    // TODO(rsargent): implement me
    assert(false);
}

std::string UUID::nickname() const {
    return computeNickname(uuid);
}

bool UUID::operator==(const UUID &rhs) const {
    return uuid == rhs.uuid;
}

bool UUID::operator!=(const UUID &rhs) const {
    return uuid != rhs.uuid;
}

