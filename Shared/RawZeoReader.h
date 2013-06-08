//
//  RawZeoReader.h
//  ZeoRelay
//
//  Created by rsargent on 10/20/12.
//  Copyright (c) 2012 rsargent. All rights reserved.
//

#ifndef __ZeoRelay__RawZeoReader__
#define __ZeoRelay__RawZeoReader__

#include <iostream>
#include <vector>
#include <string>

struct ZeoPacket {
    double time;
    int sequence;
    std::vector<unsigned char> data;
};

class RawZeoReader {
private:
    int serialFd;
public:
    RawZeoReader();
    bool open(const std::string &deviceFilename);
    bool testConnection();
    bool autoOpen();
    void close();
    bool readPacketWithTimeout(ZeoPacket &packet, double timeout);
    ~RawZeoReader();
private:
    static std::vector<std::string> allSerialPorts();
    bool waitForRead(double deadline);
    int read8(double deadline);
    int read16(double deadline);
    bool read(std::vector<unsigned char> data, double deadline);
};

#endif /* defined(__ZeoRelay__RawZeoReader__) */
