
#import "BTPhotoDetailViewController.h"
#import "BTPhotoDetailCommentViewController.h"
#import "BTPhotoUploader.h"
#import "BTPhotoMetadataRequest.h"
#import "BTPhotoTagsForUserRequest.h"
#import <QuartzCore/QuartzCore.h>

@interface BTPhotoDetailViewController ()

@end

@implementation BTPhotoDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        //
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _metadataView.layer.shadowColor = [[UIColor darkGrayColor] CGColor];
    _metadataView.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    _metadataView.layer.shadowOpacity = 1.0f;
    _metadataView.layer.shadowRadius = 1.0f;
    
	_imageView.image = _image;
    _metadataView.text = [self captionWithTags:_photoAsset.tags comment:_photoAsset.comment];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setPhotoDate:nil];
    [self setMetadataView:nil];
    [super viewDidUnload];
}

- (NSString *)captionWithTags:(NSString *)tags comment:(NSString *)comment
{
    NSString *annotation = @"";
    
    if (![tags isEqual: @""]) {
        annotation = [annotation stringByAppendingString:[NSString stringWithFormat:@"Tags\n%@\n\n", tags]];
    }
    
    if (![comment isEqual:@""]) {
        annotation = [annotation stringByAppendingString:[NSString stringWithFormat:@"Comment\n%@", comment]];
    }
    
    return annotation;
}

#pragma mark - Storyboards

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"commentSegue"]) {
        BTPhotoDetailCommentViewController *commentViewController = [segue destinationViewController];
        [commentViewController setDelegate:self];
        commentViewController.comment = _photoAsset.comment;
        commentViewController.tags = _photoAsset.tags;
    }
}

#pragma mark - Comment View Delegate

- (void)updateAnnotationsWithComment:(NSString *)comment tags:(NSString *)tags
{
    [_photoAsset setComment:comment];
    [_photoAsset setTags:tags];
    BTPhotoUploader *photoUploader = [BTPhotoUploader sharedPhotoUploader];
    [photoUploader updateAnnotationsForAsset:_photoAsset];

    _metadataView.text = [self captionWithTags:tags comment:comment];
    [_metadataView setNeedsDisplay];
}

@end
