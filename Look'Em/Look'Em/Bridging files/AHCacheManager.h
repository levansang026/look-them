//
//  ImageCacher.h
//  ContactPicker
//
//  Created by AnLVH on 12/21/16.
//  Copyright © 2016 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CacheItem;

@interface AHCacheManager : NSObject

/**
 *  @Brief Get singleton object for sharing manager
 *
 *  @return A ImageCahe
 */
+ (instancetype)sharedManager;

/**
 *  @Brief Get an image with the given key
 *
 *  @param key Key is used to find image in image cache map
 *
 *  @param handler The callback function that invokes when fetching completed
 */
- (void)imageWithKey:(NSString *)key completionHandler:(void (^)(UIImage *result,NSString *key, NSError *error))handler;

/**
 *  @Brief Load image on disk with the given key
 *
 *  @param key Key is used to find image on disk
 *
 *  @param handler The callback function that invokes when fetching completed
 */
- (void)imageOnDiskWithKey:(NSString *)key completionHandler:(void (^)(UIImage *result,NSString *key, NSError *error))handler;

/**
 *  @Brief Cache an image with the given key
 *
 *  @param image Image that needs to cache
 *  @param key   Key is an identifier for image
 */
- (void)cacheImage:(UIImage*)image key:(NSString*)key;

@end
