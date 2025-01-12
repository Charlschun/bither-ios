//  BaseApi.h
//  bither-ios
//
//  Copyright 2014 http://Bither.net
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import <Foundation/Foundation.h>
#import "BitherEngine.h"

#define BITHER_GET_COOKIE_URL @"api/v1/cookie"
#define BITHER_GET_ONE_SPVBLOCK_API @"api/v1/block/spv/one"

#define BITHER_Q_MYTRANSACTIONS @"api/v1/address/%@/transaction"
#define BITHER_ERROR_API  @"api/v1/error"
#define BITHER_EXCHANGE_TICKER @"api/v1/exchange/ticker"
#define BITHER_KLINE_URL @"api/v1/exchange/%d/kline/%d"
#define BITHER_DEPTH_URL @"api/v1/exchange/%d/depth"
#define BITHER_TREND_URL @"api/v1/exchange/%d/trend"
#define BITHER_UPLOAD_AVATAR @"api/v1/avatar"
#define BITHER_DOWNLOAD_AVATAR @"api/v1/avatar"




@interface BaseApi : NSObject

#pragma mark-get
-(void)get:(NSString *)url withParams:(NSDictionary *) params networkType:(BitherNetworkType) networkType completed:(CompletedOperation) completedOperationParam andErrorCallback:(ErrorHandler) errorCallback;


#pragma mark-post
-(void)post:(NSString *)url withParams:(NSDictionary *) params networkType:(BitherNetworkType) networkType completed:(CompletedOperation) completedOperationParam andErrorCallBack:(ErrorHandler) errorCallback;

@end
