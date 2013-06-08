//
//  BTPhotoTagsForUserRequest.h
//  Stetho
//
//  Created by Rich Henderson on 3/26/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTPhotoAsset.h"

@interface BTPhotoTagsForUserRequest : NSObject

+ (NSURLRequest *)allPhotoTagsForUser:(NSString *)uid;

@end
