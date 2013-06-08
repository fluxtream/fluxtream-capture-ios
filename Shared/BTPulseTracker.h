//
//  BTPulseTracker.h
//  HeartRateMonitor
//
//  Created by Nick Winter on 10/20/12.
//  Copyright (c) 2012 BodyTrack.
//

/*
 We could subclass this to BTBlueToothLEPulseTracker if we wanted to do other protocols.
 */

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE
#import <CoreBluetooth/CoreBluetooth.h>
#else
#import <IOBluetooth/IOBluetooth.h>
#endif
#import "FluxtreamUploaderObjc.h"
#import "Logger.h"

#include "UUID.h"

#define BT_NOTIFICATION_PULSE @"bt_pulse_notification"
#define BT_NOTIFICATION_HR_DATA @"bt_hr_data_notification"

@protocol BTPulseTrackerDelegate;

@interface BTPulseTracker : NSObject <CBCentralManagerDelegate, CBPeripheralDelegate>

@property (strong) FluxtreamUploaderObjc *uploader;
@property (weak) id<BTPulseTrackerDelegate> delegate;  /// Delegate receives notifications on peripheral connection changes, as well as pulse changes.
@property (strong) Logger *logger;

@property (strong) NSTimer *pulseTimer;

@property (assign) BOOL autoConnect;

typedef enum {
    kConnectBestSignalMode = 0,
    kConnectUUIDMode = 1
} BTPulseTrackerConnectMode;

typedef enum {
    BTPulseTrackerScanState = 0,
    BTPulseTrackerConnectingState = 1,
    BTPulseTrackerConnectedState = 2,
    BTPulseTrackerStoppedState = 3
} BTPulseTrackerState;

@property BTPulseTrackerConnectMode connectMode;
@property UUID connectUUID;

@property double lastStateChangeTime;
@property (nonatomic) BTPulseTrackerState state;

// TODO(rsargent): honor the "enabled" property
@property (nonatomic) BOOL enabled;

@property (nonatomic) BOOL heartbeatSoundEnabled;

@property (readonly) NSString *connectionStatus;
@property (readonly) NSString *connectionStatusWithDuration;
@property (readonly) NSString *receivedStatusWithDuration;
@property (readonly) BOOL connected;
@property (readonly) NSString *peripheralNickname;

@property (copy) NSString *manufacturer;

@property (assign) double heartRate;
@property (assign) double r2r;
@property (assign) double lastBeatTime;
@property (assign) BOOL lastBeatTimeValid;
@property double lastHRDataReceived;

- (void)tryConnect;
- (void)disconnect;
- (BOOL)checkBluetooth;

@end


@protocol BTPulseTrackerDelegate <NSObject>

- (void)onPulseTrackerNoBluetooth:(BTPulseTracker *)aTracker reason:(NSString *)reason;
- (void)onPulseTrackerConnected:(BTPulseTracker *)aTracker;
- (void)onPulseTrackerDisconnected:(BTPulseTracker *)aTracker;
- (void)onPulse:(BTPulseTracker *)aTracker;

@end


