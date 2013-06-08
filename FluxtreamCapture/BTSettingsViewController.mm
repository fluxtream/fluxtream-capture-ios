//
//  BTSettingsViewController.m
//  Stetho
//
//  Created by Rich Henderson on 1/7/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTSettingsViewController.h"
#import "BTPulseTracker.h"
#import "BTPhoneTracker.h"
#import "BTAppDelegate.h"
#import "Constants.h"

#define kPhotosToBeUploaded 1
#define kServerWillChange   2

@interface BTSettingsViewController ()

@end

@implementation BTSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //
    }
    return self;
}

- (void)configureView
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [_username setText:[defaults objectForKey:DEFAULTS_USERNAME]];
    [_password setText:[defaults objectForKey:DEFAULTS_PASSWORD]];
    [_server setText:[defaults objectForKey:DEFAULTS_SERVER]];
    
    _locationSwitch = [[UISwitch alloc] init];
    [_locationSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_locationCell setAccessoryView:_locationSwitch];
    [_locationSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_LOCATION]];
    
    _motionSwitch = [[UISwitch alloc] init];
    [_motionSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_motionCell setAccessoryView:_motionSwitch];
    [_motionSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_MOTION]];
    
    _appStatsSwitch = [[UISwitch alloc] init];
    [_appStatsSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_appStatsCell setAccessoryView:_appStatsSwitch];
    [_appStatsSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_APP_STATS]];
    
    _heartRateSwitch = [[UISwitch alloc] init];
    [_heartRateSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_recordHeartRateCell setAccessoryView:_heartRateSwitch];
    [_heartRateSwitch setOn:[defaults boolForKey:DEFAULTS_RECORD_HEARTRATE]];
    
    _heartbeatSoundSwitch = [[UISwitch alloc] init];
    [_heartbeatSoundSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_heartbeatSoundCell setAccessoryView:_heartbeatSoundSwitch];
    [_heartbeatSoundSwitch setOn:[defaults boolForKey:DEFAULTS_HEARTBEAT_SOUND]];
    
    _portraitUploadSwitch = [[UISwitch alloc] init];
    [_portraitUploadSwitch setTag:200];
    [_portraitUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_portraitUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_portraitCell setAccessoryView:_portraitUploadSwitch];
    [_portraitUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_PORTRAIT]];
    
    _upsideDownUploadSwitch = [[UISwitch alloc] init];
    [_upsideDownUploadSwitch setTag:201];
    [_upsideDownUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_upsideDownUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_upsideDownCell setAccessoryView:_upsideDownUploadSwitch];
    [_upsideDownUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_UPSIDE_DOWN]];
    
    _landscapeLeftUploadSwitch = [[UISwitch alloc] init];
    [_landscapeLeftUploadSwitch setTag:202];
    [_landscapeLeftUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_landscapeLeftUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_landscapeLeftCell setAccessoryView:_landscapeLeftUploadSwitch];
    [_landscapeLeftUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_LEFT]];
    
    _landscapeRightUploadSwitch = [[UISwitch alloc] init];
    [_landscapeRightUploadSwitch setTag:203];
    [_landscapeRightUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_landscapeRightUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_landscapeRightCell setAccessoryView:_landscapeRightUploadSwitch];
    [_landscapeRightUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_RIGHT]];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(photosToBeUploaded:) name:BT_NOTIFICATION_PHOTOS_TO_BE_UPLOADED object:nil];
	[self configureView];
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


- (void)updateUploaderFromUI:(FluxtreamUploaderObjc*)uploader {
    if (![uploader.username isEqualToString: _username.text] ||
        ![uploader.password isEqualToString: _password.text]) {
        uploader.username = _username.text;
        uploader.password = _password.text;
        [uploader uploadNow];
    }
}

- (IBAction)updateFromUI:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_username.text forKey:DEFAULTS_USERNAME];
    [defaults setObject:_password.text forKey:DEFAULTS_PASSWORD];
    [defaults setObject:_server.text forKey:DEFAULTS_SERVER];
    [defaults setBool:_locationSwitch.isOn forKey:DEFAULTS_RECORD_LOCATION];
    [defaults setBool:_motionSwitch.isOn forKey:DEFAULTS_RECORD_MOTION];
    [defaults setBool:_appStatsSwitch.isOn forKey:DEFAULTS_RECORD_APP_STATS];
    [defaults setBool:_heartRateSwitch.isOn forKey:DEFAULTS_RECORD_HEARTRATE];
    [defaults setBool:_heartbeatSoundSwitch.isOn forKey:DEFAULTS_HEARTBEAT_SOUND];
    [defaults setBool:_portraitUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_PORTRAIT];
    [defaults setBool:_upsideDownUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_UPSIDE_DOWN];
    [defaults setBool:_landscapeLeftUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_LEFT];
    [defaults setBool:_landscapeRightUploadSwitch.isOn forKey:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_RIGHT];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BTPulseTracker *pulseTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] pulseTracker];
    [self updateUploaderFromUI:pulseTracker.uploader];
    
    BTPhoneTracker *phoneTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] phoneTracker];
    [self updateUploaderFromUI:phoneTracker.batteryUploader];
    [self updateUploaderFromUI:phoneTracker.timeZoneUploader];
    [self updateUploaderFromUI:phoneTracker.appStatsUploader];
    [self updateUploaderFromUI:phoneTracker.locationUploader];
    [self updateUploaderFromUI:phoneTracker.motionUploader];

    phoneTracker.recordBatteryEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
    phoneTracker.recordAppStatsEnabled = [defaults boolForKey:DEFAULTS_RECORD_APP_STATS];
    phoneTracker.recordLocationEnabled = [defaults boolForKey:DEFAULTS_RECORD_LOCATION];
    phoneTracker.recordMotionEnabled = [defaults boolForKey:DEFAULTS_RECORD_MOTION];
}


- (IBAction)orientationSettingsChanged:(id)sender
{
    if ([sender isOn]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:[NSDate date] forKey:DEFAULTS_PHOTO_ORIENTATION_SETTINGS_CHANGED];
        
        BTPhotoUploader *photoUploader = [BTPhotoUploader sharedPhotoUploader];
        ALAssetOrientation orientation;
        switch ([sender tag]) {
            case 200: // Portrait
                orientation = ALAssetOrientationRight;
                break;
                
            case 201: // Upside down
                orientation = ALAssetOrientationLeft;
                break;
                
            case 202: // Landscape left
                orientation = ALAssetOrientationDown;
                break;
                
            case 203: // Landscape right
                orientation = ALAssetOrientationUp;
                break;
                
            default:
                NSLog(@"orientation not handled");
                orientation = ALAssetOrientationUp;
                break;
        }
        
        [photoUploader unuploadedPhotosWithOrientation:orientation];
    }
}

- (IBAction)serverWillChange:(id)sender
{
    NSString *messageBody = @"You shouldn't usually have to change this setting. Are you sure you want to proceed?";
    
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Fluxtream Server"
                                                      message:messageBody
                                                     delegate:self
                                            cancelButtonTitle:@"Cancel"
                                            otherButtonTitles:@"Proceed", nil];
    message.tag = kServerWillChange;
    [message show];
}

#pragma mark - Photo uploader notifications

- (void)photosToBeUploaded:(NSNotification *)notification
{
    _photosForUpload = [notification.userInfo objectForKey:@"urls"];
    
    if ([_photosForUpload count] > 0) {
        _orientationForUpload = (ALAssetOrientation)[[notification.userInfo objectForKey:@"orientation"] intValue];
        NSString *messageBody = [NSString stringWithFormat:@"You have %@ existing photos with this orientation. Upload them now?", [notification.userInfo objectForKey:@"count"]];
        
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Photo Upload"
                                                          message:messageBody
                                                         delegate:self
                                                cancelButtonTitle:@"No"
                                                otherButtonTitles:@"Upload", nil];
        message.tag = kPhotosToBeUploaded;
        [message show];
    }

}

#pragma mark - UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // check the tag property on the alertview to determine which of the two possible UIAlertViews we are dealing with
    
    switch (alertView.tag) {
        case kPhotosToBeUploaded:
            if (buttonIndex == 1) {
                [[BTPhotoUploader sharedPhotoUploader] markPhotosForUpload:_photosForUpload];
            } else {
                _photosForUpload = nil;
            }
            break;
            
        case kServerWillChange:
            if (buttonIndex == 1) {
                // the user wants to edit the server - proceed
            } else {
                // leave it
                [_server resignFirstResponder];
            }
            
        default:
            break;
    }

}


#pragma mark - UITextField delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self updateFromUI:self];
    return YES;
}

@end
