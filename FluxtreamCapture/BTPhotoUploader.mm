//
//  BTPhotoUploader.m
//  Stetho
//
//  Created by Rich Henderson on 2/4/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTPhotoUploader.h"
#import "BTPhotoAsset.h"
#import "BTPhotoImageUploadRequest.h"
#import "BTPhotoMetadataUploadRequest.h"
#import "Constants.h"
#import "NSUtils.h"


@implementation BTPhotoUploader

static NSString *const kBoundary = @"b0uNd4rYb0uNd4rYaehrtiffegbib";

+ (id)sharedPhotoUploader
{
    static BTPhotoUploader *sharedPhotoUploader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedPhotoUploader = [[self alloc] init];
    });
    
    return sharedPhotoUploader;
}


- (void)unuploadedPhotosWithOrientation:(ALAssetOrientation)requestedOrientation
{
    NSMutableArray *orientedPhotos = [[NSMutableArray alloc] init];
    
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result != NULL) {
            ALAssetOrientation orientation = (ALAssetOrientation)[[result valueForProperty:@"ALAssetPropertyOrientation"] intValue];
            
			if (orientation == requestedOrientation) {
				[orientedPhotos addObject:[[[result defaultRepresentation] url] absoluteString]];
			}
        }
    };
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
            
            NSArray *unuploadedPhotos = [self removeUploadedPhotosFromArray:orientedPhotos];
            
            if (unuploadedPhotos) {
                [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_PHOTOS_TO_BE_UPLOADED object:self userInfo:@{@"count":[NSNumber numberWithInt:[unuploadedPhotos count]], @"orientation":[NSNumber numberWithInt:requestedOrientation], @"urls":[NSArray arrayWithArray:unuploadedPhotos]}];
            }
        };
    };
    
    [_library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:assetGroupEnumerator failureBlock: ^(NSError *error) {
        NSLog(@"getting unuploaded photos with orientation failed");
    }];
}

- (NSArray *)removeUploadedPhotosFromArray:(NSMutableArray *)orientedPhotos
{
    NSMutableArray *unuploadedPhotos = [[NSMutableArray alloc] init];
    
    for (NSString *url in orientedPhotos) {
        for (BTPhotoAsset *oldPhoto in _photos) {
            if ([url isEqualToString:oldPhoto.assetURL]) {
                if (![@"0" isEqualToString:oldPhoto.uploadStatus]) {
                    // forget it
                } else {
                    [unuploadedPhotos addObject:url];
                }
            }
        }
    }
    return unuploadedPhotos;
}


- (void)markPhotosForUpload:(NSArray *)urls
{
    for (NSString *url in urls) {
        for (BTPhotoAsset *oldPhoto in _photos) {
            if ([oldPhoto.assetURL isEqualToString:url] && [oldPhoto.uploadStatus isEqualToString:@"0"]) {
                [oldPhoto setUploadStatus:@"1"];
            }
        }
    }
    [self uploadNow];
}

- (id)init
{
    if ((self = [super init])) {
        _isUploading = NO;
        _library = [[ALAssetsLibrary alloc] init];
        
        // load the saved photo roll details if they exist
        _oldPhotos = [NSKeyedUnarchiver unarchiveObjectWithFile:[self photosArrayArchivePath]];
        if (!_oldPhotos) {
            NSLog(@"Couldn't load photos.archive on startup");
        }
        
        [self discoverPhotos];
       
        [[NSOperationQueue mainQueue] addOperationWithBlock: ^{
            _uploadKickTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(uploadNow) userInfo:nil repeats:YES];
            [_uploadKickTimer fire];
        }];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsLibraryChanged:) name:ALAssetsLibraryChangedNotification object:nil];
    }
    
    return self;
}

- (void)reconcileCameraRoll
{
    if (!_oldPhotos) {
        NSLog(@"no photos.archive found");
    } else {
        NSMutableArray *cameraRollCopy = [NSMutableArray arrayWithArray:_photos];
        for (BTPhotoAsset *photo in cameraRollCopy) {
            for (BTPhotoAsset *oldPhoto in _oldPhotos) {
                if ([oldPhoto.assetURL isEqualToString:photo.assetURL]) {
                    if (oldPhoto.uploadStatus) {
                        photo.uploadStatus = oldPhoto.uploadStatus;
                        photo.facetID = oldPhoto.facetID;
                        photo.comment = oldPhoto.comment;
                        photo.tags = oldPhoto.tags;
                    } else {
                        NSLog(@"Saved upload status was nil: %@", oldPhoto.assetURL);
                    }
                    break;
                }
            }
        }
        
        _photos = [NSMutableArray arrayWithArray:cameraRollCopy];
    }

    _oldPhotos = [NSArray arrayWithArray:_photos];
    [self savePhotosArray];
    [self uploadNow];
}


- (void)discoverPhotos
{
    _discoveredPhotos = [[NSMutableArray alloc] init];
    
    void (^assetEnumerator)(ALAsset *, NSUInteger, BOOL *) = ^(ALAsset *result, NSUInteger index, BOOL *stop) {
        if (result != NULL) {            
            // check for orientation, set uploadStatus based on that
            NSNumber *orientationValue = [result valueForProperty:@"ALAssetPropertyOrientation"];
            int orientation = 0;
            if (orientationValue != nil) {
                orientation = (ALAssetOrientation)[orientationValue intValue];
            }
            
            switch (orientation) {
                case ALAssetOrientationUp:
                case ALAssetOrientationUpMirrored:
                    [self processAsset:result forOrientation:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_LEFT];
                    break;
                    
                case ALAssetOrientationDown:
                case ALAssetOrientationDownMirrored:
                    [self processAsset:result forOrientation:DEFAULTS_PHOTO_ORIENTATION_LANDSCAPE_RIGHT];
                    break;
                    
                case ALAssetOrientationLeft:
                case ALAssetOrientationLeftMirrored:
                    [self processAsset:result forOrientation:DEFAULTS_PHOTO_ORIENTATION_UPSIDE_DOWN];
                    break;
                    
                case ALAssetOrientationRight:
                case ALAssetOrientationRightMirrored:
                    [self processAsset:result forOrientation:DEFAULTS_PHOTO_ORIENTATION_PORTRAIT];
                    break;
                    
                default:
                    NSLog(@"** Unknown photo orientation! **");
                    break;
            }
        }
    };
    
    void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) {
        if (group != nil) {
            [group enumerateAssetsUsingBlock:assetEnumerator];
            _photos = [NSMutableArray arrayWithArray:_discoveredPhotos];
            [self reconcileCameraRoll];
            _isReloading = NO;
            };
    };
    
    [_library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:assetGroupEnumerator failureBlock: ^(NSError *error) {
        NSLog(@"discoverPhotos Failure");
    }];
}

- (void)processAsset:(ALAsset *)asset forOrientation:(NSString *)orientationKey
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL upload = [defaults boolForKey:orientationKey];
    NSString *status = [NSString stringWithFormat:@"%@", (upload ? @"1" : @"0")];
    NSDate *cutoffDate = [defaults objectForKey:DEFAULTS_PHOTO_ORIENTATION_SETTINGS_CHANGED];
    NSDate *assetDate = [asset valueForProperty:ALAssetPropertyDate];
    
    if ([assetDate compare:cutoffDate] == NSOrderedAscending) { // asset date is earlier than the last time the orientation settings were changed
        status = @"0"; // so don't mark it for upload
    }
    
    BTPhotoAsset *photoAsset = [[BTPhotoAsset alloc] initWithAssetURL:[[[asset defaultRepresentation] url] absoluteString] uploadStatus:status];
    [_discoveredPhotos addObject:photoAsset];
}

- (void)uploadNow
{
    if (_isUploading == YES) return;
    if ([_photos count] > 0) {
        _isUploading = YES;
        NSLog(@"photoUploader uploadNow");
        
        int i = [self photoIndexForUpload];

        if (i == NSNotFound) {
            NSLog(@"No photos marked for upload");
            _isUploading = NO;
        } else {
            BTPhotoAsset *photoAsset = [_photos objectAtIndex:i];
            [_library assetForURL:[NSURL URLWithString:photoAsset.assetURL] resultBlock:^(ALAsset *asset) {
                // force authentication
                NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                NSArray *cookies = [cookieStorage cookies];
                for (NSHTTPCookie *cookie in cookies) {
                    [cookieStorage deleteCookie:cookie];
                }
                
                NSURLRequest *request;
                
                if ([photoAsset.uploadStatus isEqual: @"1"]) {
                    NSLog(@"sending upload request for photo");
                    request = [BTPhotoImageUploadRequest uploadRequestForAsset:asset];
                } else {
                    NSLog(@"sending upload request for metadata");
                    request = [BTPhotoMetadataUploadRequest metadataUploadRequestForAsset:photoAsset];
                }
                
                NSLog(@"%@", request);
                
                [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {

                    if (error) {
                        NSLog(@"photo upload error code: %d", [error code]);
                        switch ([error code]) {
                            case NSURLErrorUserCancelledAuthentication:
                            case NSURLErrorUserAuthenticationRequired:
                            {
                                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Auth Error"
                                                                                  message:@"Check credentials in Settings tab"
                                                                                 delegate:self
                                                                        cancelButtonTitle:@"OK"
                                                                        otherButtonTitles:nil];
                                [message show];
                                [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_PHOTO_UPLOAD_AUTH_FAILED object:self];
                                break;
                            }
                            default:
                                [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_PHOTO_UPLOAD_NETWORK_ERROR object:self];
                                break;
                        }
                        _isUploading = NO;
                    } else {
                        int statusCode = [(NSHTTPURLResponse *) response statusCode];
                        NSLog(@"photo uploader got %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
                        NSLog(@"photo upload success: status %d", statusCode);
                        
                        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:nil error:&error];
                        
                        if ([photoAsset.uploadStatus isEqual:@"1"]) {
                            NSLog(@"returned from upload request for photo");
                            NSString *key = [[json objectForKey:@"payload"] objectForKey:@"key"];
                            photoAsset.uploadStatus = key;
                            NSString *facetID = [[json objectForKey:@"payload"] objectForKey:@"id"];
                            photoAsset.facetID = facetID;
                        } else {
                            NSLog(@"returned from upload request for metadata");
                            if (photoAsset.commentNeedsUpdate == YES) {
                                [photoAsset setCommentNeedsUpdate:NO];
                            }
                        }

                        [_photos replaceObjectAtIndex:i withObject:photoAsset];
                        [self savePhotosArray];
                        [[NSNotificationCenter defaultCenter] postNotificationName:BT_NOTIFICATION_PHOTO_UPLOAD_SUCCEEDED object:self userInfo:@{@"index":[NSNumber numberWithInt:i]}];
                        _isUploading = NO;
                        [self uploadNow];
                    }
                }];
            } failureBlock:^(NSError *error) {
                NSLog(@"error fetching asset: %@", error);
            }];
        }
    }
}


- (int)photoIndexForUpload
{
    for (int i = 0; i < [_photos count]; i++) {
        BTPhotoAsset *photoAsset = [_photos objectAtIndex:i];
        if ([photoAsset.uploadStatus isEqual:@"1"] || photoAsset.commentNeedsUpdate == YES) {
            return i;
        }
    }
    
    return NSNotFound;
}


- (NSString *)photosArrayArchivePath
{
    NSArray *documentDirectories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [documentDirectories objectAtIndex:0];
    NSString *path = [documentDirectory stringByAppendingPathComponent:@"photos.archive"];
    return path;
}


- (BOOL)savePhotosArray
{
    NSString *path = [self photosArrayArchivePath];
    
    BOOL success = [NSKeyedArchiver archiveRootObject:_photos toFile:path];
    
    if (success == YES)
    {
        NSError *error = nil;
        
        NSURL *url = [NSURL fileURLWithPath:path];
        BOOL excludeFromBackup = [url setResourceValue: [NSNumber numberWithBool: YES]
                                      forKey: NSURLIsExcludedFromBackupKey error: &error];
        if(!excludeFromBackup){
            NSLog(@"Error excluding %@ from backup %@", [url lastPathComponent], error);
        }

    }
    return success;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Assets Library Notifications

- (void)assetsLibraryChanged:(NSNotification *)notification
{
    if (!_isReloading) {
        _isReloading = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self discoverPhotos];
        });
    }
}

#pragma mark - Comment & Tag upload handling

- (void)updateAnnotationsForAsset:(BTPhotoAsset *)annotatedAsset
{
    for (BTPhotoAsset *asset in _photos) {
        if (asset.assetURL == annotatedAsset.assetURL) {
            asset.comment = annotatedAsset.comment;
            asset.tags = annotatedAsset.tags;
            if (![annotatedAsset.facetID isEqual: @""]) {
                asset.facetID = annotatedAsset.facetID;
            } else {
                asset.uploadStatus = @"1";
            }
            
            asset.commentNeedsUpdate = YES;
        }
    }
    
    [self savePhotosArray];
    [self uploadNow];
}

@end
