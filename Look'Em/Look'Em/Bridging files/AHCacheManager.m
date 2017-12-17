//
//  ImageCacher.m
//  ContactPicker
//
//  Created by AnLVH on 12/21/16.
//  Copyright © 2016 admin. All rights reserved.
//

#import "AHCacheManager.h"
#import "CacheItem.h"
#import <CommonCrypto/CommonHMAC.h>

#define ContactPickerCachingDirectory @"ContactPickerCachingDirectory"
#define EXPIRY_TWO_DAYS 2*24*60*60
#define EXPIRY_ONE_HOURS 60*60
#define MIN_CACHE_SIZE 10*1024*1024
#define MAX_CACHE_SIZE 0.05*[[NSProcessInfo processInfo] physicalMemory]
#define ImageCacherErrorDomain @"vn.com.VNG.ContactPicker.ImageCacherErrorDomain"

typedef NS_ENUM(NSUInteger,ImageCacherErrorCode) {
    NotExistInCache,
    NotExistInDisk,
};


@interface AHCacheManager () {
    dispatch_queue_t internalConcurrentQueue;
    dispatch_queue_t internalIOSerialQueue;
    
    NSMutableDictionary *imageCacheMap;
    NSString *cacheDirectory;
    
    NSUInteger minCacheSize;
    NSUInteger maxCacheSize;
    NSUInteger usedCacheSize;

    CacheItem *leastRecentlyUsed;
    CacheItem *mostRecentlyUsed;
}


@end

@implementation AHCacheManager

+ (instancetype)sharedManager {
    static AHCacheManager *imageCacher = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        imageCacher = [[AHCacheManager alloc]init];
    });
    return imageCacher;
}

- (instancetype)init {
    self = [super init];
    
    if(self) {
        imageCacheMap = [NSMutableDictionary dictionary];
        cacheDirectory = [self cacheDirectoryPath];
        
        internalConcurrentQueue = dispatch_queue_create("vn.com.VNG.ContactPicker.ImageCacher.ConcurrentQueue", DISPATCH_QUEUE_CONCURRENT);
        internalIOSerialQueue = dispatch_queue_create("vn.com.VNG.ContactPicker.ImageCacher.IOSerialQueue", DISPATCH_QUEUE_SERIAL);
        
        usedCacheSize = 0;
        minCacheSize = MIN_CACHE_SIZE;
        maxCacheSize = MAX_CACHE_SIZE;
        
        [[NSNotificationCenter defaultCenter]addObserver:self
                                                selector:@selector(didReceiveMemoryWarning:)
                                                    name:UIApplicationDidReceiveMemoryWarningNotification
                                                  object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(enterBackgroundHandler)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning:(NSNotification *)notification {
    [self rollCache];
}

#pragma Store Cache

- (void)imageWithKey:(NSString *)URLString completionHandler:(void (^)(UIImage *result,NSString *key, NSError *error))handler {
    __weak typeof(self) weakSelf = self;
    dispatch_async(internalConcurrentQueue, ^{
        
        NSString *md5Key = [weakSelf cachedFileNameForKey:URLString];
        
        CacheItem *cachedItem = [imageCacheMap objectForKey:md5Key];
        
        if (cachedItem) {
            [weakSelf changeCacheItemPriority:cachedItem];
            if (handler) {
                handler(cachedItem.image, URLString, nil);
            }
        }
        else {
            if(handler) {
                NSError *error = [NSError errorWithDomain:ImageCacherErrorDomain
                                                         code:NotExistInCache
                                                     userInfo:@{ NSLocalizedDescriptionKey : @"Image not in Cache"}];
                handler(nil,URLString, error);
            }
        }
    });
}

- (void)imageOnDiskWithKey:(NSString *)URLString completionHandler:(void (^)(UIImage *result,NSString *key, NSError *error))handler {
    __weak typeof(self) weakSelf = self;
    dispatch_async(internalIOSerialQueue, ^{
        
        NSString *md5Key = [weakSelf cachedFileNameForKey:URLString];
        
        NSString *cacheItemPath = [cacheDirectory stringByAppendingPathComponent:md5Key];
        UIImage *image = [self cachedImageWithContentOfFile:cacheItemPath];
        NSError *error;
        
        if(!image) {
            error = [NSError errorWithDomain:ImageCacherErrorDomain
                                        code:NotExistInDisk
                                    userInfo:@{ NSLocalizedDescriptionKey : @"Image not in disk"}];
        }
        
        if(handler) {
             handler(image,URLString, error);
        }
    });
}

- (void)cacheImage:(UIImage *)image key:(NSString *)URLString {
    __weak typeof(self) weakSelf = self;
    dispatch_barrier_async(internalConcurrentQueue, ^{
        
        NSString *md5Key = [weakSelf cachedFileNameForKey:URLString];
        
        if(![imageCacheMap objectForKey:md5Key]) {
            CacheItem *cacheItem = [[CacheItem alloc]initWithImage:image
                                                          key:md5Key
                                                   expiryDate:[NSDate dateWithTimeIntervalSinceNow:EXPIRY_ONE_HOURS]];
            
            NSString *cacheItemPath = [cacheDirectory stringByAppendingPathComponent:md5Key];
            
            if(![[NSFileManager defaultManager] fileExistsAtPath:cacheItemPath]) {
                dispatch_async(internalIOSerialQueue, ^{
                    if(![self writeImage:image toFile:cacheItemPath]) {
                        NSLog(@"write image error");
                    }
                });
            }
    
            [self addCacheItem:cacheItem];
        }
    });
}

#pragma mark - Remove Cache
- (void)rollCache {
    __weak typeof(self) weakSelf = self;
    static BOOL didReceiveMemoryWarning = NO;
    dispatch_barrier_async(internalConcurrentQueue, ^{
        
        NSLog(@"Truoc khi roll: Used cache: %lu", (unsigned long)usedCacheSize);
        if(!didReceiveMemoryWarning) {
            while (usedCacheSize > minCacheSize) {
                [weakSelf removeLeastUsedItem];
            }
            didReceiveMemoryWarning = YES;
        }
        else {
            didReceiveMemoryWarning = NO;
            [imageCacheMap removeAllObjects];
            leastRecentlyUsed = nil;
            mostRecentlyUsed = nil;
            usedCacheSize = 0;
        }
        NSLog(@"Sau khi roll: Used cache: %lu", (unsigned long)usedCacheSize);
    });
}

#pragma mark - Private methods

- (void)addCacheItem:(CacheItem*)item {
    @synchronized (self) {
        if(item) {
            NSUInteger itemSize = [item sizeInBytes];
            while (usedCacheSize + itemSize >= maxCacheSize) {
                [self removeLeastUsedItem];
            }
            usedCacheSize += itemSize;
            [imageCacheMap setObject:item forKey:item.key];
            [self changeCacheItemPriority:item];
        }
    }
}

- (void)changeCacheItemPriority:(CacheItem*)item {
    @synchronized (self) {
        if (leastRecentlyUsed == nil && mostRecentlyUsed == nil) {
            leastRecentlyUsed = item;
            mostRecentlyUsed = item;
        }
        else {
            if (item == mostRecentlyUsed) {
                return;
            }
            
            if (item == leastRecentlyUsed) {
                leastRecentlyUsed = leastRecentlyUsed.nexItem;
                leastRecentlyUsed.preItem = nil;
            }
            
            if (item.preItem && item.nexItem) {
                item.preItem.nexItem = item.nexItem;
                item.nexItem.preItem = item.preItem;
            }
            
            mostRecentlyUsed.nexItem = item;
            item.preItem = mostRecentlyUsed;
            item.nexItem = nil;
            mostRecentlyUsed = item;
        }
    }
}

- (void)removeLeastUsedItem {
    @synchronized (self) {
        if (leastRecentlyUsed) {
            CacheItem *itemToRemove = leastRecentlyUsed;
            
            leastRecentlyUsed = leastRecentlyUsed.nexItem;
            leastRecentlyUsed.preItem = nil;
            
            [imageCacheMap removeObjectForKey:itemToRemove.key];
            usedCacheSize -= [itemToRemove sizeInBytes];
            itemToRemove = nil;
        }
    }
}

- (NSString*)cacheDirectoryPath {
    NSArray *diskPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true);
    NSString *cachePath = [diskPaths[0] stringByAppendingPathComponent:ContactPickerCachingDirectory];
    
    if(![[NSFileManager defaultManager]fileExistsAtPath:cachePath isDirectory:nil]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:YES attributes:nil error:&error];
        if(error) {
            NSLog(@"%@",error);
        }
    }
    return cachePath;
}

- (nullable NSString *)cachedFileNameForKey:(nullable NSString *)key {
    const char *str = key.UTF8String;
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%@",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10],
                          r[11], r[12], r[13], r[14], r[15], [key.pathExtension isEqualToString:@""] ? @"" : [NSString stringWithFormat:@".%@", key.pathExtension]];
    
    return filename;
}

- (void)enterBackgroundHandler {
    Class UIApplicationClass = NSClassFromString(@"UIApplication");
    if(!UIApplicationClass || ![UIApplicationClass respondsToSelector:@selector(sharedApplication)]) {
        return;
    }
    UIApplication *application = [UIApplication performSelector:@selector(sharedApplication)];
    __block UIBackgroundTaskIdentifier bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];

    [self removeAllExpiredFileWithCompletionBlock:^{
        [application endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }];
}

- (void)removeAllExpiredFileWithCompletionBlock:(void(^)(void))handler{
    dispatch_async(internalIOSerialQueue, ^{
        __block NSError *error;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray<NSString *> *cachedFilesName = [fileManager contentsOfDirectoryAtPath:[self cacheDirectoryPath] error:&error];
        
        if(!error) {
            for (NSString *name in cachedFilesName) {
                
                NSString *path = [cacheDirectory stringByAppendingPathComponent:name];
                NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:path error:&error];
                if (fileAttributes) {
                    NSDate *expireTime = [NSDate dateWithTimeInterval:EXPIRY_TWO_DAYS sinceDate:[fileAttributes objectForKey: NSFileModificationDate]];
                    
                    NSDate *now = [NSDate date];
                    if ([now compare:expireTime] == NSOrderedDescending) {
                       [fileManager removeItemAtPath:path error:&error];
                    }
                }
            }
            
        }
        else {
            NSLog(@"Can't read cachDirectory Path: %@", error.description);
        }
        
        if(handler) {
            handler();
        }
    });
}

- (BOOL)writeImage:(UIImage*)image toFile:(NSString *)path {
    NSData *imageData = UIImageJPEGRepresentation(image, 1.0);
    if(imageData && imageData.length > 0) {
        return [imageData writeToFile:path atomically:YES];
    }
    return NO;
}

- (UIImage*)cachedImageWithContentOfFile:(NSString*)path {
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    if(image) {
        
        NSMutableDictionary *fileAttributes = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil]mutableCopy];
        [fileAttributes setObject:[NSDate date] forKey:NSFileModificationDate];
        
        NSError *error = nil;
        [[NSFileManager defaultManager]setAttributes:fileAttributes ofItemAtPath:path error:&error];
        
        if(error) {
            NSLog(@"%@",error);
        }
    }
    return image;
}

@end
