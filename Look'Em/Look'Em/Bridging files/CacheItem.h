//
//  CacheItem.h
//  ContactPicker
//
//  Created by AnLVH on 12/21/16.
//  Copyright © 2016 admin. All rights reserved.
//

#import <UIKit/UIKit.h>

@class UIImage;

@interface CacheItem : NSObject

@property UIImage *image;
@property NSString *key;
@property NSDate *expiryDate;

@property (weak, atomic) CacheItem *preItem;
@property (weak, atomic) CacheItem *nexItem;

/**
 *  @Brief Get size of cache item
 *
 *  @return The number of bytes
 */
- (NSUInteger)sizeInBytes;

/**
 *  @Brief Check the expiration of cache item
 *
 *  @return YES if exprired, else NO
 */
- (BOOL)cacheItemExpired;

/**
 *  @Brief Create a cache item with an image and key
 *
 *  @param image Image is used to init cache item
 *  @param key   Key is used to init cache item
 */
- (id)initWithImage:(UIImage*)image key:(NSString*)key expiryDate:(NSDate*)expiryDate;

@end
