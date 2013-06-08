//
//  BTPhotoUploader.h
//  Stetho
//
//  Created by Rich Henderson on 2/4/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "BTPhotoAsset.h"

@interface BTPhotoUploader : NSObject

@property (strong, nonatomic) ALAssetsLibrary *library;
@property (strong) NSMutableArray *photos;
@property (strong) NSMutableArray *discoveredPhotos;
@property (strong) NSArray *oldPhotos;
@property (strong) NSURLRequest *postRequest;
@property (strong) NSTimer *uploadKickTimer;
@property (assign) BOOL isUploading;
@property (assign) BOOL isReloading;

+ (id)sharedPhotoUploader;

- (void)unuploadedPhotosWithOrientation:(ALAssetOrientation)requestedOrientation;
- (void)markPhotosForUpload:(NSArray *)photos;
- (void)updateAnnotationsForAsset:(BTPhotoAsset *)annotatedAsset;

- (void)uploadNow;
- (BOOL)savePhotosArray;

@end
        