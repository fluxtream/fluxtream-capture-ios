//
//  BTPhotoTagsForUserRequest.m
//  Stetho
//
//  Created by Rich Henderson on 3/26/13.
//  Copyright (c) 2013 BodyTrack. All rights reserved.
//

#import "BTPhotoTagsForUserRequest.h"
#import "Constants.h"
#import "NSUtils.h"

@implementation BTPhotoTagsForUserRequest

+ (NSURLRequest *)allPhotoTagsForUser:(NSString *)uid
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *baseURL = [defaults objectForKey:DEFAULTS_SERVER];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: [NSString stringWithFormat:@"http://%@/api/bodytrack/users/%@/tags", baseURL, uid]]];
    
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

@end
