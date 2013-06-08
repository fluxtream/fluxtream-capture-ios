//
//  BTPhotoMetadataRequest.h
//  Stetho
//
//  Created by Rich Henderson on 3/15/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTPhotoAsset.h"

@interface BTPhotoMetadataRequest : NSObject

+ (NSURLRequest *)metadataRequestForAsset:(BTPhotoAsset *)asset;

@end
