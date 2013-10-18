//
//  BTPulseTracker.m
//  HeartRateMonitor
//
//  Created by Nick Winter on 10/20/12.
//

#import "BTPulseTracker.h"
#include <vector>
#include <string>
#include <deque>
#include <sys/time.h>
#import "Utils.h"
#import "NSUtils.h"
#import "Samples.h"
#include "Nickname.h"

#include "UUID.h"

@interface BTPulseTracker()
- (void)startScan;
- (void)stopScan;
- (void)connectToBestSignal;
- (void)connectPeripheral:(CBPeripheral *)peripheral;
- (void)disconnectPeripheral:(CBPeripheral *)peripheral;

- (void)pulse;
- (void)updateWithHRMData:(NSData *)data;


@property (strong) CBCentralManager *manager;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property BOOL waitingForBestRSSI;
@property double bestRSSI;
@property (strong) CBPeripheral *bestPeripheral;
@property (strong) NSMutableArray *discoveredPeripherals;

@end

static UUID getUUID(CFUUIDRef uuid) {
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    return UUID(&uuidBytes, sizeof(uuidBytes));
}

/*
 * Get printable name for peripheral
 */
static NSString *getNickname(CBPeripheral *peripheral) {
    // Polar H7 has unique identifier as part of name, awesome
    if ([peripheral.name hasPrefix:@"Polar H7 "]) {
        return peripheral.name;
    }
    // Otherwise, give it a nickname according to UUID, if possible
    if (peripheral.UUID) {
        CFUUIDBytes uuid  = CFUUIDGetUUIDBytes(peripheral.UUID);
        return [NSString stringWithFormat:@"%@ (%s)", peripheral.name, computeNickname(&uuid, sizeof(uuid)).c_str()];
    } else {
        if (sizeof(peripheral) == 4) {
            return [NSString stringWithFormat:@"%@ %08lX", peripheral.name, (unsigned long) peripheral];
        } else {
            return [NSString stringWithFormat:@"%@ %016llX", peripheral.name, (unsigned long long) peripheral];
        }
    }
}

@implementation BTPulseTracker
@synthesize peripheral = _peripheral;


#pragma mark - Object lifecycle

- (id)init {
    if(self = [super init]) {
        self.lastStateChangeTime = 0;
        self.logger = [[Logger alloc] init];
        self.autoConnect = YES;
        self.discoveredPeripherals = [[NSMutableArray alloc] init];
        
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        if (self.autoConnect) [self tryConnect];

        self.uploader = [[FluxtreamUploaderObjc alloc] init];
        self.uploader.deviceNickname = @"PolarStrap";
        [self.uploader addChannel:@"HeartRate"];
        [self.uploader addChannel:@"BeatSpacing"];
        self.uploader.maximumAge = 60.0;
    }
    return self;
}

- (void)dealloc {
    [self stopScan];
    self.delegate = nil;
    [self.peripheral setDelegate:nil];
}

#pragma mark - Public connection stuff

- (void)disconnect {
    self.autoConnect = NO;
    if (self.peripheral) {
        [self disconnectPeripheral: self.peripheral];
    }
}

- (void)tryConnect {
    if (!self.peripheral) {
        [self.discoveredPeripherals removeAllObjects];
        [self startScan];
    }
}

- (NSString *)connectionStatus {
    NSString *nickname = self.peripheralNickname;
    switch (self.state) {
        case BTPulseTrackerScanState:
            return [NSString stringWithFormat:@"Scanning for heart rate monitor"];
        case BTPulseTrackerConnectingState:
            return [NSString stringWithFormat:@"Connecting to %@", nickname];
        case BTPulseTrackerConnectedState:
            return [NSString stringWithFormat:@"Connected to %@", nickname];
        case BTPulseTrackerStoppedState:
            return [NSString stringWithFormat:@"Stopped"];
        default:
            return nil;
    }
}
- (NSString *)connectionStatusWithDuration {
    NSString *status = self.connectionStatus;
    if (self.lastStateChangeTime != 0 && doubletime() - self.lastStateChangeTime > 2.0) {
        status = [self.connectionStatus stringByAppendingFormat:@" for %@",
                  printDuration(doubletime() - self.lastStateChangeTime)];
    }
    return status;
}

- (NSString *)receivedStatusWithDuration {
    double age = doubletime() - self.lastHRDataReceived;
    if (self.state != BTPulseTrackerConnectedState) {
        return @"";
    } else if (self.lastHRDataReceived == 0) {
        return @"No data received.";
    } else if (age < 5) {
        return @"Receiving data.";
    } else {
        return [NSString stringWithFormat:@"Data last received %@ ago.", printDuration(age)];
    }
}

-(void)setPeripheral:(CBPeripheral*)peripheral {
    if (_peripheral) {
        [_peripheral setDelegate:nil];
    }
    
    if (_peripheral && [self.delegate respondsToSelector:@selector(onPulseTrackerDisconnected:)]) {
        [self.delegate onPulseTrackerDisconnected:self];
    }
    
    _peripheral = peripheral;
    
    if (peripheral && [self.delegate respondsToSelector:@selector(onPulseTrackerConnected:)]) {
        [self.delegate onPulseTrackerConnected:self];
    }
    
    if (peripheral) {
        [peripheral setDelegate:self];
    }
}

-(NSString*)peripheralNickname {
    if (self.peripheral) return getNickname(self.peripheral);
    else return nil;
}

- (void)setState:(BTPulseTrackerState)state {
    if (_state != state) {
        NSLog(@"changing state from %d to %d", _state, state);
        if (self.lastStateChangeTime != 0 && doubletime() - self.lastStateChangeTime > 2.0) {
            [self.logger log:@"%@", self.connectionStatusWithDuration];
        }
        _state = state;
        self.lastStateChangeTime = doubletime();
        [self.logger log:@"%@", self.connectionStatus];
    }
}

#pragma mark - Start/Stop Scan methods

/*
 * Do we support Bluetooth LE?
 * Raise alert if Bluetooth LE is not enabled or is not supported.
 */
- (BOOL) checkBluetooth
{
    NSString * state = nil;
    switch ([self.manager state])
    {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            state = @"Something is wrong with Bluetooth Low Energy support.";
    }
    NSLog(@"Central manager state: %@", state);
    if([self.delegate respondsToSelector:@selector(onPulseTrackerNoBluetooth:reason:)])
        [self.delegate onPulseTrackerNoBluetooth:self reason:state];
    return FALSE;
}

/*
 * Request CBCentralManager to scan for heart rate peripherals using service UUID 0x180D
 */
- (void) startScan
{
    self.state = BTPulseTrackerScanState;
    self.peripheral = nil;
    self.manufacturer = @"";
    self.heartRate = 0;

    if (self.connectMode == kConnectBestSignalMode) {
        self.waitingForBestRSSI = YES;
        self.bestPeripheral = nil;
        self.bestRSSI = -1e100;
        double waitTime = 3;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (waitTime * NSEC_PER_SEC)),
                       dispatch_get_main_queue(),
                       ^{ [self connectToBestSignal]; });
    } else {
        self.waitingForBestRSSI = NO;
    }
    [self.manager scanForPeripheralsWithServices:[NSArray arrayWithObject:[CBUUID UUIDWithString:@"180D"]] options:nil];
}

/*
 Request CBCentralManager to stop scanning for heart rate peripherals
 */
- (void) stopScan
{
    [self.manager stopScan];
}

#pragma mark - Heart Rate Data

/*
 Update UI with heart rate data received from device
 Docs at http://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicViewer.aspx?u=org.bluetooth.characteristic.heart_rate_measurement.xml
 */

- (void) updateWithHRMData:(NSData *)data
{
    double now = doubletime();
    self.lastHRDataReceived = now;
    const uint8_t *reportData = (const uint8_t*) [data bytes];
    const uint8_t *reportDataEnd = reportData + [data length];
    
    uint8_t flags = *reportData++;
    
    uint16_t bpm = 0;
    
    if (flags & 0x01) {
        /* uint16 bpm */
        bpm = CFSwapInt16LittleToHost(*(uint16_t *)reportData);
        reportData += 2;
    } else {
        /* uint8 bpm */
        bpm = *reportData++;
    }
    
    uint16_t energyExpended = 0;
    boolean_t energyExpendedValid = false;
    
    if (flags & 0x08) {
        energyExpended = CFSwapInt16LittleToHost(*(uint16_t*) reportData);
        energyExpendedValid = true;
        reportData += 2;
    }
    
    std::vector<double> r2rs;
    std::vector<double> beatTimes;
    if (flags & 0x10) {
        double totalDuration = 0;
        while (reportData < reportDataEnd) {
            double an_r2r = CFSwapInt16LittleToHost(*(uint16_t*) reportData)/1024.0;
            r2rs.push_back(an_r2r);
            totalDuration += an_r2r;
            reportData += 2;
        }
        if (!self.lastBeatTimeValid) {
            self.lastBeatTime = now - totalDuration;
            self.lastBeatTimeValid = true;
        }
        for (unsigned i = 0; i < r2rs.size(); i++) {
            self.lastBeatTime += r2rs[i];
            beatTimes.push_back(self.lastBeatTime);
        }
        double error = now - self.lastBeatTime;
        double maxError = 5.0;
        if (fabs(error) > maxError) {
            double correction = (error > 0 ? 0.1 : -0.1) * (fabs(error) - maxError);
            std::string msg = string_printf("Error = %.3f, correcting beatTimes by %.3f", error, correction);
            NSLog(@"%@", [NSString stringWithUTF8String:msg.c_str()]);
            self.lastBeatTime += correction;
        }
    }
    
    bool log = false;
    std::string msg;
    
    if (log) msg = string_printf("Time: %.3f, BPM: %d", now, bpm);
    if (r2rs.size()) {
        if (log) msg += ", R2R: [";
        for (unsigned i = 0; i < r2rs.size(); i++) {
            if (log) if (i) msg += ", ";
            if (log) msg += string_printf("%.3f:%.3f", beatTimes[i]-now, r2rs[i]);
            [self.uploader addSample:beatTimes[i] ch0:bpm ch1:r2rs[i]];
        }
        if (log) msg += "]";
    }
    
    if (log) msg += string_printf(" (now %ld samples stored)", (long) [self.uploader sampleCount]);
    
    if (log) NSLog(@"HRM received: %@", [NSString stringWithUTF8String:msg.c_str()]);
    
    double oldBpm = self.heartRate;
    self.heartRate = bpm;
    if(r2rs.size()) {
        self.r2r = r2rs[r2rs.size() - 1];
    } else if (bpm == 0) {
        self.r2r = 0;
    }
    if (oldBpm == 0) {
        [self pulse];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_HR_DATA object:self];
}

- (void)pulse {
    if([self.delegate respondsToSelector:@selector(onPulse:)])
        [self.delegate onPulse:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_PULSE object:self];
    //NSLog(@"Got heart rate: %d", self.heartRate);
    if (self.heartRate != 0) {
        self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:(60. / self.heartRate) target:self selector:@selector(pulse) userInfo:nil repeats:NO];
    }
}


#pragma mark - CBCentralManager delegate methods
/*
 Invoked whenever the central manager's state is updated.
 */
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self checkBluetooth];
}


/*
 * Connecting to Bluetooth Smart / Bluetooth Low Energy devices is interesting
 *
 * Devices do not advertise a UUID;  the UUID is only discoverable upon connecting to the device
 *
 * Devices have addresses, but these addresses may be scrambled every 15 mins.
 *
 * The OS maintains a mapping from address to CBPeripheral*, so you can check to see if the CBPeripheral is identical
 * to know if the device address is identical, but again, the address can get scrambled every 15 mins, so beware.
 *
 * Until you've connected with a particular CBPeripheral, it's UUID is set to nil.
 *
 * Pseudocode for discovering all UUIDs that are available
 *
 * scan
 * for each didDiscoverPeripheral:
 *   try to load 
 *
 * Pseudocode for trying to reconnect to a particular UUID:
 *
 * scan
 * discover peripheral:
 *   connect to peripheral
 *     connected:  have correct UUID?  Done!
 *
 * Pseudocode for trying to connect to best-signal
 *
 * scan
 * phase1, for 3 seconds:
 * discover peripheral:
 *    queue it
 * phase2:
 * if any discovered, connect to the one with the best signal
 * otherwise:
 * discover peripheral:
 *
 * but only populates
 * Reference: http://lists.apple.com/archives/bluetooth-dev/2012/Aug/msg00107.html
 */

/*
 * CBCentralManager discovered a peripheral during scanning
 */
- (void) centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)nsRSSI
{
    double rssi = [nsRSSI doubleValue];
    if (self.waitingForBestRSSI) {
        [self.logger logVerbose:@"Found %@ with signal strength %g", getNickname(peripheral), rssi];
        if (!self.bestPeripheral || rssi > self.bestRSSI) {
            self.bestPeripheral = peripheral;
            self.bestRSSI = rssi;
        }
    } else {
        if (self.connectMode == kConnectUUIDMode && peripheral.UUID && getUUID(peripheral.UUID) != self.connectUUID) {
            // Not the device we're looking for
            [self.logger logVerbose:@"Found device %@", getNickname(peripheral)];
        } else {
            [self connectPeripheral:peripheral];
        }
    }
}

- (void) connectToBestSignal
{
    self.waitingForBestRSSI = NO;
    if (!self.peripheral && self.bestPeripheral) {
        [self.logger logVerbose:@"Best signal is %@", getNickname(self.bestPeripheral)];
        [self connectPeripheral: self.bestPeripheral];
    } else if (!self.bestPeripheral) {
        NSLog(@"No devices found by best signal collection timeout");
    }
}

/*
 * Request connection to peripheral
 */
- (void) connectPeripheral:(CBPeripheral*)peripheral
{
    if (!self.peripheral) {
        self.peripheral = peripheral;
        self.state = BTPulseTrackerConnectingState;
        [self.manager connectPeripheral:peripheral options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    }
}

/*
 Invoked when the central manager creates a connection to a peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    self.lastBeatTimeValid = false;
    if (self.connectMode == kConnectUUIDMode && self.connectUUID != getUUID(peripheral.UUID)) {
        [self.logger logVerbose:@"(Disconnecting from wrong device %@)", getNickname(peripheral)];
        [self disconnectPeripheral:peripheral];
    } else if (peripheral != self.peripheral) {
        [self.logger logVerbose:@"(Disconnecting from unexpected device %@)", getNickname(peripheral)];
        [self disconnectPeripheral:peripheral];
    } else {
        self.state = BTPulseTrackerConnectedState;
        [self.logger logVerbose:@"Peripheral UUID=%@", hex(peripheral.UUID)];
        [peripheral discoverServices:nil];
    }
    [self stopScan];
}

/*
 * Request disconnection from peripheral
 */

- (void) disconnectPeripheral:(CBPeripheral *)peripheral
{
    [self.logger logVerbose:@"Requesting disconnect from %@", getNickname(peripheral)];
    [self.manager cancelPeripheralConnection:self.peripheral];
}

/*
 Invoked whenever an existing connection with the peripheral is torn down.
 Reset local variables
 */
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    if (self.peripheral == peripheral) {
        [self.logger log:@"Lost connection to %@", getNickname(peripheral)];
        [self startScan];
    } else {
        [self.logger logVerbose:@"(Disconnected from %@)", getNickname(peripheral)];
    }
}

/*
 Invoked when the central manager fails to create a connection with the peripheral.
 */
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    [self.logger log:@"Failed to connect to %@", getNickname(peripheral)];
    // [error localizedDescription]
}

#pragma mark - CBPeripheral delegate methods
/*
 Invoked upon completion of a -[discoverServices:] request.
 Discover available characteristics on interested services
 
 *
 * 1800: Generic Access
 * 1801: Generic Attribute
 * 180a: Device Informaion
 * 180d: Heart Rate
 * 180f: Battery Service
 * 
 */
- (void) peripheral:(CBPeripheral *)aPeripheral didDiscoverServices:(NSError *)error
{
    for (CBService *aService in aPeripheral.services)
    {
        [aPeripheral discoverCharacteristics:nil forService:aService];
    }
}

/*
 * Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 * Perform appropriate operations on interested characteristics
 *
 * http://developer.bluetooth.org/gatt/characteristics/Pages/CharacteristicsHome.aspx
 *
 * Polar H7:
 *
 * 1800:2a00 Device Name
 * 1800:2a01 Appearance
 * 1800:2a02 Privacy flag
 * 1800:2a03 Reconnection address
 * 1800:2a04 Peripheral preferred connection parameters
 *
 * 1801:2a05 Service changed
 *
 * 180a:2a23 System ID
 * 180a:2a24 Model number string
 * 180a:2a25 Serial number string
 * 180a:2a26 Firmware revision string
 * 180a:2a27 Hardware revision string
 * 180a:2a28 Software revision string
 * 180a:2a29 Manufacturer name string
 *
 * 180d:2a37 Heart Rate measurement
 * 180d:2a38 Body Sensor Location
 *
 * 180f:2a19 Battery Level (%)
 */

unsigned long long u64(CBUUID *uuid);

unsigned long long u64(CBUUID *uuid) {
    unsigned long long ret = 0;
    const unsigned char *bytes = (const unsigned char *) uuid.data.bytes;
    for (unsigned i = 0; i < uuid.data.length; i++) {
        ret |= (((unsigned long long)bytes[uuid.data.length - 1 - i]) << (i * 8));
    }
    return ret;
}

NSString *hex(CFUUIDRef uuid);
NSString *hex(CFUUIDRef uuid) {
    CFUUIDBytes uuidBytes = CFUUIDGetUUIDBytes(uuid);
    NSMutableString *ret = [[NSMutableString alloc] init];
    for (unsigned i = 0; i < sizeof(uuidBytes); i++) {
        [ret appendFormat:@"%02X", ((unsigned char*) & uuidBytes)[i]];
    }
    return ret;
}

unsigned long long lsbFirst(NSData *data);

unsigned long long lsbFirst(NSData *data) {
    unsigned long long ret = 0;
    const unsigned char *bytes = (const unsigned char *) data.bytes;
    size_t length = data.length;
    for (unsigned i = 0; i < length; i++) {
        ret |= (((unsigned long long)bytes[i]) << (i * 8));
    }
    return ret;
}


/*
 * Discovered characteristic
 */

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    
    for (CBCharacteristic *ch in service.characteristics)
    {
        unsigned long long serviceID = (u64(service.UUID) << 32) | u64(ch.UUID);
        if (ch.properties & CBCharacteristicPropertyRead) {
            NSLog(@"Requesting read of %llX", serviceID);
            [peripheral readValueForCharacteristic:ch];
        }
        if (ch.properties & CBCharacteristicPropertyNotify) {
            NSLog(@"Requesting notification for %llX", serviceID);
            [peripheral setNotifyValue:YES forCharacteristic:ch];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)ch error:(NSError *)error
{
    if (error) {
        NSLog(@"Characteristic %X has error %@", (int)u64(ch.UUID), [error description]);
        return;
    }
    if (!ch.value) {
        NSLog(@"Characteristic %X has no value", (int)u64(ch.UUID));
        return;
    }
    switch (u64(ch.UUID)) {
        case 0x2A37: // Heart rate
            [self updateWithHRMData:ch.value];
            break;
        case 0x2A19: // Battery level
            [self.logger log:@"Battery level is %d%%", (int)lsbFirst(ch.value)];
            break;
        case 0x2A00: // Device name
            [self.logger logVerbose:@"Device name: %@", utf8(ch.value)];
            break;
        case 0x2A23: // System ID
            [self.logger logVerbose:@"Device UUID: %llX", lsbFirst(ch.value)];
            break;
        case 0x2A24: // Model number
            [self.logger logVerbose:@"Model: %@", utf8(ch.value)];
            break;
        case 0x2A25: // Serial number
            [self.logger logVerbose:@"Serial number: %@", utf8(ch.value)];
            break;
        case 0x2A26: // Firmware revision
            [self.logger logVerbose:@"Firmware version: %@", utf8(ch.value)];
            break;
        case 0x2A27: // Hardware revision
            [self.logger logVerbose:@"Hardware version: %@", utf8(ch.value)];
            break;
        case 0x2A28: // Software revision
            [self.logger logVerbose:@"Software version: %@", utf8(ch.value)];
            break;
        case 0x2A29: // Manufacturer
            [self.logger logVerbose:@"Manufacturer: %@", utf8(ch.value)];
            self.manufacturer = utf8(ch.value);
            break;
        case 0x2A38: // Body sensor location
            [self.logger logVerbose:@"Body sensor location: %d", (int)lsbFirst(ch.value)];
            break;
        default:
            [self.logger logVerbose:@"Characteristic %X: %@", (int)u64(ch.UUID), ch.value];
            break;
    }
}
         
#pragma mark - Utilities


         
@end
