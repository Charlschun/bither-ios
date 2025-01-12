//
//  TransactionCell.m
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

#import "TransactionCell.h"
#import "AmountButton.h"
#import "StringUtil.h"
#import "DateUtil.h"
#import "TransactionConfidenceView.h"
#import "DialogAddressFull.h"
#import "NSString+Size.h"
#import "UIBaseUtil.h"

#define kConfidenceIconRightMargin (10)

@interface TransactionCell()<DialogAddressFullDelegate, AmountButtonFrameChangeListener>{
    BTAddress* _address;
    BTTx *_tx;
    NSMutableDictionary* _addresses;
    BOOL _income;
    NSArray *_sortedAddresses;
}
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblTime;
@property (weak, nonatomic) IBOutlet AmountButton *btnAmount;
@property (weak, nonatomic) IBOutlet TransactionConfidenceView *vTransactionConfidence;
@property (weak, nonatomic) IBOutlet UIButton *btnTransactionFull;
@end

@implementation TransactionCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)showTx:(BTTx*)tx byAddress:(BTAddress*)address{
    _tx = tx;
    _address = address;
    _addresses = [[NSMutableDictionary alloc]init];
    self.btnAmount.frameChangeListener = self;
    int64_t value = [tx deltaAmountFrom:address];
    [self.btnAmount setAmount:value];
    self.lblTime.text = [DateUtil stringFromDate:[NSDate dateWithTimeIntervalSince1970:tx.txTime]];
    _income = value > 0;
    NSString *a = @"---";
    if(_income){
        NSUInteger count = tx.inputAddresses.count;
        for(int k = 0; k < count;k++){
            NSObject *ai = [tx.inputAddresses objectAtIndex:k];
            if(ai != [NSNull null]){
                if(![StringUtil compareString:address.address compare:(NSString*)ai] && a.length < 30){
                    a = (NSString*)ai;
                }
                NSObject* value = _addresses[ai];
                NSObject* newValue = _tx.inValues[k];
                if(value != nil && value != [NSNull null]){
                    u_int64_t delta = 0;
                    if(newValue != nil && newValue != [NSNull null]){
                        delta = [(NSNumber*)newValue unsignedLongLongValue];
                    }
                    value = [NSNumber numberWithUnsignedLongLong:(delta + [(NSNumber*)value unsignedLongLongValue])];
                }else{
                    value = newValue;
                }
                _addresses[(NSString*)ai] = value;
            }
        }
    }else{
        NSUInteger count = tx.outputAddresses.count;
        for(int k = 0; k < count;k++){
            NSObject *ai = [tx.outputAddresses objectAtIndex:k];
            if(ai != [NSNull null]){
                if(![StringUtil compareString:address.address compare:(NSString*)ai] && a.length < 30){
                    a = (NSString*)ai;
                }
                NSObject* value = _addresses[ai];
                NSObject* newValue = _tx.outputAmounts[k];
                if(value != nil && value != [NSNull null]){
                    u_int64_t delta = 0;
                    if(newValue != nil && newValue != [NSNull null]){
                        delta = [(NSNumber*)newValue unsignedLongLongValue];
                    }
                    value = [NSNumber numberWithUnsignedLongLong:(delta + [(NSNumber*)value unsignedLongLongValue])];
                }else{
                    value = newValue;
                }
                _addresses[(NSString*)ai] = value;
            }
        }
    }
    _sortedAddresses = [_addresses.allKeys sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        if([StringUtil compareString:obj1 compare:_address.address]){
            return NSOrderedDescending;
        }else if([StringUtil compareString:obj2 compare:_address.address]){
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    }];
    if(a.length > 4){
        a = [StringUtil shortenAddress:a];
    }
    [self.vTransactionConfidence showTransaction:tx];
    self.lblAddress.text = a;
    
    CGFloat width = [self.lblAddress.text sizeWithRestrict:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) font:self.lblAddress.font].width;
    CGRect frame = self.lblAddress.frame;
    frame.size.width = width;
    self.lblAddress.frame = frame;
    
    frame = self.btnTransactionFull.frame;
    frame.origin.x = CGRectGetMaxX(self.lblAddress.frame) + 5;
    self.btnTransactionFull.frame = frame;
}

-(void)amountButtonFrameChanged:(CGRect)frame{
    self.vTransactionConfidence.frame = CGRectMake(frame.origin.x - self.vTransactionConfidence.frame.size.width - kConfidenceIconRightMargin, self.vTransactionConfidence.frame.origin.y, self.vTransactionConfidence.frame.size.width, self.vTransactionConfidence.frame.size.height);
}

- (IBAction)transactionFullPressed:(id)sender {
    [[[DialogAddressFull alloc]initWithDelegate:self]showFromView:self.btnTransactionFull];
}

-(NSUInteger)dialogAddressFullRowCount{
    if(_sortedAddresses && _sortedAddresses.count > 0){
        return _sortedAddresses.count;
    }else{
        return 1;
    }
}

-(NSString*)dialogAddressFullAddressForRow:(NSUInteger)row{
    if(_sortedAddresses && _sortedAddresses.count > 0){
        NSString* address = _sortedAddresses[row];
        if([StringUtil compareString:address compare:_address.address]){
            return NSLocalizedString(@"Me", nil);
        }else{
            return address;
        }
    }else{
        return NSLocalizedString(@"Unknown Address", nil);
    }
}

-(int64_t)dialogAddressFullAmountForRow:(NSUInteger)row{
    if(_sortedAddresses && _sortedAddresses.count > 0){
        NSObject* value = _addresses[_sortedAddresses[row]];
        if(value != nil && value != [NSNull null]){
            return [(NSNumber*)value unsignedLongLongValue];
        }else{
            return 0;
        }
    }else{
        return 0;
    }
}

-(BOOL)dialogAddressFullDoubleColumn{
    return _sortedAddresses && _sortedAddresses.count > 0;
}

-(void)showMsg:(NSString*)msg{
    UIViewController* ctr = self.getUIViewController;
    if([ctr respondsToSelector:@selector(showMessage:)]){
        [ctr performSelector:@selector(showMessage:) withObject:msg];
    }
}

@end
