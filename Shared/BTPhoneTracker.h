//
//  BTPhoneTracker.h
//  Stetho
//
//  Created by rsargent on 12/22/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "FluxtreamUploaderObjc.h"
#import "Logger.h"

@interface BTPhoneTracker : NSObject <CLLocationManagerDelegate>


@property (strong) FluxtreamUploaderObjc *batteryUploader;
@property (strong) FluxtreamUploaderObjc *timeZoneUploader;
@property (strong) FluxtreamUploaderObjc *appStatsUploader;
@property (strong) FluxtreamUploaderObjc *locationUploader;
@property (strong) FluxtreamUploaderObjc *motionUploader;

@property (strong) Logger *logger;

@property BOOL recordLocationEnabled;
@property (nonatomic) BOOL recordMotionEnabled;
@property (nonatomic) BOOL recordBatteryEnabled;
@property (nonatomic) BOOL recordAppStatsEnabled;

// CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error;

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager;
- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager;

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading;
// - (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager;

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status;

@end
