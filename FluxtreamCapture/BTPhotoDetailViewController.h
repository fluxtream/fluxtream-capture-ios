
#import <UIKit/UIKit.h>
#import "BTPhotoAsset.h"

@interface BTPhotoDetailViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet UITextView *metadataView;
@property (strong, nonatomic) IBOutlet UINavigationItem *photoDate;
@property (strong) BTPhotoAsset *photoAsset;
@property (strong, nonatomic) id image;

- (void)updateAnnotationsWithComment:(NSString *)comment tags:(NSString *)tags;


@end
