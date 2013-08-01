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

@implementation BTFirstViewController

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
    
    BTAppDelegate *appDelegate = (BTAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.firstViewController = self;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:DEFAULTS_FIRSTRUN] == YES) {
        [defaults setBool:NO forKey:DEFAULTS_FIRSTRUN];
        [defaults synchronize];
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Welcome"
                                                          message:@"Please enter your GigaPan username and password (register at gigapan.com)"
                                                         delegate:self
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [message show];
        
        [appDelegate selectSettingsTab];
    }

    // TODO(rsargent) subscribe to auth failed, queued data
    // pop up alert with UIAlertView
    
    TextViewLogger *logger = [[TextViewLogger alloc] init];
    logger.maxDisplayedVerbosity = kLogNormal;
    
    hrStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateHRStatus) userInfo:nil repeats:YES];
    uploadStatusTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateUploadStatus) userInfo:nil repeats:YES];
}


- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

