//
//  BTPhotoAsset.h
//  Stetho
//
//  Created by Rich Henderson on 2/5/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface BTPhotoAsset : NSObject <NSCoding>


// Unique asset URL as supplied by assets library framework.  Persists through restart.
// Always set.
@property (strong) NSString *assetURL;


// https://fluxtream.atlassian.net/wiki/display/FLX/BodyTrack+server+APIs#BodyTrackserverAPIs-/photoUpload?connector_name=CONNECTOR_NAME

// Fluxtream's facet ID;  used for setting comment or tags
// "" means never uploaded
// Otherwise, stores "id" returned in a successful Fluxtream upload

@property (strong) NSString *facetID;

// "0" means never uploaded
// "1" we want to upload
// Otherwise, stores the "key" returned by fluxtream upload, e.g.
// "14.FluxtreamCapture.photo.2013098.1365434963721_e1adc5810563c2ac4c501aeab414b5c6f41a32b6e447ce49408c742506b8c300"
// Used for fetching image, e.g. /photo/ID

// The UID is the very first number, up to the ".", and we need it for uploading metadata.

@property (strong) NSString *uploadStatus;

// "" if no comment
// Otherwise, has the most recent user input
@property (strong) NSString *comment;

// "" if no tags
// Otherwise, tags are delimited by ",".  Alphanumerics, dashes, and underscores are allowed.  All else is converted to underscore at the server

@property (strong) NSString *tags;

// True if comment or tags needs uploading

@property (assign) BOOL commentNeedsUpdate;

- (id)initWithAssetURL:(NSString *)assetURL uploadStatus:(NSString *)uploadStatus;

@end
