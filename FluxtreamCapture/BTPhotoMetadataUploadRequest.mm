//
//  BTPhotoMetadataUploadRequest.m
//  Stetho
//
//  Created by Rich Henderson on 3/14/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTPhotoMetadataUploadRequest.h"
#import "Constants.h"
#import "NSUtils.h"

@implementation BTPhotoMetadataUploadRequest

+ (NSURLRequest *)metadataUploadRequestForAsset:(BTPhotoAsset *)asset
{
    // check we have a facet id for the asset before we begin, if not return nil
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults objectForKey:DEFAULTS_SERVER];
    NSArray *keyParts = [asset.uploadStatus componentsSeparatedByString:@"."]; //UID is the first item in the returned array
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: [NSString stringWithFormat:@"http://%@/api/bodytrack/metadata/%@/FluxtreamCapture.photo/%@/set", baseURL, [keyParts objectAtIndex:0], asset.facetID]]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:30];
    [request setHTTPMethod:@"POST"];
    [request setValue:[NSString stringWithFormat:@"application/x-www-form-urlencoded"] forHTTPHeaderField: @"Content-Type"];
    
    NSString *body = [NSString stringWithFormat:@"comment=%@&tags=%@", asset.comment, asset.tags];
    
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    [request addValue:[NSString stringWithFormat:@"%i", [body length]] forHTTPHeaderField:@"Content-Length"];
    
    NSString *authStr = [NSString stringWithFormat:@"%@:%@", [defaults valueForKey:DEFAULTS_USERNAME], [defaults valueForKey:DEFAULTS_PASSWORD]];
    
    NSData *authData = [authStr dataUsingEncoding:NSUTF8StringEncoding];
    NSString *authValue = [NSString stringWithFormat:@"Basic %@", base64encode(authData)];
    [request setValue:authValue forHTTPHeaderField:@"Authorization"];
    
    return request;
}

@end
