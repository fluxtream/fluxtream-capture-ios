
#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "BTPhotoUploader.h"
#import "BTPhotoAsset.h"

@interface BTPhotosViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) ALAssetsLibrary *library;
@property (strong, nonatomic) ALAssetsGroup *assetsGroup;
@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;
@property (strong, nonatomic) UIImage *selectedImage;
@property (strong, nonatomic) NSString *selectedImageDate;
@property (strong, nonatomic) BTPhotoAsset *selectedPhotoAsset;

@property (assign) BOOL isReloading;

@end
