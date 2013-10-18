//
//  BTPhotoDetailCommentViewController.m
//  Stetho
//
//  Created by Rich Henderson on 2/27/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTPhotoDetailCommentViewController.h"
#import "BTPhotoDetailViewController.h"

@interface BTPhotoDetailCommentViewController ()

@end

@implementation BTPhotoDetailCommentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [_tagEntryView setText:_tags];
    [_commentEntryView setText:_comment];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setSaveButton:nil];
    [self setCancelButton:nil];
    [super viewDidUnload];
}



#pragma mark - UITextViewDelegate methods

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
}

- (IBAction)saveButtonTapped:(id)sender
{
        _comment = [NSString stringWithString:_commentEntryView.text];
        _tags = [NSString stringWithString:_tagEntryView.text];
    
    [_delegate updateAnnotationsWithComment:_comment tags:_tags];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
