//
//  Nickname.h
//  Stetho
//
//  Created by rsargent on 10/25/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#ifndef Stetho_Nickname_h
#define Stetho_Nickname_h

#include <stdlib.h>
#include <string>

std::string computeNickname(const void *data, size_t len);
std::string computeNickname(std::string data);

#endif
