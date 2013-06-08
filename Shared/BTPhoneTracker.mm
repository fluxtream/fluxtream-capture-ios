//
//  BTPhoneTracker.m
//  Stetho
//
//  Created by rsargent on 12/22/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import "BTPhoneTracker.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>

#include <sys/sysctl.h>
#include <mach/mach.h>
#include <mach/mach_host.h>

#include "Utils.h"
#import "Constants.h"

class Rate {
private:
    double lastValue;
    double lastTime;
public:
    Rate() {
        lastTime = lastValue = 0.0;
    }
    double update(double time, double value) {
        double elapsed = time - lastTime;
        double rate;
        if (elapsed <= 0.0 || lastTime == 0.0) {
            rate = 0.0;
        } else {
            rate = (value - lastValue) / elapsed;
        }
        lastTime = time;
        lastValue = value;
        return rate;
    }
};

@interface BTPhoneTracker()
{
    double motionTimeOffsetSum;
    double motionTimeOffsetWeight;
    double motionTimeOffsetFilter;
    double motionInitialTimeOffset;
    bool   inBackground;

    Rate systemwideTotalCpu;
    Rate systemwideUserCpu;
    Rate appTotalCpu;
    Rate appUserCpu;
    
    UIBackgroundTaskIdentifier backgroundTask;
    bool   capturingLocation;
}

@property (strong) NSTimer *batteryCaptureTimer;
@property (strong) NSTimer *timeZoneCaptureTimer;
@property (strong) NSTimer *appStatsCaptureTimer;
@property (strong) NSTimer *locationCaptureTimer;

@property (strong) CMMotionManager *motionManager;
@property (strong) NSOperationQueue *motionQueue;

@property (strong) CLLocationManager *locationManager;

- (void)initBatteryCapture;
- (void)initTimeZoneCapture;
- (void)initAppStatsCapture;
- (void)initLocationCapture;
- (void)initMotionCapture;

- (void)applicationDidBecomeActive;
- (void)applicationWillResignActive;
- (void)applicationDidEnterBackground;
- (void)applicationWillEnterForeground;
- (void)applicationWillTerminate;
- (void)applicationDidReceiveMemoryWarning;

- (void)beginBackgroundTask;
- (void)endBackgroundTask;

@end

@implementation BTPhoneTracker

- (id)init {
    if (self = [super init]) {
        capturingLocation = false;
        inBackground = false;
        backgroundTask = UIBackgroundTaskInvalid;

        [self initBatteryCapture];
        [self initTimeZoneCapture];
        [self initAppStatsCapture];
        
        [self initLocationCapture];
        [self initMotionCapture];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];

        [defaultCenter addObserver:self selector:@selector(applicationDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        
    }
    return self;
}

static UIApplication *app() {
    return [UIApplication sharedApplication];
}

- (void)applicationDidBecomeActive {
    NSLog(@"applicationDidBecomeActive");
    inBackground = false;
}

- (void)applicationWillResignActive {
    NSLog(@"applicationWillResignActive");
}

- (void)beginBackgroundTask {
    if (backgroundTask == UIBackgroundTaskInvalid) {
        NSLog(@"Starting background task");
        backgroundTask = [app() beginBackgroundTaskWithExpirationHandler:^{[self backgroundTaskDidExpire];}];
        NSLog(@"Started background task, id=%ld.  Time remaining=%g", (long)backgroundTask, [app() backgroundTimeRemaining]);
    }
}

- (void)endBackgroundTask {
    if (backgroundTask != UIBackgroundTaskInvalid) {
        NSLog(@"Ending background task.  Time remaining=%g", [app() backgroundTimeRemaining]);
        [app() endBackgroundTask:backgroundTask];
        NSLog(@"Ended background task.  Time remaining=%g", [app() backgroundTimeRemaining]);
        backgroundTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationDidEnterBackground {
    NSLog(@"applicationDidEnterBackground.  Time remaining=%g", [app() backgroundTimeRemaining]);
    [self beginBackgroundTask];
    inBackground = true;
}

- (void)backgroundTaskDidExpire {
    NSLog(@"backgroundTaskDidExpire");
    [self endBackgroundTask];
}

- (void)applicationWillEnterForeground {
    NSLog(@"applicationWillEnterForeground");
    [self endBackgroundTask];
}

- (void)applicationWillTerminate {
    NSLog(@"applicationWillTerminate");
}

- (void)applicationDidReceiveMemoryWarning {
    NSLog(@"applicationDidReceiveMemoryWarning");
}


// Motion

    
    
// Battery and charging state

- (void)initBatteryCapture {
    self.batteryUploader = [[FluxtreamUploaderObjc alloc] init];
    self.batteryUploader.deviceNickname = @"FluxtreamCapture";
    [self.batteryUploader addChannel:@"MobileBatteryLevel"];
    [self.batteryUploader addChannel:@"MobileBatteryCharging"];
    self.batteryUploader.logSamples = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.batteryUploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    self.batteryUploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    
    self.batteryUploader.maximumAge = 15*60; // seconds
    self.batteryCaptureTimer = NULL;
    self.recordBatteryEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
}

- (void)setRecordBatteryEnabled:(BOOL)recordBatteryEnabled {
    _recordBatteryEnabled = recordBatteryEnabled;
    if (self.recordBatteryEnabled && !self.batteryCaptureTimer) {
        double updateInterval = 60; // seconds
        self.batteryCaptureTimer =
        [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(captureBattery) userInfo:nil repeats:YES];
    } else if (!self.recordBatteryEnabled && self.batteryCaptureTimer) {
        [self.batteryCaptureTimer invalidate];
        self.batteryCaptureTimer = NULL;
    }
}

- (void)captureBattery {
    double now = [FluxtreamUploaderObjc now];
    double batteryLevel = [UIDevice currentDevice].batteryLevel;
    double batteryCharging = 0;                                        // 0=not plugged in, or unknown
    switch ([UIDevice currentDevice].batteryState) {
        case UIDeviceBatteryStateCharging: batteryCharging = 1; break; // 1=plugged in and charging
        case UIDeviceBatteryStateFull: batteryCharging = 2; break;     // 2=plugged in but full
        case UIDeviceBatteryStateUnknown: batteryCharging = 3; break;
        case UIDeviceBatteryStateUnplugged: batteryCharging = 4; break;
    }
    [self.batteryUploader addSample:now ch0:batteryLevel ch1:batteryCharging];
}

// Current time zone name, abbreviation, and offset

- (void)initTimeZoneCapture {
    self.timeZoneUploader = [[FluxtreamUploaderObjc alloc] init];
    self.timeZoneUploader.deviceNickname = @"FluxtreamCapture";
    // UTC offset and current time zone abbreviation share the same channel name -- one is numeric, and one is string
    [self.timeZoneUploader addChannel:@"TimeZoneOffset"]; // Offset from UTC, in seconds
    [self.timeZoneUploader addStringChannel:@"TimeZoneOffset"]; // Current time zone abbreviation (e.g. EST, EDT)
    [self.timeZoneUploader addStringChannel:@"TimeZoneName"];   // Time zone name (e.g. America/Chicago)
    self.timeZoneUploader.logSamples = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.timeZoneUploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    self.timeZoneUploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    
    double updateInterval = 5*60; // seconds
    self.timeZoneUploader.maximumAge = 15*60; // seconds
    
    self.timeZoneCaptureTimer =
    [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(captureTimeZone) userInfo:nil repeats:YES];
}

- (void)captureTimeZone {
    // We care when the system time zone changes, so we need to clear the application's cache
    // of the system's time zone before reading it.
    [NSTimeZone resetSystemTimeZone];
    NSTimeZone *systemTimeZone = [NSTimeZone systemTimeZone];
    
    double numericValues[] = {
        (double) [systemTimeZone secondsFromGMT]
    };
    
    NSArray *stringValues = [NSArray arrayWithObjects:[systemTimeZone abbreviation], [systemTimeZone name], nil];
    
    [self.timeZoneUploader addSample:[FluxtreamUploaderObjc now]
                       numericValues:numericValues numericCount:sizeof(numericValues)/sizeof(numericValues[0])
                        stringValues:stringValues];
}

// Stats on application

- (void)initAppStatsCapture {
    self.appStatsUploader = [[FluxtreamUploaderObjc alloc] init];
    self.appStatsUploader.deviceNickname = @"FluxtreamCapture";
    // UTC offset and current time zone abbreviation share the same channel name -- one is numeric, and one is string
    [self.appStatsUploader addChannel:@"InBackground"];            // 0=in foreground, 1=in background
    [self.appStatsUploader addChannel:@"BackgroundTimeRemaining"]; // in seconds
    [self.appStatsUploader addChannel:@"SystemwideWiredMemory"];   // in MB
    [self.appStatsUploader addChannel:@"SystemwideActiveMemory"];  // in MB
    [self.appStatsUploader addChannel:@"SystemwideFreeMemory"];    // in MB
    [self.appStatsUploader addChannel:@"SystemwideTotalCPUUsage"]; // % of total (1=100% of all cores)
    [self.appStatsUploader addChannel:@"SystemwideUserCPUUsage"];  // % of total (1=100% of all cores)
    [self.appStatsUploader addChannel:@"AppResidentMemory"];       // in MB
    [self.appStatsUploader addChannel:@"AppVirtualMemory"];        // in MB
    [self.appStatsUploader addChannel:@"AppTotalCPUUsage"];        // % of total (1=100% of all cores)
    [self.appStatsUploader addChannel:@"AppUserCPUUsage"];         // % of total (1=100% of all cores)
    self.appStatsUploader.logSamples = YES;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.appStatsUploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    self.appStatsUploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    
    self.appStatsUploader.maximumAge = 15*60; // seconds
    self.recordAppStatsEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
}

- (void)setRecordAppStatsEnabled:(BOOL)enabled {
    _recordAppStatsEnabled = enabled;
    if (self.recordAppStatsEnabled && !self.appStatsCaptureTimer) {
        double updateInterval = 1*60; // seconds
        self.appStatsCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(captureAppStats) userInfo:nil repeats:YES];
    } else if (!self.recordAppStatsEnabled && self.appStatsCaptureTimer) {
        [self.appStatsCaptureTimer invalidate];
        self.appStatsCaptureTimer = NULL;
    }
}

static double toDouble(time_value_t t) {
    return t.seconds + t.microseconds * 1e-6;
}

static double toDouble(struct timeval t) {
    return t.tv_sec + t.tv_usec * 1e-6;
}

#include <sys/resource.h>

- (void)captureAppStats {
    double now = [FluxtreamUploaderObjc now];

    double backgroundTimeRemaining = [[UIApplication sharedApplication] backgroundTimeRemaining];
    
    // System RAM stats.  Consider moving this to Utils
    vm_statistics_data_t vmStats;
    memset(&vmStats, 0, sizeof(vmStats));
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);

    vm_size_t pagesize;
    host_page_size(mach_host_self(), &pagesize);
    
    double megabytesPerPage = pagesize / (1024.0*1024.0);
    
    double systemwideWiredMemory  = vmStats.wire_count   * megabytesPerPage;
    double systemwideActiveMemory = vmStats.active_count * megabytesPerPage;
    double systemwideFreeMemory   = vmStats.free_count   * megabytesPerPage;
    
    double systemwideUserCpuTime, systemwideSystemCpuTime; // in seconds
    int cpuCount;
    
    get_systemwide_cpu_usage(systemwideUserCpuTime, systemwideSystemCpuTime, cpuCount);
    double systemwideTotalCpuTime = systemwideUserCpuTime + systemwideSystemCpuTime;
    
    // App RAM usage.  Consider moving this to Utils
    struct task_basic_info taskInfo;
    memset(&taskInfo, 0, sizeof(taskInfo));
    mach_msg_type_number_t taskInfoSize = TASK_BASIC_INFO_COUNT;
    task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&taskInfo, &taskInfoSize);
    double appResidentMemory = taskInfo.resident_size / (1024.0 * 1024.0);
    double appVirtualMemory  = taskInfo.virtual_size  / (1024.0 * 1024.0);
    
    // App CPU usage.  Consider moving this to Utils
    struct rusage usage;
    getrusage(RUSAGE_SELF, &usage);
    double appUserCpuTime = toDouble(usage.ru_utime);
    double appTotalCpuTime = toDouble(usage.ru_stime) + appUserCpuTime;
    
    double vals[] = {
        (double) inBackground,
        backgroundTimeRemaining,
        systemwideWiredMemory,
        systemwideActiveMemory,
        systemwideFreeMemory,
        systemwideTotalCpu.update(now, systemwideTotalCpuTime) / cpuCount,
        systemwideUserCpu.update (now, systemwideUserCpuTime ) / cpuCount,
        appResidentMemory,
        appVirtualMemory,
        appTotalCpu.update(now, appTotalCpuTime) / cpuCount,
        appUserCpu. update(now, appUserCpuTime ) / cpuCount,
    };
    
    [self.appStatsUploader addSample:[FluxtreamUploaderObjc now] values:vals count:sizeof(vals)/sizeof(vals[0])];
}

// Location capture

static const char *authorizationStatusDescription(CLAuthorizationStatus status) {
    switch (status) {
        case kCLAuthorizationStatusNotDetermined: return "Not determined";
        case kCLAuthorizationStatusRestricted:    return "Restricted";
        case kCLAuthorizationStatusDenied:        return "Denied";
        case kCLAuthorizationStatusAuthorized:    return "Authorized";
        default:                                  return "Unknown";
    }
}
- (void)initLocationCapture
{
    self.locationUploader = [[FluxtreamUploaderObjc alloc] init];
    self.locationUploader.deviceNickname = @"FluxtreamCapture";
    [self.locationUploader addChannel:@"Latitude"];           // degrees
    [self.locationUploader addChannel:@"Longitude"];          // degrees
    [self.locationUploader addChannel:@"Altitude"];           // meters above sea level
    [self.locationUploader addChannel:@"HorizontalAccuracy"]; // uncertainty, in meters
    [self.locationUploader addChannel:@"VerticalAccuracy"];   // uncertainty, in meters
    [self.locationUploader addChannel:@"Speed"];              // meters/second.  Invalid = negative
    [self.locationUploader addChannel:@"Course"];             // degrees.  North=0, East=90, ...;  Invalid = negative
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.locationUploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    self.locationUploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    _recordLocationEnabled = [defaults boolForKey:DEFAULTS_RECORD_LOCATION];
    
    self.locationUploader.logSamples = YES;
    self.locationUploader.maximumAge = 15*60;

    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.pausesLocationUpdatesAutomatically = NO;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    [self startCapturingLocation];
    NSLog(@"initLocationCapture authorization status: %s", authorizationStatusDescription([CLLocationManager authorizationStatus]));
    
    double updateInterval = 9*60; // seconds
    self.locationCaptureTimer = [NSTimer scheduledTimerWithTimeInterval:updateInterval target:self selector:@selector(startCapturingLocation) userInfo:nil repeats:YES];
}

- (void)startCapturingLocation
{
    NSLog(@"startCapturingLocation, remaining time before: %g", [app() backgroundTimeRemaining]);
    [self.locationManager startUpdatingLocation];
    NSLog(@"startCapturingLocation, remaining time after: %g", [app() backgroundTimeRemaining]);
}

- (void)stopCapturingLocation
{
    NSLog(@"stopCapturingLocation, remaining time before: %g", [app() backgroundTimeRemaining]);
    [self.locationManager stopUpdatingLocation];
    NSLog(@"stopCapturingLocation, remaining time after: %g", [app() backgroundTimeRemaining]);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    // TODO(rsargent): CLLocation gives negative speed or heading when invalid;  can we upload in such a way to not send invalid values?
    //   e.g. NaN, JSON NULL?
    NSLog(@"didUpdateLocations");
    if (self.recordLocationEnabled) {
        for (CLLocation *location in locations) {
            [self.locationUploader
             addSample:[location.timestamp timeIntervalSince1970]
             ch0: location.coordinate.latitude
             ch1: location.coordinate.longitude
             ch2: location.altitude
             ch3: location.horizontalAccuracy
             ch4: location.verticalAccuracy
             ch5: location.speed
             ch6: location.course];
        }
    }
    [self stopCapturingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"locationManager didFailWithError %@", [error description]);
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    NSLog(@"locationManager didFinishDeferredUpdatesWithError %@", [error description]);
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
    NSLog(@"locationManagerDidPauseLocationUpdates");
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
    NSLog(@"locationManagerDidResumeLocationUpdates");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    NSLog(@"locationManager didUpdateHeading");
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    NSLog(@"didChangeAuthorizationStatus to %s", authorizationStatusDescription(status));
}

- (void)initMotionCapture
{
    _recordMotionEnabled = false;
    self.motionUploader = [[FluxtreamUploaderObjc alloc] init];
    self.motionUploader.deviceNickname = @"FluxtreamCapture";
    [self.motionUploader addChannel:@"AccelX"];
    [self.motionUploader addChannel:@"AccelY"];
    [self.motionUploader addChannel:@"AccelZ"];
    [self.motionUploader addChannel:@"RotX"];
    [self.motionUploader addChannel:@"RotY"];
    [self.motionUploader addChannel:@"RotZ"];
    [self.motionUploader addChannel:@"RotW"];
    // TODO(rsargent): remove these once we've characterized the system
    [self.motionUploader addChannel:@"Lag"];
    [self.motionUploader addChannel:@"Drift"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.motionUploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    self.motionUploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    
    self.motionUploader.maximumAge = 15 * 60.0;
    self.motionUploader.logSamples = NO;
    
    self.motionManager = [[CMMotionManager alloc] init];
    double updateRate = 10; // Hz
    self.motionManager.deviceMotionUpdateInterval = 1. / updateRate;
    self.motionQueue = [[NSOperationQueue alloc] init];

    [self setRecordMotionEnabled:[defaults boolForKey:DEFAULTS_RECORD_MOTION]];
}

- (void)setRecordMotionEnabled:(BOOL)recordMotionEnabled
{
    recordMotionEnabled = !!recordMotionEnabled;
    if (recordMotionEnabled != _recordMotionEnabled) {
        _recordMotionEnabled = recordMotionEnabled;
        if (!recordMotionEnabled) {
            [self.motionManager stopDeviceMotionUpdates];
        } else {
            motionTimeOffsetFilter = 0.01;
            motionTimeOffsetSum = motionTimeOffsetWeight = 0;
            
            [self.motionManager
             startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
             toQueue:self.motionQueue
             withHandler:^(CMDeviceMotion *motion, NSError *error) {
                 double now = [FluxtreamUploaderObjc now];
                 CMAcceleration a = [motion userAcceleration];
                 CMAttitude *attitude = [motion attitude];
                 CMQuaternion q = [attitude quaternion];
                 
                 // Motion timestamps are measured in time since boot, but we need to convert these to epoch time
                 // to upload.
                 //
                 // Converting from time since boot to epoch time is complicated by two factors:
                 // 1) The offset between them changes over time, since the device's notion of epoch time can be warped by external
                 //    time update (e.g. ntp or cell network).
                 // 2) There's an unknown lag between measurement capture and our service of it in this routine
                 //
                 // We estimate the "time offset" to add to the motion timestamp to yield epoch time, by low-pass filtering
                 // the apparent time offset of each sample (assuming lag time=0).  The end result is that we slowly adjust to
                 // changes in epoch time.
                 
                 double apparentSampleOffset = now - motion.timestamp;
                 motionTimeOffsetSum = apparentSampleOffset * motionTimeOffsetFilter + motionTimeOffsetSum * (1. - motionTimeOffsetFilter);
                 motionTimeOffsetWeight = motionTimeOffsetFilter + motionTimeOffsetWeight * (1. - motionTimeOffsetFilter);
                 double timeOffset = motionTimeOffsetSum / motionTimeOffsetWeight;
                 if (motionTimeOffsetWeight < 0.5) {
                     // Keep updating this until the offset estimate is half-full, then freeze it for drift calculation
                     motionInitialTimeOffset = timeOffset;
                 }
                 double sampleTime = motion.timestamp + timeOffset;
                 
                 // Larger lag means it's taking longer between sample capture and now
                 double lag = now - sampleTime;
                 
                 // Positive drift means epoch time appears to be advancing faster than time since boot
                 double drift = timeOffset - motionInitialTimeOffset;
                 [self.motionUploader addSample:sampleTime ch0:a.x ch1:a.y ch2:a.z ch3:q.x ch4:q.y ch5:q.z ch6:q.w ch7:lag ch8:drift];
                 
                 
                 //NSLog(@"got update %+7f\t%+7f\t%+7f\t%+7f\t%+7f\t%+7f\t%+7f\t%+7f\t%+7f\t%+11f",
                 //      q.x, q.y, q.z, q.w,
                 //      a.x, a.y, a.z,
                 //      lag, drift,
                 //      motion.timestamp);
             }];
        }
    }
}

@end
