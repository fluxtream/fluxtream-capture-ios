//
//  BTPhotoDetailCommentViewController.h
//  Stetho
//
//  Created by Rich Henderson on 2/27/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BTPhotoDetailCommentViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, assign) id delegate;

@property (strong, nonatomic) IBOutlet UITextField *tagEntryView;
@property (strong, nonatomic) IBOutlet UITextView *commentEntryView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;

@property NSString *comment;
@property NSString *tags;

- (IBAction)saveButtonTapped:(id)sender;
- (IBAction)cancelButtonTapped:(id)sender;

@end
