//
//  BTFirstViewController.h
//  Stetho
//
//  Created by Nick Winter on 10/20/12.
//  Copyright (c) 2012 BodyTrack. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextViewLogger.h"

@interface BTFirstViewController : UIViewController
{
    NSTimer *hrStatusTimer;
    NSTimer *uploadStatusTimer;
}
@property (weak, nonatomic) IBOutlet UILabel *heartRateLabel;
@property (weak, nonatomic) IBOutlet UILabel *variabilityLabel;
@property (weak, nonatomic) IBOutlet UIImageView *heartImage;
@property (weak, nonatomic) IBOutlet UILabel *hrConnectionStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *hrDataStatusLabel;
@property (weak, nonatomic) IBOutlet UILabel *hrUploadStatusLabel;
@property (weak, nonatomic) IBOutlet UITextView *hrLogView;
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;

@end
