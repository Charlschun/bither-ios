//  UserDefaultsUtil.h
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
#import "StringUtil.h"
#import "BitherSetting.h"
#import "BTPasswordSeed.h"


///@description   UserDefaults相关
@interface UserDefaultsUtil : NSObject
+ (UserDefaultsUtil *)instance;


-(NSInteger)getLastVersion;
-(void)setLastVersion:(NSInteger) version;

-(MarketType) getDefaultMarket;
-(void)setMarket:(MarketType) marketType;

-(void)setExchangeType:(ExchangeType ) exchangeType;
-(ExchangeType)getDefaultExchangeType;


-(long long)getLastCheckPrivateKeyTime;
-(void)setLastCheckPrivateKeyTime:(long long)time;

-(long long)getLastBackupKeyTime;
-(void)setLastBackupKeyTime:(long long) time;
-(BOOL)hasPrivateKey;

-(void)setHasPrivateKey:(BOOL) hasPrivateKey;

-(BOOL)getSyncBlockOnlyWifi;
-(void)setSyncBlockOnlyWifi:(BOOL)onlyWifi;
-(BOOL)getDownloadSpvFinish;
-(void)setDownloadSpvFinish:(BOOL)finish;
-(BTPasswordSeed *)getPasswordSeed;
-(void)setPasswordSeed:(BTPasswordSeed *)passwordSeed;

-(TransactionFeeMode) getTransactionFeeMode;
-(void)setTransactionFeeMode :(TransactionFeeMode ) feeMode;
-(BOOL) hasUserAvatar;
-(NSString *)getUserAvatar;
-(void) setUserAvatar:(NSString *)avatar;
-(NSInteger) getQrCodeTheme;
-(void)setQrCodeTheme:(NSInteger) qrCodeTheme;






@end
