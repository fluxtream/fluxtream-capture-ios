//
//  BTAppDelegate.h
//  Stetho
//
//  Created by Nick Winter on 10/20/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "Logger.h"
#import "BTFirstViewController.h"
#import "BTPhoneTracker.h"
#import "BTPulseTracker.h"
#import "BTPhotoUploader.h"

@interface BTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (weak) BTFirstViewController *firstViewController;
@property (strong) BTPulseTracker *pulseTracker;
@property (strong) BTPhoneTracker *phoneTracker;
@property (strong) BTPhotoUploader *photoUploader;
@property (readonly) Logger *logger;

- (void)selectSettingsTab;

@end
