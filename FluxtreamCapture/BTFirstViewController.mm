//
//  BTFirstViewController.m
//  Stetho
//
//  Created by Nick Winter on 10/20/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import "BTFirstViewController.h"
#import <AudioToolbox/AudioToolbox.h>

#include "Utils.h"
#include "NSUtils.h"

#include "Constants.h"

#import "BTAppDelegate.h"

@interface BTFirstViewController ()
@property (assign) SystemSoundID heartbeatS1Sound;
@property (assign) SystemSoundID heartbeatS2Sound;

- (void)onPulse:(NSNotification *)note;
- (void)onHRDataReceived:(NSNotification *)note;

@end

@implementation BTFirstViewController
@synthesize heartRateLabel;
@synthesize variabilityLabel;
@synthesize heartImage;
@synthesize heartbeatS1Sound;
@synthesize heartbeatS2Sound;

#pragma mark - View lifecycle

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
#ifdef DEBUG
    const char *buildType = "debug";
#else
    const char *buildType = "release";
#endif
    
    
    NSString * version = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];
    NSString * build = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *)kCFBundleVersionKey];
    
    self.buildLabel.text = [NSString stringWithFormat:@"Version %@ %s build %@ %s", version, buildType, build, __DATE__];
    
	// Do any additional setup after loading the view, typically from a nib.
    NSString *soundPathS1 = [[NSBundle mainBundle] pathForResource:@"heartbeat_s1" ofType:@"aiff"];
    NSString *soundPathS2 = [[NSBundle mainBundle] pathForResource:@"heartbeat_s2" ofType:@"aiff"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPathS1], &heartbeatS1Sound);
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath:soundPathS2], &heartbeatS2Sound);
    
    BTAppDelegate *appDelegate = (BTAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.firstViewController = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:DEFAULTS_FIRSTRUN] == YES) {
        [defaults setBool:NO forKey:DEFAULTS_FIRSTRUN];
        [defaults synchronize];
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                          message:@"Please enter your Fluxtream username and password (register at fluxtream.com)"
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        
        [appDelegate selectSettingsTab];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPulse:) name:BT_NOTIFICATION_PULSE object:[appDelegate pulseTracker]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onHRDataReceived:) name:BT_NOTIFICATION_HR_DATA object:[appDelegate pulseTracker]];

    // TODO(rsargent) subscribe to auth failed, queued data
    // pop up alert with UIAlertView
    
    TextViewLogger *logger = [[TextViewLogger alloc] init];
    logger.maxDisplayedVerbosity = kLogNormal;
    logger.textView = self.hrLogView;
    
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    pulseTracker.logger = logger;
    pulseTracker.uploader.username = [defaults objectForKey:DEFAULTS_USERNAME];
    pulseTracker.uploader.password = [defaults objectForKey:DEFAULTS_PASSWORD];
    pulseTracker.uploader.serverPrefix = [defaults objectForKey:DEFAULTS_SERVER];
    
    hrStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateHRStatus) userInfo:nil repeats:YES];
    uploadStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUploadStatus) userInfo:nil repeats:YES];
}


- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    AudioServicesDisposeSystemSoundID(heartbeatS1Sound);
    AudioServicesDisposeSystemSoundID(heartbeatS2Sound);
    [self setHeartRateLabel:nil];
    [self setVariabilityLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Pulse display

- (void)onPulse:(NSNotification *)note {
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    double PULSESCALE = 1.5;
    double PULSEDURATION = 0.2 * 60.0 / pulseTracker.heartRate;
    
    [UIView animateWithDuration:PULSEDURATION delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        if ([defaults boolForKey:DEFAULTS_HEARTBEAT_SOUND] == YES) AudioServicesPlaySystemSound(heartbeatS1Sound);
        self.heartImage.transform = CGAffineTransformMakeScale(PULSESCALE, PULSESCALE);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:PULSEDURATION delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if ([defaults boolForKey:DEFAULTS_HEARTBEAT_SOUND] == YES) AudioServicesPlaySystemSound(heartbeatS2Sound);
            self.heartImage.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
}

- (void)onHRDataReceived:(NSNotification *)note {
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    self.heartRateLabel.text = [NSString stringWithFormat:@"%.0f BPM", pulseTracker.heartRate];
    self.variabilityLabel.text = [NSString stringWithFormat:@"%d ms", (int) (0.5 + pulseTracker.r2r * 1000)];
}

- (void)updateHRStatus {
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    self.hrConnectionStatusLabel.text = pulseTracker.connectionStatusWithDuration;
    self.hrDataStatusLabel.text = pulseTracker.receivedStatusWithDuration;
}

- (void)updateUploadStatus {
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    self.hrUploadStatusLabel.text = [pulseTracker.uploader getStatus];
}


@end
