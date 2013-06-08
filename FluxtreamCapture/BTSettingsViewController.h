//
//  BTSettingsViewController.h
//
//  Created by Rich Henderson on 2/11/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface BTSettingsViewController : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate>

// Settings tableview
// Login
@property (strong, nonatomic) IBOutlet UITableViewCell *usernameCell;
@property (strong, nonatomic) IBOutlet UITextField *username;
@property (strong, nonatomic) IBOutlet UITableViewCell *passwordCell;
@property (strong, nonatomic) IBOutlet UITextField *password;
@property (strong, nonatomic) IBOutlet UITableViewCell *serverCell;
@property (strong, nonatomic) IBOutlet UITextField *server;

// Capture
@property (strong, nonatomic) IBOutlet UITableViewCell *locationCell;
@property (strong, nonatomic) UISwitch *locationSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *motionCell;
@property (strong, nonatomic) UISwitch *motionSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *appStatsCell;
@property (strong, nonatomic) UISwitch *appStatsSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *recordHeartRateCell;
@property (strong, nonatomic) UISwitch *heartRateSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *heartbeatSoundCell;
@property (strong, nonatomic) UISwitch *heartbeatSoundSwitch;

// Automatic Photo Upload
@property (strong, nonatomic) IBOutlet UITableViewCell *portraitCell;
@property (strong, nonatomic) UISwitch *portraitUploadSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *upsideDownCell;
@property (strong, nonatomic) UISwitch *upsideDownUploadSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *landscapeLeftCell;
@property (strong, nonatomic) UISwitch *landscapeLeftUploadSwitch;
@property (strong, nonatomic) IBOutlet UITableViewCell *landscapeRightCell;
@property (strong, nonatomic) UISwitch *landscapeRightUploadSwitch;

@property (assign) ALAssetOrientation orientationForUpload;
@property (strong, nonatomic) NSArray *photosForUpload;

- (IBAction)orientationSettingsChanged:(id)sender;
- (IBAction)serverWillChange:(id)sender;

@end
