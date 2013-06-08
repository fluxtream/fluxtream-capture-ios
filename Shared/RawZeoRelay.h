//
//  RawZeoRelay.h
//  ZeoRelay
//
//  Created by rsargent on 10/23/12.
//  Copyright (c) 2012 rsargent. All rights reserved.
//

#ifndef __ZeoRelay__RawZeoRelay__
#define __ZeoRelay__RawZeoRelay__

#include <iostream>
#include "RawZeoReader.h"
#include "FluxtreamUploader.h"

class RawZeoRelay {
public:
    RawZeoReader reader;
    FluxtreamUploader uploader;

    RawZeoRelay();
    
    // Relay until Zeo stops sending
    // Assumes reader is already connected
    void relay() {
        double timeout = 5.0; // seconds
        ZeoPacket packet;
        fprintf(stderr, "starting relay\n");
        while (reader.readPacketWithTimeout(packet, timeout)) {
            fprintf(stderr, "got a packet, yo!\n");
        }
        fprintf(stderr, "relay timed out\n");
    }
    
    
    void autoRelay() {
        while (1) {
            reader.autoOpen();
            relay();
        }
    }
}

#endif /* defined(__ZeoRelay__RawZeoRelay__) */
