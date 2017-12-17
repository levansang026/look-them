//
//  Downloader.m
//  DownloadManager
//
//  Created by LVHAN on 1/6/17.
//  Copyright © 2017 admin. All rights reserved.
//

#import "AHDowloadManager.h"
#import "AHNetworkManager.h"
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, DownloadManagerErrorCode) {
    InvalidImage = 0,
    MissingData,
    Timemout,
};
#define DefaultTimeoutInterval 60.0
#define DefaultMaxConcurrentTask 6
#define DownloadManagerErrorDomain @"vn.com.VNG.ContactPicker.DownloaderErrorDomain"
typedef void (^AHDownloaderProgressBlock) (NSData* data,NSError *error);
typedef NSMutableArray<AHDownloaderProgressBlock> AHProgressBlockArray;

@interface AHDowloadManager () {
    NSMutableSet<NSURL*> *runningURLRequest;
    dispatch_queue_t downloadQueue;
    dispatch_semaphore_t concurrentLimittingSemaphore;
    NSMutableDictionary <NSURL*,NSMutableArray<AHDownloaderProgressBlock>*> *progressBlocks;
}

@end

@implementation AHDowloadManager

+ (instancetype)sharedDownloader {
    static AHDowloadManager *downloader = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloader = [[AHDowloadManager alloc] init];
    });
    
    return downloader;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        concurrentLimittingSemaphore = dispatch_semaphore_create(DefaultMaxConcurrentTask);
        runningURLRequest = [NSMutableSet set];
        downloadQueue = dispatch_queue_create("vn.com.VNG.Downloader.ContactLoaderDownloadQueue", DISPATCH_QUEUE_CONCURRENT);
        progressBlocks = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (instancetype)initWithMaxConcurrentDownloadTasks:(long)limit {
    self = [super init];
    if(self) {
        concurrentLimittingSemaphore = dispatch_semaphore_create(limit);
        runningURLRequest = [NSMutableSet set];
        downloadQueue = dispatch_queue_create("vn.com.VNG.Downloader.ContactLoaderDownloadQueue", DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (void)downloadImageWithURL:(NSURL *)url completionHandler:(void (^)(UIImage *, NSError *))handler {
    [self downloadDataWithURL:url completionHandler:^(NSData *data, NSError *error) {
        if (error) {
            handler(nil, error);
        }
        else {
            UIImage *image = [UIImage imageWithData:data];
            if(!image) {
                error = [NSError errorWithDomain:DownloadManagerErrorDomain code:InvalidImage userInfo:@{NSLocalizedDescriptionKey : @"Invalid Image"}];
            }
            
            if(handler) {
                handler(image,error);
            }
        }
    }];
}

- (void)downloadDataWithURL:(NSURL *)url completionHandler:(void (^)(NSData *, NSError *))handler {
    __weak typeof (self)weakSelf = self;
    
    //Nếu url đang down thì add block
    if ([self isRunningURLRequest:url]){
        NSLog(@"%@ is downloading", url.absoluteString);
        [self addProgressBlock:handler forURL:url];
        return;
    }
    
    if(dispatch_semaphore_wait(concurrentLimittingSemaphore, dispatch_time(DISPATCH_TIME_NOW, (DefaultTimeoutInterval * NSEC_PER_SEC)))) {
        NSLog(@"TIMEOUT");
        if(handler) {
            handler(nil, [self errorTimeOut]);
        }
    }
    else {
        NSLog(@"%lu",(unsigned long)[runningURLRequest count]);
        
        //Kiểm tra URL thêm 1 lần nữa do có trường hợp 2 thằng cùng url bị block lúc chờ semaphore
        dispatch_barrier_sync(downloadQueue, ^{
            if ([self isRunningURLRequest:url]) {
                NSLog(@"%@ is downloading", url.absoluteString);
                [self addProgressBlock:handler forURL:url];
                dispatch_semaphore_signal(concurrentLimittingSemaphore);
                return;
            }
            else {
                [self addURLRequest:url];
            }
        });
        
        dispatch_async(downloadQueue, ^{
            [[AHNetworkManager sharedManager] downloadWithURL:url completionHandler:^(NSData *result, NSError *error) {
                if(result) {
                    //[[AHNetworkManager sharedManager]cancelRequestsForURL:url];
                    dispatch_group_t group = dispatch_group_create();
                    AHProgressBlockArray *blocks = [weakSelf progressBlocksForURL:url];
                    dispatch_apply([blocks count], dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(size_t i) {
                        dispatch_group_enter(group);
                        [blocks objectAtIndex:i](result,error);
                        dispatch_group_leave(group);
                    });
                    dispatch_group_notify(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                        [weakSelf removeProgressBlockForURL:url];
                    });
                }
                [self removeURLRequest:url];
                dispatch_semaphore_signal(concurrentLimittingSemaphore);
                
                if(handler) {
                    handler(result,error);
                }
                
                if(error) {
                    AHDownloaderProgressBlock nextBlock = [self firstProgressBlockForURL:url];
                    NSLog(@"Download Error");
                    if(nextBlock) {
                        [self downloadDataWithURL:url completionHandler:nextBlock];
                    }
                }
            }];
        });
    }
}

#pragma mark - Private methods

- (AHProgressBlockArray*)progressBlocksForURL:(NSURL*)URL {
    return [progressBlocks objectForKey:URL];
}

- (void)addProgressBlock:(AHDownloaderProgressBlock)progressBlock forURL:(NSURL*)URL {
    @synchronized (self) {
        NSMutableArray <AHDownloaderProgressBlock>* blocks = [progressBlocks objectForKey:URL];
        if(!blocks) {
            blocks = [NSMutableArray array];
            [progressBlocks setObject:blocks forKey:URL];
        }
        [blocks addObject:progressBlock];
    }
}

- (void)removeProgressBlockForURL:(NSURL*)URL {
    @synchronized (self) {
        [progressBlocks removeObjectForKey:URL];
    }
}

- (AHDownloaderProgressBlock)firstProgressBlockForURL:(NSURL*)URL {
    AHProgressBlockArray *blocks = [self progressBlocksForURL:URL];
    if(blocks && [blocks count] > 0) {
        return [[progressBlocks objectForKey:URL]firstObject];
    }
    return nil;
}

- (void)removeFirstProgressBlockForURL:(NSURL*)URL {
    @synchronized (self) {
        AHProgressBlockArray *blocks = [self progressBlocksForURL:URL];
        if(blocks && [blocks count] > 0) {
            [blocks removeObjectAtIndex:0];
        }
    }
}

- (void)addURLRequest:(NSURL*)URL {
    @synchronized (self) {
        if(URL) {
            [runningURLRequest addObject:URL];
        }
    }
}

- (void)removeURLRequest:(NSURL*)URL {
    @synchronized (self) {
        if(URL && [runningURLRequest containsObject:URL]) {
            [runningURLRequest removeObject:URL];
        }
    }
}

- (BOOL)isRunningURLRequest:(NSURL*)URL {
    return (URL && [runningURLRequest containsObject:URL]) ? YES : NO;
}

#pragma mark - Error

- (NSError *)errorTimeOut {
    return [NSError errorWithDomain:DownloadManagerErrorDomain
                               code:Timemout
                           userInfo:@{NSLocalizedDescriptionKey : @"Time out"}];
}

@end
