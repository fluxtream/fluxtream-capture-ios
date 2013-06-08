#import "BTPhotosViewController.h"
#import "BTPhotoDetailViewController.h"
#import "BTPhotoUploader.h"
#import "BTPhotoAsset.h"
#import "BTCommentBadge.h"
#import "Constants.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>

@interface BTPhotosViewController ()

@end

@implementation BTPhotosViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _library = [[ALAssetsLibrary alloc] init];
    _assetsGroup = [[ALAssetsGroup alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(photoUploadSucceeded:)
                                                 name:BT_NOTIFICATION_PHOTO_UPLOAD_SUCCEEDED object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationForegrounded:)
                                                 name:BT_NOTIFICATION_APP_FOREGROUNDED object:nil];
    
    if (!_isReloading) {
        _isReloading = YES;
        [self refreshCollectionView];
        
        // Scroll to the most recent photos
        dispatch_async(dispatch_get_main_queue(), ^{
            NSIndexPath *path = [NSIndexPath indexPathForRow:([[[BTPhotoUploader sharedPhotoUploader] photos] count] - 1) inSection:0];
            [_collectionView scrollToItemAtIndexPath:path atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        });
    }

    // Register collection view cell for reuse
    UINib *cellNib = [UINib nibWithNibName:@"BTPhotoCell" bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:@"BTPhotoCell"];
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setItemSize:CGSizeMake(100, 132)];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionVertical];
    [self.collectionView setCollectionViewLayout:flowLayout];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self refreshCollectionView];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)button1Tapped:(UIButton *)sender
{
    UICollectionViewCell *cell = (UICollectionViewCell*)sender.superview.superview;
    
    UIActivityIndicatorView *button1ActivityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:101];
    [button1ActivityIndicator startAnimating];
    [sender setHidden:YES];
    
    NSIndexPath *path = [self.collectionView indexPathForCell:cell];
    
    BTPhotoAsset *assetToUpload = [[[BTPhotoUploader sharedPhotoUploader] photos] objectAtIndex:path.row];
    [assetToUpload setUploadStatus:@"1"];
    [[[BTPhotoUploader sharedPhotoUploader] photos] replaceObjectAtIndex:path.row withObject:assetToUpload];
    [[BTPhotoUploader sharedPhotoUploader] uploadNow];
}


#pragma mark - UICollectionView Data Source methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"BTPhotoCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:cellIdentifier forIndexPath:indexPath];
    
    BTPhotoAsset *photoAsset = [[[BTPhotoUploader sharedPhotoUploader] photos] objectAtIndex:indexPath.row];
    
    UIButton *button1 = (UIButton *)[cell viewWithTag:100];
    [button1 addTarget:self action:@selector(button1Tapped:) forControlEvents:UIControlEventTouchUpInside];
    UIActivityIndicatorView *button1ActivityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:101];
    
    if ([photoAsset.uploadStatus isEqual:@"1"]) {
        // we want to upload
        [button1 setHidden:YES];
        [button1ActivityIndicator startAnimating];
    } else if ([photoAsset.uploadStatus isEqual:@"0"]) {
        // don't upload
        [button1 setTitle:@"Upload" forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [button1 setBackgroundColor:[UIColor colorWithRed:229.0f/255.0f green:229.0f/255.0f blue:229.0f/255.0f alpha:1.0]];
        CALayer *btnLayer = [button1 layer];
        [btnLayer setMasksToBounds:YES];
        [btnLayer setCornerRadius:5.0f];
        [btnLayer setBorderWidth:1.0f];
        [btnLayer setBorderColor:[[UIColor lightGrayColor] CGColor]];
        [button1 setHidden:NO];
        [button1ActivityIndicator stopAnimating];
    } else if (photoAsset.uploadStatus != nil) {
        // already uploaded
        [button1 setTitle:@"Uploaded" forState:UIControlStateNormal];
        [button1 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
        [button1 setBackgroundColor:[UIColor colorWithRed:217.0f/255.0f green:234.0f/255.0f blue:211.0f/255.0f alpha:1.0]];
        CALayer *btnLayer = [button1 layer];
        [btnLayer setMasksToBounds:YES];
        [btnLayer setCornerRadius:5.0f];
        [btnLayer setBorderWidth:1.0f];
        [btnLayer setBorderColor:[[UIColor colorWithRed:169.0f/255.0f green:221.0f/255.0f blue:151.0f/255.0f alpha:1.0] CGColor]];
        [button1 setHidden:NO];
        [button1ActivityIndicator stopAnimating];
    } else {
        // should never happen
        NSLog(@"Photo uploadStatus was nil!");
    }
    
    BTCommentBadge *commentBadge = (BTCommentBadge *)[cell viewWithTag:400];
    if ([photoAsset.comment isEqual:@""] && [photoAsset.tags isEqual:@""]) {
        [commentBadge setHidden:YES];
    } else {
        [commentBadge setHidden:NO];
    }
    
    [_library assetForURL:[NSURL URLWithString:photoAsset.assetURL] resultBlock:^(ALAsset *asset) {        
        UIImageView *cellImageView = (UIImageView *)[cell viewWithTag:300];
        UIImage *thumb = [UIImage imageWithCGImage:[asset thumbnail]];
        [cellImageView setImage:thumb];
    } failureBlock:^(NSError *error) {
        NSLog(@"error fetching asset: %@", error);
    }];
    
    return cell;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return [[[BTPhotoUploader sharedPhotoUploader] photos] count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (void)refreshCollectionView
{
    NSLog(@"Refresh photos collection view");
    [_collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
    _isReloading = NO;
}


#pragma mark - UICollectionView Delegate methods

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    BTPhotoAsset *photoAsset = [[[BTPhotoUploader sharedPhotoUploader] photos] objectAtIndex:indexPath.row];
    [_library assetForURL:[NSURL URLWithString:photoAsset.assetURL] resultBlock:^(ALAsset *asset) {
        CGImageRef assetImage = [[asset defaultRepresentation] fullScreenImage];
        _selectedImage = [UIImage imageWithCGImage:assetImage];
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterShortStyle];
        [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
        _selectedImageDate = [dateFormatter stringFromDate:[asset valueForProperty:@"ALAssetPropertyDate"]];
        _selectedPhotoAsset = photoAsset;
        
        [self performSegueWithIdentifier: @"detailSegue" sender:self];
    } failureBlock:^(NSError *error) {
        NSLog(@"error fetching asset: %@", error);
    }];
}


#pragma mark - Notifications from BTPhotoUploader

- (void)photoUploadSucceeded:(NSNotification *)notification
{
    NSNumber *i = [notification.userInfo objectForKey:@"index"];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[i unsignedIntegerValue] inSection:0];
    
    UICollectionViewCell *cell = [_collectionView cellForItemAtIndexPath:indexPath];
    
    UIButton *button1 = (UIButton *)[cell viewWithTag:100];
    [button1 setTitle:@"Uploaded" forState:UIControlStateNormal];
    [button1 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [button1 setBackgroundColor:[UIColor colorWithRed:217.0f/255.0f green:234.0f/255.0f blue:211.0f/255.0f alpha:1.0]];
    CALayer *btnLayer = [button1 layer];
    [btnLayer setMasksToBounds:YES];
    [btnLayer setCornerRadius:5.0f];
    [btnLayer setBorderWidth:1.0f];
    [btnLayer setBorderColor:[[UIColor colorWithRed:169.0f/255.0f green:221.0f/255.0f blue:151.0f/255.0f alpha:1.0] CGColor]];
    [button1 setHidden:NO];

    UIActivityIndicatorView *button1ActivityIndicator = (UIActivityIndicatorView *)[cell viewWithTag:101];
    [button1ActivityIndicator stopAnimating];
}


#pragma mark - ALAssetsLibraryChangedNotification

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    if (!_isReloading) {
        _isReloading = YES;
        [self refreshCollectionView];
    }
}

- (void)applicationForegrounded:(NSNotification *)notification
{
    [self refreshCollectionView];
}


#pragma mark - Storyboards

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([[segue identifier] isEqualToString:@"detailSegue"]) {
        BTPhotoDetailViewController *detailViewController = [segue destinationViewController];

        detailViewController.image = _selectedImage;
        detailViewController.photoDate.title = _selectedImageDate;
        detailViewController.photoAsset = _selectedPhotoAsset;
    }
}
@end
