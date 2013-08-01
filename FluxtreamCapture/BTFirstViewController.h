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
@property (weak, nonatomic) IBOutlet UILabel *buildLabel;

@end
