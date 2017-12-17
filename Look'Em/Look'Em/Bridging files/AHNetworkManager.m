//
//  AHNetworkManager.m
//  AHNetworkManager
//
//  Created by AnLVH on 1/9/17.
//  Copyright © 2017 admin. All rights reserved.
//

#import "AHNetworkManager.h"

#define HTTPMethodGET @"GET"
#define HTTPMethodPUT @"PUT"
#define HTTPMethodPOST @"POST"
#define HTTPMethodDELETE @"DELETE"
const NSTimeInterval DefaultTimeoutInterval = 60.0;


@interface AHNetworkManager () {
    NSURLSession *URLSession;
}
@end

@implementation AHNetworkManager

#pragma mark - Public methods

+ (instancetype)sharedManager {
    static AHNetworkManager *networkObject = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        networkObject = [[AHNetworkManager alloc]init];
    });
    return networkObject;
}

- (instancetype)init {
    self = [super init];
    if(self) {
        URLSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        URLSession.sessionDescription = @"vn.com.VNG.CNNetworking";
    }
    return self;
}

- (void)downloadWithURL:(NSURL *)url completionHandler:(void (^)(NSData*, NSError *))handler {
    if(!url) {
        if(handler) {
            handler(nil, [self errorForNilURL]);
        }
        return;
    }
    
    NSURLRequest *URLRequest = [self URLRequestWithURL:url HTTPMethod:HTTPMethodGET timeoutInterval:DefaultTimeoutInterval];
   
    NSURLSessionDataTask *dataTask = [URLSession dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            NSLog(@"%@",error);
        }
        if(handler) {
            handler(data,error);
        }
    }];
    [dataTask resume];
}

- (void)uploadWithURL:(NSURL *)url fromData:(NSData*)data completionHandler:(void (^)(BOOL, NSError *))handler {
    
    if(!url) {
        if(handler) {
            handler(NO,[self errorForNilURL]);
        }
        return;
    }
    
    NSURLRequest *URLRequest = [self URLRequestWithURL:url HTTPMethod:HTTPMethodPUT timeoutInterval:DefaultTimeoutInterval];
    
    NSURLSessionUploadTask *uploadTask = [URLSession uploadTaskWithRequest:URLRequest fromData:data completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        BOOL success;
        if(error) {
            success = NO;
        }
        else {
            success = YES;
        }
        
        if(handler) {
            handler(success,error);
        }
    }];
    [uploadTask resume];
}

- (void)requestWithURL:(NSURL *)url type:(CNNetworkingHTTPMethod)HTTPMethodType completionHandler:(void (^)(NSData*, NSError *))handler {
    NSString *HTTPMethod;
    switch (HTTPMethodType) {
        case CNNetworkingHTTPMethodGET:
            HTTPMethod = HTTPMethodGET;
            break;
        case CNNetworkingHTTPMethodPOST:
            HTTPMethod = HTTPMethodPOST;
            break;
        case CNNetworkingHTTPMethodDELETE:
            HTTPMethod = HTTPMethodDELETE;
            break;
        case CNNetworkingHTTPMethodPUT:
            HTTPMethod = HTTPMethodPUT;
            break;
        default:
            HTTPMethod = HTTPMethodGET;
            break;
    }
    NSURLRequest *URLRequest = [self URLRequestWithURL:url HTTPMethod:HTTPMethod timeoutInterval:DefaultTimeoutInterval];
    
    if(!url) {
        if(handler) {
            handler(nil,[self errorForNilURL]);
        }
        return;
    }
    
    NSURLSessionDataTask *dataTask = [URLSession dataTaskWithRequest:URLRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if(error) {
            NSLog(@"%@",error);
        }
        if(handler) {
            handler(data,error);
        }
    }];
    [dataTask resume];
}

- (void)request:(NSURLRequest *)request completionHandler:(void (^)(NSData*, NSError *))handler {
    if(!request) {
        if(handler) {
            handler(nil,[NSError errorWithDomain:NSURLErrorDomain code:-2 userInfo:@{NSLocalizedDescriptionKey : @"Request must not be nil"}]);
        }
        return;
    }
    
    NSURLSessionDataTask *dataTask = [URLSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
    }];
    [dataTask resume];
}

- (void)cancelAllRequests {
    [URLSession invalidateAndCancel];
    URLSession = nil;
}

- (void)cancelRequestsForURL:(NSURL*)URL {
    [URLSession getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        NSInteger capacity = [dataTasks count] + [uploadTasks count] + [downloadTasks count];
        NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:capacity];
        [tasks addObjectsFromArray:dataTasks];
        [tasks addObjectsFromArray:uploadTasks];
        [tasks addObjectsFromArray:downloadTasks];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"originalRequest.URL = %@", URL];
        [tasks filterUsingPredicate:predicate];
        for (NSURLSessionTask *task in tasks) {
            [task cancel];
        }
 
    }];
}

#pragma mark - Private methods

- (NSError*)errorForNilURL
{
    return [NSError errorWithDomain:NSURLErrorDomain
                               code:-1
                           userInfo:@{NSLocalizedFailureReasonErrorKey : @"URL must not be nil"}];
}

- (NSURLRequest*)URLRequestWithURL:(NSURL*)url HTTPMethod:(NSString*)HTTPMethod timeoutInterval:(NSTimeInterval)timeout {
    NSMutableURLRequest *URLRequest = [NSMutableURLRequest requestWithURL:url];
    [URLRequest setTimeoutInterval:DefaultTimeoutInterval];
    [URLRequest setHTTPMethod:HTTPMethodGET];
    return URLRequest;
}

@end
