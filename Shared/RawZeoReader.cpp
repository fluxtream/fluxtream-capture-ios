//
//  RawZeoReader.cpp
//  ZeoRelay
//
//  Created by rsargent on 10/20/12.
//  Copyright (c) 2012 rsargent. All rights reserved.
//

#include "RawZeoReader.h"
#include "Utils.h"
#include <termios.h>
#include <unistd.h>
#include <fcntl.h>

RawZeoReader::RawZeoReader() : serialFd(-1) {
}

bool RawZeoReader::open(const std::string &deviceFilename) {
    close();
    serialFd = ::open(deviceFilename.c_str(), O_RDWR | O_NONBLOCK | O_NOCTTY);
    if (serialFd == -1) return false;

    struct termios options;
    memset(&options, 0, sizeof(options));
    tcgetattr(serialFd, &options);
    cfsetispeed(&options, B38400);
    cfsetospeed(&options, B38400);
    options.c_iflag = 0;
    options.c_oflag = 0;
    options.c_cflag = CS8 | CREAD | CLOCAL;
    options.c_cc[VMIN] = 0;     // No min chars to read
    options.c_cc[VTIME] = 0;    // Don't wait
    tcsetattr(serialFd, TCSANOW, &options);
    
    return true;
}

bool RawZeoReader::testConnection() {
    ZeoPacket packet;
    double timeout = 5.0; // seconds
    // The Zeo is continually spitting out packets;  consider a connection good
    // if the zeo sends a packet in the next 5 seconds
    return readPacketWithTimeout(packet, timeout);
}

bool RawZeoReader::autoOpen() {
    std::vector<std::string> serialPorts = allSerialPorts();
    for (unsigned i = 0; i < serialPorts.size(); i++) {
        if (open(serialPorts[i]) && testConnection()) {
            return true;
        }
        close();
    }
    return false;
}

void RawZeoReader::close() {
    if (serialFd != -1) {
        ::close(serialFd);
        serialFd = -1;
    }
}

bool RawZeoReader::readPacketWithTimeout(ZeoPacket &packet, double timeout) {
    double deadline = timeout + doubletime();

    while (doubletime() < deadline) {
        if (read8(deadline) != 'A') continue;
        if (read8(deadline) != '4') continue;
        int checksum = read8(deadline);
        int length = read16(deadline);
        if (read16(deadline) != (0xffff ^ length)) continue;
        if (length == 0) {
            fprintf(stderr, "readPacketWithTimeout: length=0, rejecting");
            continue;
        }
        
        int timeSecs = read8(deadline);
        int timeFrac = read16(deadline);
        packet.time = timeSecs + timeFrac / 65536.0;
        
        packet.sequence = read8(deadline);
        packet.data.resize(length);

        read(packet.data, deadline);
        unsigned char computedChecksum = 0;
        for (unsigned i = 0; i < packet.data.size(); i++) {
            computedChecksum += packet.data[i];
        }
        if (checksum != computedChecksum) {
            fprintf(stderr, "Checksum error: 0x%x != 0x%x", checksum, computedChecksum);
            continue;
        }
        if (doubletime() >= deadline) break;
        fprintf(stderr, "readPacketWithTimeout(%g) returns type 0x%02x, data length %ld",
                timeout, packet.data[1], (long) packet.data.size());
        return true;
    }
    fprintf(stderr, "readPacketWithTimeout(%g): timeout", timeout);
    return false;
}


RawZeoReader::~RawZeoReader() {
    close();
}

std::vector<std::string> RawZeoReader::allSerialPorts() {
    return glob("/dev/tty.*");
}

int RawZeoReader::read8(double deadline) {
    unsigned char c;
    if (!waitForRead(deadline)) return -1;
    if (1 != ::read(serialFd, &c, 1)) return -1;
    return c;
}

int RawZeoReader::read16(double deadline) {
    int low = read8(deadline);
    int high = read8(deadline);
    if (low == -1 || high == -1) return -1;
    return (high << 8) | low;
}

bool RawZeoReader::read(std::vector<unsigned char> data, double deadline) {
    size_t nread = 0;
    while (nread < data.size()) {
        if (!waitForRead(deadline)) return false;
        long ret = ::read(serialFd, &data[nread], data.size() - nread);
        if (ret < 0) return false;
        nread += ret;
    }
    return true;
}