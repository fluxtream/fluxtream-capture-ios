//
//  NSUtils.h
//  HeartRateMonitor
//
//  Created by bodytrack on 10/15/12.
//

#ifndef HeartRateMonitor_NSUtils_h
#define HeartRateMonitor_NSUtils_h

#include <string>

NSString *base64encode(NSData *data);
NSString *printDuration(double duration);
NSString *utf8(NSData *data);
NSString *utf8(const std::string &str);
#endif
