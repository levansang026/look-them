//
//  CacheItem.m
//  ContactPicker
//
//  Created by AnLVH on 12/21/16.
//  Copyright © 2016 admin. All rights reserved.
//

#import "CacheItem.h"
#define BYTES_PER_PIXEL 4

@interface CacheItem () {

}

@end

@implementation CacheItem

- (id)initWithImage:(UIImage *)image key:(NSString *)key expiryDate:(NSDate*)expired{
    self = [super init];
    if(self) {
        self.image = image;
        self.key = key;
        self.expiryDate = expired;
    }
    return self;
}

- (NSUInteger)sizeInBytes {
    return self.image.size.height * self.image.size.width * self.image.scale * BYTES_PER_PIXEL;
}

- (BOOL)cacheItemExpired {
    NSDate *curDate = [NSDate date];
    return [self.expiryDate compare:curDate] != NSOrderedDescending ? YES : NO;
}


@end
