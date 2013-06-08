#include "NSUtils.h"

NSString *base64encode(NSData *data) {
    const char *base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    const unsigned char *src = (const unsigned char*) [data bytes];
    
    NSMutableData *target =
    [NSMutableData dataWithCapacity: ([data length] + 2) / 3 * 4];
    
    for (long srclength = [data length]; srclength > 0; srclength -= 3) {
        unsigned int in = *src++ << 16;
        if (srclength > 1) in += *src++ << 8;
        if (srclength > 2) in += *src++;
        
        [target appendBytes:&base64[0x3f & (in >> 18)] length:1];
        [target appendBytes:&base64[0x3f & (in >> 12)] length:1];
        [target appendBytes:srclength > 1 ? &base64[0x3f & (in >> 6)] : "=" length:1];
        [target appendBytes:srclength > 2 ? &base64[0x3f & (in >> 0)] : "=" length:1];
    }
    
    return [[NSString alloc] initWithData:target encoding:NSASCIIStringEncoding];
}

NSString *printDuration(double duration) {
    if (duration > 7200) {
        return [NSString stringWithFormat: @"%.1f hours", duration / 3600];
    } else if (duration > 120) {
        return [NSString stringWithFormat: @"%.1f minutes", duration / 60];
    } else {
        return [NSString stringWithFormat: @"%.0f seconds", duration];
    }
}

NSString *utf8(NSData *data) {
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

NSString *utf8(const std::string &str) {
    return [NSString stringWithUTF8String:str.c_str()];
}
