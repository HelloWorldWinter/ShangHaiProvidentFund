//
//  CDJSONBaseNetworkService.m
//  ProvidentFund
//
//  Created by cdd on 15/12/9.
//  Copyright © 2015年 9188. All rights reserved.
//

#import "CDJSONBaseNetworkService.h"
#import "CDPointActivityIndicator.h"
#import "CDNetworkRequestManager.h"
#import "CDGlobalHTTPSessionManager.h"
#import <YYCache/YYCache.h>
#import "NSDictionary+CDDictionaryAdditions.h"
#import "NSString+CDEncryption.h"

@interface CDJSONBaseNetworkService ()

@property (nonatomic, strong) NSURLSessionDataTask *currentTask;
@property (nonatomic, strong) CDGlobalHTTPSessionManager *manager;
@property (nonatomic, copy) NSString *cacheURLStringID;
@property (nonatomic, strong) YYCache *cache;

@end

@implementation CDJSONBaseNetworkService

- (instancetype)init {
    return [self initWithDelegate:nil];
}

- (instancetype)initWithDelegate:(id <CDJSONBaseNetworkServiceDelegate>)delegate {
    if (self = [super init]) {
        _isLoaded = NO;
        _delegate = delegate;
        _httpRequestMethod = kHttpRequestTypePOST;
        _toCacheData=NO;
        _isIgnoreCache=YES;
    }
    return self;
}

- (CDGlobalHTTPSessionManager *)manager{
    if (_manager==nil) {
        _manager = [CDGlobalHTTPSessionManager sharedManager];
    }
    return _manager;
}

- (YYCache *)cache{
    if (_cache==nil) {
        _cache=[YYCache cacheWithName:self.cacheURLStringID];
    }
    return _cache;
}

- (void)request:(NSString *)urlString params:(id)params {
    if (!urlString || urlString.length == 0) { return; }
    [self resetNetworkService];
    
    /**
     *  先使用缓存数据
     */
    if (self.toCacheData && !self.isIgnoreCache) {
        NSString *paramsString = (params==nil ? @"" : [params cd_TransformToParamStringWithMethod:(kHttpRequestTypeGET)]);
        self.cacheURLStringID=[[NSString stringWithFormat:@"%@%@",urlString,paramsString] cd_md5HexDigest];
        if ([self.cache containsObjectForKey:self.cacheURLStringID]) {
            CDLog(@"使用缓存数据:%@",urlString);
            _isUseCache=YES;
            [self succeedGetResponse:[self.cache objectForKey:self.cacheURLStringID]];
        }
    }
    
    WS(weakSelf);
    switch (_httpRequestMethod) {
        case kHttpRequestTypePOST: {
            self.currentTask = [self.manager POST:urlString parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSError *error=nil;
                id responseObj=[NSJSONSerialization JSONObjectWithData:responseObject options:(NSJSONReadingMutableContainers) error:&error];
                if (!error) {
                    if ([weakSelf isKindOfClass:[CDJSONBaseNetworkService class]]) {
                        _isLoaded = YES;
                        [weakSelf taskDidFinish:task responseObject:responseObj];
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if ([weakSelf isKindOfClass:[CDJSONBaseNetworkService class]]) {
                    [weakSelf taskDidFail:task error:error];
                }
            }];
            
        }   break;
        case kHttpRequestTypeGET: {
            self.currentTask = [self.manager GET:urlString parameters:params progress:^(NSProgress * _Nonnull downloadProgress) {
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                NSError *error=nil;
                id responseObj=[NSJSONSerialization JSONObjectWithData:responseObject options:(NSJSONReadingMutableContainers) error:&error];
                if (!error) {
                    if ([weakSelf isKindOfClass:[CDJSONBaseNetworkService class]]) {
                        _isLoaded = YES;
                        [weakSelf taskDidFinish:task responseObject:responseObj];
                    }
                }
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                if ([weakSelf isKindOfClass:[CDJSONBaseNetworkService class]]) {
                    [weakSelf taskDidFail:task error:error];
                }
            }];
        }   break;
    }
    
    //打印请求信息
    _isLoading=YES;
    [CDNetworkRequestManager addService:self];
    //打印请求信息
    CDLog(@">>> %@ Request URL: %@ Parameters:\n%@",(_httpRequestMethod==kHttpRequestTypePOST ? @"POST":@"GET"),urlString,params);
}

- (NSString *)requsetURLString{
    return self.currentTask.currentRequest.URL.absoluteString;
}

/* 请求完成 */
- (void)taskDidFinish:(NSURLSessionTask *)task responseObject:(id)responseObject {
    CDLog(@">>> URL: %@ Response Data: %@ ", task.currentRequest.URL,responseObject);
    if (task.state == NSURLSessionTaskStateCompleted) {
        _isLoaded = YES;
        _isLoading=NO;
        _isUseCache=NO;
        [self succeedGetResponse:responseObject];
        self.currentTask = nil;
        [CDNetworkRequestManager removeService:self];
    }
}

/* 请求失败 */
- (void)taskDidFail:(NSURLSessionTask *)task error:(NSError *)error {
    CDLog(@">>> URL: %@ Response Error: %@", task.currentRequest.URL,error.localizedDescription);
    if (task.state == NSURLSessionTaskStateCompleted || task.state == NSURLSessionTaskStateCanceling) {
        _isLoading=NO;
        if (error.code==NSURLErrorBadServerResponse) {
            if (self.toCacheData && [self.cache containsObjectForKey:self.cacheURLStringID]) {
                CDLog(@"使用缓存数据(BadServer)%@",task.currentRequest.URL.absoluteString);
                _isUseCache=YES;
                [self succeedGetResponse:[self.cache objectForKey:self.cacheURLStringID]];
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(service:didFailLoadWithError:)]) {
            [self.delegate service:self didFailLoadWithError:error];
        }
        self.currentTask = nil;
        [CDNetworkRequestManager removeService:self];
    }
}

- (void)cancel {
    if (!self.currentTask || self.currentTask.state == NSURLSessionTaskStateCanceling || self.currentTask.state == NSURLSessionTaskStateCompleted) {
        return;
    }
    [self.currentTask cancel];
    if (_delegate && [_delegate respondsToSelector:@selector(serviceDidCancel:)]) {
        [_delegate serviceDidCancel:self];
    }
    self.currentTask=nil;
    [CDNetworkRequestManager removeService:self];
}

- (void)succeedGetResponse:(id)responseObject{
    _rootData = responseObject;
//    if ([_rootData isKindOfClass:[NSDictionary class]]) {
//        id returnCode = [_rootData objectForKey:@"code"];
//        if ([returnCode isKindOfClass:[NSNumber class]]) {
//            _returnCode = [NSString stringWithFormat:@"%@",returnCode];
//        } else if ([returnCode isKindOfClass:[NSString class]]) {
//            _returnCode = returnCode;
//        }
//        _desc = [_rootData objectForKey:@"desc"];
//    }
    [self requestDidFinish:_rootData];
    if (self.delegate && [self.delegate respondsToSelector:@selector(serviceDidFinished:)]) {
        [self.delegate serviceDidFinished:self];
    }
}

/**
 *  子类可覆写，把请求到的数据转换成模型
 */
- (void)requestDidFinish:(id)rootData {
    if (self.toCacheData && self.cacheURLStringID && _returnCode==1) {
        [self.cache setObject:rootData forKey:self.cacheURLStringID];
    }
}

- (void)resetNetworkService{
    [self.currentTask cancel];
    self.currentTask=nil;
    _isLoading=NO;
    _isUseCache=NO;
    [CDNetworkRequestManager removeService:self];
}

@end
