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

// Automatic Photo Upload
@property (strong, nonatomic) IBOutlet UITableViewCell *panoUploadCell;
@property (strong, nonatomic) UISwitch *panoUploadSwitch;

@property (assign) ALAssetOrientation orientationForUpload;
@property (strong, nonatomic) NSArray *photosForUpload;

- (IBAction)orientationSettingsChanged:(id)sender;

@end
