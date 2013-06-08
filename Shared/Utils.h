//
//  Utils.h
//  HeartRateMonitor
//

#ifndef HeartRateMonitor_Utils_h
#define HeartRateMonitor_Utils_h

#include <string>
#include <vector>
#include <stdlib.h>
std::string string_vprintf(const char *fmt, va_list args);

std::string string_printf(const char *fmt, ...);

unsigned long long microtime();
double doubletime();

std::vector<std::string> glob(const std::string &pattern);

void get_systemwide_cpu_usage(double &user_cpu_seconds_ret, double &system_cpu_seconds_ret, int &cpu_count_ret);

#endif
