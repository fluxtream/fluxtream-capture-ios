/*
     File: HeartRateMonitorAppDelegate.m
 Abstract: Implementatin of Heart Rate Monitor app using Bluetooth Low Energy (LE) Heart Rate Service. This app demonstrats the use of CoreBluetooth APIs for LE devices.
  Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "HeartRateMonitorAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

@implementation HeartRateMonitorAppDelegate

@synthesize window;
@synthesize heartView;
@synthesize scanSheet;
@synthesize arrayController;
@synthesize pulseTracker;
@synthesize heartRateMonitors;


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.heartRateMonitors = [NSMutableArray array];
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:0.];
    [self.heartView layer].position = CGPointMake( [[self.heartView layer] frame].size.width / 2, [[self.heartView layer] frame].size.height / 2 );
    [self.heartView layer].anchorPoint = CGPointMake(0.5, 0.5);
    [NSAnimationContext endGrouping];
    self.pulseTracker = [[BTPulseTracker alloc] init];
    self.pulseTracker.delegate = self;
}


/*
 Disconnect peripheral when application terminate 
*/
- (void) applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"applicationWillTerminate");
    [self.pulseTracker disconnect];
}

#pragma mark - Scan sheet methods

/* 
 Open scan sheet to discover heart rate peripherals if it is LE capable hardware 
*/
- (IBAction)openScanSheet:(id)sender 
{
    if([self.pulseTracker isLECapableHardware])
    {
        //autoConnect = TRUE;
        //self.arrayController = [[NSArrayController alloc] init];  // work to clear it?
        [self.arrayController removeObjects:self.heartRateMonitors];
        [NSApp beginSheet:self.scanSheet modalForWindow:self.window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
        [self.pulseTracker startScan];
    }
}

/*
 Close scan sheet once device is selected
*/
- (IBAction)closeScanSheet:(id)sender 
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertDefaultReturn];
    [self.scanSheet orderOut:self];    
}

/*
 Close scan sheet without choosing any device
*/
- (IBAction)cancelScanSheet:(id)sender 
{
    [NSApp endSheet:self.scanSheet returnCode:NSAlertAlternateReturn];
    [self.scanSheet orderOut:self];
}

/* 
 This method is called when Scan sheet is closed. Initiate connection to selected heart rate peripheral
*/
- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo 
{
    [self.pulseTracker stopScan];
    if( returnCode == NSAlertDefaultReturn )
    {
        NSIndexSet *indexes = [self.arrayController selectionIndexes];
        if ([indexes count] != 0) 
        {
            NSUInteger anIndex = [indexes firstIndex];
            [self.pulseTracker connectToPeripheralAtIndex:anIndex];
            [indicatorButton setHidden:FALSE];
            [progressIndicator setHidden:FALSE];
            [progressIndicator startAnimation:self];
            [connectButton setTitle:@"Cancel"];
        }
    }
}

#pragma mark - Connect Button

/*
 This method is called when connect button pressed and it takes appropriate actions depending on device connection state
 */
- (IBAction)connectButtonPressed:(id)sender
{
    if(self.pulseTracker.connected)
        [self.pulseTracker disconnect];
    else if(self.pulseTracker.connecting) {
        [self.pulseTracker disconnect];
        [indicatorButton setHidden:TRUE];
        [progressIndicator setHidden:TRUE];
        [progressIndicator stopAnimation:self];
        [connectButton setTitle:@"Connect"];
        [self openScanSheet:nil];
    }
    else
        [self openScanSheet:nil];
}

#pragma mark - BTPulseTrackerDelegate methods

- (void)onPulseTrackerScanResultsChanged:(BTPulseTracker *)aTracker {
    [self.arrayController rearrangeObjects];
}

- (void)onPulseTrackerConnectionStart:(BTPulseTracker *)aTracker {
    [indicatorButton setHidden:FALSE];
    [progressIndicator setHidden:FALSE];
    [progressIndicator startAnimation:self];
    [connectButton setTitle:@"Cancel"];
}

- (void)onPulseTrackerConnected:(BTPulseTracker *)aTracker {
    [connectButton setTitle:@"Disconnect"];
    [indicatorButton setHidden:TRUE];
    [progressIndicator setHidden:TRUE];
    [progressIndicator stopAnimation:self];
}

- (void)onPulseTrackerDisconnected:(BTPulseTracker *)aTracker {
    [connectButton setTitle:@"Connect"];
}

- (void)onPulseTrackerFailedToConnect:(BTPulseTracker *)aTracker {
    [connectButton setTitle:@"Connect"];
}

- (void)onPulseTrackerNoBluetooth:(BTPulseTracker *)aTracker reason:(NSString *)reason {
    [self cancelScanSheet:nil];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:reason];
    [alert addButtonWithTitle:@"OK"];
    [alert setIcon:[[NSImage alloc] initWithContentsOfFile:@"AppIcon"]];
    [alert beginSheetModalForWindow:[self window] modalDelegate:self didEndSelector:nil contextInfo:nil];
}


/*
 Update pulse UI
 */
- (void)onPulse:(BTPulseTracker *)aTracker {
    float PULSESCALE = 1.2;
    float PULSEDURATION = 0.2;

    CABasicAnimation *pulseAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    pulseAnimation.toValue = [NSNumber numberWithFloat:PULSESCALE];
    pulseAnimation.fromValue = [NSNumber numberWithFloat:1.0];
    
    pulseAnimation.duration = PULSEDURATION;
    pulseAnimation.repeatCount = 1;
    pulseAnimation.autoreverses = YES;
    pulseAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    [[heartView layer] addAnimation:pulseAnimation forKey:@"scale"];
}


@end
