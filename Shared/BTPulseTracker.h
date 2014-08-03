//
//  BTPulseTracker.h
//  HeartRateMonitor
//
//  Randy Sargent and Nick Winter
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

@property (nonatomic) BOOL enabled;
@property (nonatomic) BOOL heartbeatSoundEnabled;

@property (strong) NSTimer *pulseTimer;

@property (nonatomic) BOOL connectOnlyToNickname;
@property (nonatomic) NSString *connectNickname;

typedef enum {
    BTPulseTrackerDisabledState = 0,
    BTPulseTrackerScanState = 1,
    BTPulseTrackerConnectingState = 2,
    BTPulseTrackerConnectedState = 3,
    BTPulseTrackerStoppedState = 4
} BTPulseTrackerState;

@property double lastStateChangeTime;
@property (nonatomic) BTPulseTrackerState state;

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

- (BOOL)checkBluetooth;

@end


@protocol BTPulseTrackerDelegate <NSObject>

- (void)onPulseTrackerNoBluetooth:(BTPulseTracker *)aTracker reason:(NSString *)reason;
- (void)onPulseTrackerConnected:(BTPulseTracker *)aTracker;
- (void)onPulseTrackerDisconnected:(BTPulseTracker *)aTracker;
- (void)onPulse:(BTPulseTracker *)aTracker;

@end


