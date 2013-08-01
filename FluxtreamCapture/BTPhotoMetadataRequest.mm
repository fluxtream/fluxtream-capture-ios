//
//  BTPhotoMetadataRequest.m
//  Stetho
//
//  Created by Rich Henderson on 3/15/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTPhotoMetadataRequest.h"
#import "Constants.h"
#import "NSUtils.h"

@implementation BTPhotoMetadataRequest

+ (NSURLRequest *)metadataRequestForAsset:(BTPhotoAsset *)asset
{
    if ([asset.facetID isEqual: @""]) {
        return nil;
    } else {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        // asset.facetID:  ID as returned by server
        // TODO
        NSMutableURLRequest *request =
            [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"http://upload.gigapan.com/todo-upload-metadata"]];
        
        [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
        [request setHTTPShouldHandleCookies:NO];
        [request setTimeoutInterval:30];
        [request setHTTPMethod:@"GET"];
        
        NSString *authStr = [NSString stringWithFormat:@"%@:%@", [defaults valueForKey:DEFAULTS_USERNAME], [defaults valueForKey:DEFAULTS_PASSWORD]];
        
        NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
        NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64encode(authData)];
        [request setValue:authValue forHTTPHeaderField:@"Authorization"];
        
        return request;
    }
}

@end
