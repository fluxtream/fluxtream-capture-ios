
#include "Utils.h"

#include <sys/time.h>
#include <string>
#include <vector>
#include <glob.h>

std::string string_vprintf(const char *fmt, va_list args)
{
    int size= 500;
    char *buf = (char*)malloc(size);
    while (1) {
        va_list copy;
        va_copy(copy, args);
#if defined(_WIN32)
        int nwritten= _vsnprintf(buf, size, fmt, copy);
#else
        int nwritten= vsnprintf(buf, size, fmt, copy);
#endif
        va_end(copy);
        // Some c libraries return -1 for overflow, some return
        // a number larger than size-1
        if (nwritten < 0) {
            size *= 2;
        } else if (nwritten >= size) {
            size = nwritten + 1;
        } else {
            if (nwritten && buf[nwritten-1] == 0) nwritten--;
            std::string ret(buf, buf+nwritten);
            free(buf);
            return ret;
        }
        buf = (char*)realloc(buf, size);
    }
}

std::string string_printf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    std::string ret= string_vprintf(fmt, args);
    va_end(args);
    return ret;
}

unsigned long long microtime()
{
#ifdef WIN32
    return ((long long)GetTickCount() * 1000);
#else
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return ((long long) tv.tv_sec * (long long) 1000000 +
            (long long) tv.tv_usec);
#endif
}

double doubletime()
{
    return microtime() / 1000000.0;
}

std::vector<std::string> glob(const std::string &pattern) {
    glob_t glob_result;
    glob(pattern.c_str(), GLOB_TILDE, NULL, &glob_result);
    std::vector<std::string> ret;
    for (unsigned i = 0; i < glob_result.gl_pathc; i++) {
        ret.push_back(glob_result.gl_pathv[i]);
    }
    globfree(&glob_result);
    return ret;
}


//kern_return_t host_processor_info
//(
// host_t host,
// processor_flavor_t flavor,
// natural_t *out_processor_count,
// processor_info_array_t *out_processor_info,
// mach_msg_type_number_t *out_processor_infoCnt
// );

#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

void get_systemwide_cpu_usage(double &user_cpu_seconds_ret, double &system_cpu_seconds_ret, int &cpu_count_ret)
{
    // This was determined empircally on an iPhone 5 running iOS 6.  Is there a better way to find this number?
    double secondsPerTick = 1.0 / 100.0;
    processor_info_array_t cpuInfo;
    mach_msg_type_number_t numCpuInfo;
    natural_t numCPUs = 0;
    user_cpu_seconds_ret = system_cpu_seconds_ret = cpu_count_ret = 0;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numCPUs, &cpuInfo, &numCpuInfo);
    if(err == KERN_SUCCESS) {
        cpu_count_ret = numCPUs;
        for(unsigned i = 0U; i < numCPUs; ++i) {
            natural_t *cpu = (natural_t*) &cpuInfo[CPU_STATE_MAX * i];
            // Warning: these counters wrap in ~1.27 years
            user_cpu_seconds_ret += (cpu[CPU_STATE_USER] + cpu[CPU_STATE_NICE]) * secondsPerTick;
            system_cpu_seconds_ret += cpu[CPU_STATE_MAX] * secondsPerTick;
        }
        
        size_t cpuInfoSize = sizeof(integer_t) * numCpuInfo;
        vm_deallocate(mach_task_self(), (vm_address_t)cpuInfo, cpuInfoSize);
    }
}
