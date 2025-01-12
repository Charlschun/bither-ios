//
//  BitherSetting.h
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
#import "MKNetworkEngine.h"
#import "BTSettings.h"

#define BitherMarketUpdateNotification  @"BitherMarketUpdateNotification"
#define BitherAddressNotification  @"BitherAddressNotification"
#define DONATE_ADDRESS  @"1BsTwoMaX3aYx9Nc8GdgHZzzAGmG669bC3"
#define DONATE_AMOUNT (100000)

#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]
#define PRIVATE_KEY_OF_HOT_COUNT_LIMIT (10)
#define PRIVATE_KEY_OF_COLD_COUNT_LIMIT (100)


#define FORMAT_TIMESTAMP_INTERVAL 1000

#define ColorTextGray1 [UIColor colorWithWhite:0.78 alpha:1.0]
#define ColorTextGray2 [UIColor colorWithWhite:0.42 alpha:1.0]
#define ColorUserName [UIColor colorWithRed:100.0/255 green:129.0/255 blue:157.0/255 alpha:1.0]
#define ColorAmt [UIColor colorWithRed:1 green:133.0 / 255 blue:44.0 /255 alpha:1]
#define ColorTableHeader [UIColor colorWithRed:241.0/255 green:241.0/255 blue:241.0/255 alpha:0.9]
#define ColorBg [UIColor colorWithRed:66.0/255 green:94.0/255 blue:122.0/255 alpha:1.0]
#define ColorProgress [UIColor colorWithRed:29.0/255 green:86.0/255 blue:119.0/255 alpha:1.0]
#define ColorDivide [UIColor colorWithWhite:0.86 alpha:1.0]
#define ColorButton [UIColor colorWithRed:50.0/255 green:79.0/255 blue:133.0/255 alpha:1.0]

#define ColorAmtIncoming [UIColor colorWithRed:117.0/255.0 green:193.0 / 255.0 blue:27.0 /255.0 alpha:1]
#define ColorAmtOutgoing [UIColor colorWithRed:254.0/255.0 green:118.0 / 255.0 blue:18.0 /255.0 alpha:1]

#define CardMargin 10.0f
#define CardTopOffset 9.0f
#define CardBottomOffset 5.0f
#define CardCornerRedius 8.0f

#define ColorTextGray1 [UIColor colorWithWhite:0.78 alpha:1.0]
#define ColorTextGray2 [UIColor colorWithWhite:0.42 alpha:1.0]
#define ColorUserName [UIColor colorWithRed:100.0/255 green:129.0/255 blue:157.0/255 alpha:1.0]
#define ColorAmt [UIColor colorWithRed:1 green:133.0 / 255 blue:44.0 /255 alpha:1]
#define ColorTableHeader [UIColor colorWithRed:241.0/255 green:241.0/255 blue:241.0/255 alpha:0.9]
#define ColorProgress [UIColor colorWithRed:29.0/255 green:86.0/255 blue:119.0/255 alpha:1.0]
#define ColorDivide [UIColor colorWithWhite:0.86 alpha:1.0]
#define ColorButton [UIColor colorWithRed:50.0/255 green:79.0/255 blue:133.0/255 alpha:1.0]

#define CardMargin 10.0f
#define CardTopOffset 9.0f
#define CardBottomOffset 5.0f
#define CardCornerRedius 8.0f

#define ImageCompressionQuality 0.445

#define NavHeight 44.0f
#define TabBarHeight 44.0f
#define QR_CODE_SPLIT @":"


typedef void (^DictResponseBlock)(NSDictionary *dict);
typedef void (^IdResponseBlock)(id response);
typedef void (^ArrayResponseBlock)(NSArray *array);
typedef void (^ImageResponseBlock)(UIImage *image, NSURL *url);
typedef void (^ErrorHandler)(MKNetworkOperation *errorOp, NSError* error);
typedef void (^CompletedOperation)(MKNetworkOperation *completedOperation);
typedef void (^ResponseFormat)(MKNetworkOperation *completedOperation);
typedef void (^LongResponseBlock)(long long num);
typedef void (^StirngBlock)(NSString * string);
typedef void (^VoidBlock)(void);
typedef void (^ErrorBlock)(NSError * error);
typedef void (^ViewControllerBlock)(UIViewController * controller);
typedef NSString * (^GetValueBlock)(void);
typedef NSArray *(^GetArrayBlock) (void);




typedef enum  {
     BITSTAMP=1, BTCE=2, HUOBI=3, OKCOIN=4, BTCCHINA=5, CHBTC=6
}MarketType;

typedef enum  {
    ONE_MINUTE=1, FIVE_MINUTES=5, ONE_HOUR=60, ONE_DAY=1440
}KLineTimeType;

typedef enum  {
    Normal=10000 ,Low=1000
}TransactionFeeMode;

typedef enum {
    USD,CNY
}ExchangeType;

typedef enum {
    AddressNormal, AddressTxTooMuch, AddressSpecialAddress
}AddressType;

#define CustomErrorDomain @"www.bither.net"
typedef enum {
    
PasswordError = -1000,
    
}CustomErrorFailed;

typedef enum{
    Text,Encrypted,Decrypetd
} PrivateKeyQrCodeType;


@interface BitherSetting : NSObject

+(NSString *)getMarketName:(MarketType )marketType;
+(NSString *)getMarketDomain:(MarketType )marketType;
+(NSString *)getExchangeSymbol:(ExchangeType) exchangeType;
+(NSString *)getExchangeName:(ExchangeType)exchangeType;
+(NSString *)getTransactionFeeMode:(TransactionFeeMode)transactionFee;
+(UIColor *) getMarketColor:(MarketType )marketType;

@end
