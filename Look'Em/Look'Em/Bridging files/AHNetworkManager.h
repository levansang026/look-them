//
//  AHNetworkManager.h
//  AHNetworkManager
//
//  Created by AnLVH on 1/9/17.
//  Copyright © 2017 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, CNNetworkingHTTPMethod) {
    CNNetworkingHTTPMethodGET = 0,
    CNNetworkingHTTPMethodPOST,
    CNNetworkingHTTPMethodDELETE,
    CNNetworkingHTTPMethodPUT
};

@interface AHNetworkManager : NSObject

/**
 *  @Brief Get an singleton object for sharing manager
 *
 *  @return return CNNetworking object
 */
+ (instancetype)sharedManager;

/**
 *  @Brieft Download data with a specificed url
 *
 *  @param url     URL is used to request
 *  @param handler The callback function that invokes when the downloading completed
 */
- (void)downloadWithURL:(NSURL*)url completionHandler:(void (^)(NSData *result, NSError *error))handler;

/**
 *  @Brief Upload data with an specificed url
 *
 *  @param url     URL is used to request
 *  @param data    Data that need uploading
 *  @param handler The callback function that invokes when the uploading completed
 */
- (void)uploadWithURL:(NSURL*)url fromData:(NSData*)data completionHandler:(void (^)(BOOL success, NSError *error))handler;

/**
 *  @Brief Request data with URL ad HTTPMethod
 *
 *  @param url        URL is used to request
 *  @param HTTPMethod HTTPMethod : GET, POST, DELETE, PUT,..
 *  @param handler    The callback function that invokes when the requesting completed
 */
- (void)requestWithURL:(NSURL*)url
                  type:(CNNetworkingHTTPMethod)HTTPMethod
     completionHandler:(void (^)(NSData *result, NSError *error))handler;

/**
 *  @Brief Request data
 *
 *  @param request The request to an HTTP method
 *  @param handler The callback function that invokes when the requesting completed
 */
- (void)request:(NSURLRequest*)request completionHandler:(void (^)(NSData *result, NSError *error))handler;

/**
 *  @Brief Cancel all requests
 */
- (void)cancelAllRequests;

/**
 *  @Brief Cancel all request to specificed URL
 *
 *  @param URL URL is used to request
 */
- (void)cancelRequestsForURL:(NSURL*)URL;

@end
