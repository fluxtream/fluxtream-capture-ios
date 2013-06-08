//
//  BTPhotoImageUploadRequest.h
//  Stetho
//
//  Created by Rich Henderson on 3/14/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface BTPhotoImageUploadRequest : NSObject

+ (NSURLRequest *)uploadRequestForAsset:(ALAsset *)asset;

@end
