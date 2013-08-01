//
//  BTSettingsViewController.m
//  Stetho
//
//  Created by Rich Henderson on 1/7/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTSettingsViewController.h"
#import "BTPhoneTracker.h"
#import "BTAppDelegate.h"
#import "Constants.h"

#define kPhotosToBeUploaded 1

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
    
    _panoUploadSwitch = [[UISwitch alloc] init];
    [_panoUploadSwitch setTag:200];
    [_panoUploadSwitch addTarget:self action:@selector(updateFromUI:) forControlEvents:UIControlEventValueChanged];
    [_panoUploadSwitch addTarget:self action:@selector(orientationSettingsChanged:) forControlEvents:UIControlEventValueChanged];
    [_panoUploadCell setAccessoryView:_panoUploadSwitch];
    [_panoUploadSwitch setOn:[defaults boolForKey:DEFAULTS_PHOTO_UPLOAD_ALL_PANOS]];
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
    [defaults setBool:_panoUploadSwitch.isOn forKey:DEFAULTS_PHOTO_UPLOAD_ALL_PANOS];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    BTPhoneTracker *phoneTracker = [(BTAppDelegate *)[[UIApplication sharedApplication] delegate] phoneTracker];
    [self updateUploaderFromUI:phoneTracker.batteryUploader];
    [self updateUploaderFromUI:phoneTracker.timeZoneUploader];
    [self updateUploaderFromUI:phoneTracker.appStatsUploader];
    [self updateUploaderFromUI:phoneTracker.locationUploader];
    [self updateUploaderFromUI:phoneTracker.motionUploader];

    phoneTracker.recordBatteryEnabled = false;
    phoneTracker.recordAppStatsEnabled = false;
    phoneTracker.recordLocationEnabled = false;
    phoneTracker.recordMotionEnabled = false;
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
