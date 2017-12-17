//
//  Downloader.h
//  DownloadManager
//
//  Created by LVHAN on 1/6/17.
//  Copyright © 2017 admin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AHDowloadManager : NSObject

/**
 *  @Brief Get an singleton object for sharing manager
 *
 *  @return DownloadManager object
 */
+ (instancetype)sharedDownloader;

/**
 *  @Brief Create an DownloadManager with maximum concurrent downloading tasks
 *
 *  @param limit The maximum concurrent tasks
 *
 *  @return DownloadManager object
 */
- (instancetype)initWithMaxConcurrentDownloadTasks:(long)limit;

/**
 *  @Brief Download an Image with URL
 *
 *  @param url     URL is used to request
 *  @param handler The callback function that invokes when the downloading completed
 */
- (void)downloadImageWithURL:(NSURL *)url
           completionHandler:(void (^)(UIImage *result, NSError *error))handler;

/**
 *  @Brief Download data with URL
 *
 *  @param url     URL is used to request
 *  @param handler The callback function that invokes when the downloading completed
 */
- (void)downloadDataWithURL:(NSURL *)url
      completionHandler:(void (^)(NSData *data, NSError *error))handler;
@end
