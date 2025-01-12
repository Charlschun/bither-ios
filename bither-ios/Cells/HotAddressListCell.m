//
//  HotAddressListCell.m
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

#import "HotAddressListCell.h"
#import "StringUtil.h"
#import "TransactionConfidenceView.h"
#import "AmountButton.h"
#import "NSAttributedString+Size.h"
#import "UIBaseUtil.h"
#import "DialogAddressFull.h"
#import "MarketUtil.h"
#import "DialogAddressLongPressOptions.h"
#import "DialogPassword.h"
#import "DialogPrivateKeyEncryptedQrCode.h"
#import "DialogPrivateKeyDecryptedQrCode.h"
#import "DialogProgress.h"
#import "DialogPrivateKeyText.h"
#import "DialogAlert.h"
#import "KeyUtil.h"
#import "HotAddressViewController.h"
#import "BitherSetting.h"
#import "UIImage+ImageRenderToColor.h"

#define kUnconfirmedTxAmountLeftMargin (3)

#define kBalanceFontSize (19)

@interface HotAddressListCell ()<DialogAddressFullDelegate,DialogPrivateKeyOptionsDelegate,DialogPasswordDelegate>{
    BTAddress * _btAddress;
    PrivateKeyQrCodeType _qrcodeType;
}

@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UILabel *lblBalanceBtc;
@property (weak, nonatomic) IBOutlet UILabel *lblBalanceMoney;
@property (weak, nonatomic) IBOutlet UIImageView *ivType;
@property (weak, nonatomic) IBOutlet UILabel *lblTransactionCount;
@property (weak, nonatomic) IBOutlet UIImageView *ivHighlighted;
@property (weak, nonatomic) IBOutlet UIView *vNoUnconfirmedTx;
@property (weak, nonatomic) IBOutlet UIView *vUnconfirmedTx;
@property (weak, nonatomic) IBOutlet TransactionConfidenceView *vUnconfirmedTxConfidence;
@property (weak, nonatomic) IBOutlet AmountButton *vUnconfirmedTxAmount;
@property (weak, nonatomic) IBOutlet UIButton *btnAddressFull;
@property (strong, nonatomic) UILongPressGestureRecognizer * longPress;
@property (weak, nonatomic) IBOutlet UIImageView *ivSymbolBtc;

@end

@implementation HotAddressListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
    }
    return self;
}

-(void)setAddress:(BTAddress*)address{
    _btAddress=address;
    self.vUnconfirmedTxAmount.alignLeft = YES;
    self.lblAddress.text = [StringUtil shortenAddress:address.address];
    CGFloat width = [self widthForLabel:self.lblAddress maxWidth:self.frame.size.width];
    self.lblAddress.frame = CGRectMake(self.lblAddress.frame.origin.x, self.lblAddress.frame.origin.y, width, self.lblAddress.frame.size.height);
    if (self.longPress==nil) {
        self.longPress=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewCellLongPressed:)];
        
    }
    if (![[self.ivType gestureRecognizers] containsObject:self.longPress]) {
        [self.ivType addGestureRecognizer:self.longPress];
    }
    if(address.hasPrivKey){
        self.ivType.image = [UIImage imageNamed:@"address_type_private"];
    }else{
        self.ivType.image = [UIImage imageNamed:@"address_type_watchonly"];
    }
    
    self.lblBalanceBtc.attributedText = [StringUtil attributedStringForAmount:address.balance withFontSize:kBalanceFontSize];
    
    width = [self.lblBalanceBtc.attributedText sizeWithRestrict:CGSizeMake(CGFLOAT_MAX, self.lblBalanceBtc.frame.size.height)].width;
    self.lblBalanceBtc.frame = CGRectMake(CGRectGetMaxX(self.lblBalanceBtc.frame) - width, self.lblBalanceBtc.frame.origin.y, width, self.lblBalanceBtc.frame.size.height);
    self.ivSymbolBtc.frame = CGRectMake(CGRectGetMinX(self.lblBalanceBtc.frame) - self.ivSymbolBtc.frame.size.width - 2, self.ivSymbolBtc.frame.origin.y, self.ivSymbolBtc.frame.size.width, self.ivSymbolBtc.frame.size.height);
    self.lblTransactionCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)[address txCount]];
    NSArray *txs;
    if([address txCount] > 0 && (txs = [address getRecentlyTxsWithConfirmationCntLessThan:6 andLimit:1]) && txs.count > 0){
        self.vNoUnconfirmedTx.hidden = YES;
        self.vUnconfirmedTx.hidden = NO;
        BTTx *tx = [txs objectAtIndex:0];
        [self.vUnconfirmedTxConfidence showTransaction:tx];
        self.vUnconfirmedTxAmount.amount = [tx deltaAmountFrom:address];
        CGRect frame = self.vUnconfirmedTxAmount.frame;
        frame.origin.x = CGRectGetMaxX(self.vUnconfirmedTxConfidence.frame) + kUnconfirmedTxAmountLeftMargin;
        self.vUnconfirmedTxAmount.frame = frame;
    }else{
        self.vNoUnconfirmedTx.hidden = NO;
        self.vUnconfirmedTx.hidden = YES;
    }
    CGRect frame = self.btnAddressFull.frame;
    frame.origin.x = CGRectGetMaxX(self.lblAddress.frame) + 5;
    self.btnAddressFull.frame = frame;
    if ([MarketUtil getDefaultNewPrice]>0) {
        double balanceMoney=([MarketUtil getDefaultNewPrice]*address.balance)/pow(10, 8);
        self.lblBalanceMoney.text=[StringUtil formatPrice:balanceMoney];
    }else{
        self.lblBalanceMoney.text=@"--";
    }
    if(!self.ivSymbolBtc.image){
        self.ivSymbolBtc.image = [[UIImage imageNamed:@"symbol_btc_slim"] renderToColor:self.lblBalanceBtc.textColor];
        frame = self.ivSymbolBtc.frame;
        CGFloat height = frame.size.height;
        width = frame.size.height / self.ivSymbolBtc.image.size.height * self.ivSymbolBtc.image.size.width;
        CGFloat x = frame.origin.x - (width - frame.size.width);
        frame.origin.x = x;
        frame.size.width = width;
        frame.size.height = height;
        self.ivSymbolBtc.frame = frame;
    }
}

-(CGFloat)widthForLabel:(UILabel*)lbl maxWidth:(CGFloat)maxWidth{
    CGFloat width = [lbl.text boundingRectWithSize:CGSizeMake(maxWidth, lbl.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: lbl.font, NSParagraphStyleAttributeName:[NSParagraphStyle defaultParagraphStyle]} context:nil].size.width;
    width = ceilf(width);
    return width;
}
- (IBAction)addressFullPressed:(id)sender {
    [[[DialogAddressFull alloc]initWithDelegate:self]showFromView:self.btnAddressFull];
}

-(NSUInteger)dialogAddressFullRowCount{
    return 1;
}

-(NSString*)dialogAddressFullAddressForRow:(NSUInteger)row{
    return _btAddress.address;
}

-(int64_t)dialogAddressFullAmountForRow:(NSUInteger)row{
    return 0;
}

-(BOOL)dialogAddressFullDoubleColumn{
    return NO;
}

-(void)showMsg:(NSString*)msg{
    UIViewController* ctr = self.getUIViewController;
    if([ctr respondsToSelector:@selector(showMsg:)]){
        [ctr performSelector:@selector(showMsg:) withObject:msg];
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [super setHighlighted:highlighted animated:animated];
    self.ivHighlighted.highlighted = highlighted;
}

- (void) handleTableviewCellLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state==UIGestureRecognizerStateBegan) {
        DialogAddressLongPressOptions *dialogPrivateKeyOptons=[[DialogAddressLongPressOptions alloc] initWithAddress:_btAddress andDelegate:self];
        [dialogPrivateKeyOptons showInWindow:self.window];
    
    }
    
}

//DialogPrivateKeyOptionsDelegate
-(void)stopMonitorAddress{
    [[[DialogAlert alloc]initWithMessage:NSLocalizedString(@"Sure to stop monitoring this address?", nil) confirm:^{
        [KeyUtil stopMonitor:_btAddress];
        if (self.viewController&&[self.viewController isMemberOfClass:[HotAddressViewController class]]) {
            HotAddressViewController * hotAddressViewController=(HotAddressViewController*)self.viewController;
            [hotAddressViewController reload];
        }
    } cancel:nil]showInWindow:self.window];
}

-(void)resetMonitorAddress{
}

-(void)showPrivateKeyDecryptedQrCode{
    _qrcodeType=Decrypetd;
    DialogPassword *dialog = [[DialogPassword alloc]initWithDelegate:self];
    [dialog showInWindow:self.window];
}

-(void)showPrivateKeyEncryptedQrCode{
    _qrcodeType=Encrypted;
    DialogPassword *dialog = [[DialogPassword alloc]initWithDelegate:self];
    [dialog showInWindow:self.window];
}

-(void)showPrivateKeyTextQrCode{
    _qrcodeType=Text;
    DialogPassword *dialog = [[DialogPassword alloc]initWithDelegate:self];
    [dialog showInWindow:self.window];
}

//DialogPasswordDelegate
-(void)onPasswordEntered:(NSString *)password{
    __block NSString * bpassword=password;
    password=nil;
    if(_qrcodeType==Encrypted){
        DialogPrivateKeyEncryptedQrCode *dialog = [[DialogPrivateKeyEncryptedQrCode alloc]initWithAddress:_btAddress];
        [dialog showInWindow:self.window];
    }else{
        DialogProgress *dialogProgress=[[DialogProgress alloc] initWithMessage:NSLocalizedString(@"Please wait…", nil)];
        [dialogProgress showInWindow:self.window];
        [self decrypted:bpassword callback:^(id response) {
            [dialogProgress dismiss];
            if (_qrcodeType==Decrypetd) {
                DialogPrivateKeyDecryptedQrCode *dialogPrivateKey=[[DialogPrivateKeyDecryptedQrCode alloc] initWithAddress:response];
                [dialogPrivateKey showInWindow:self.window];
                
            }else{
                DialogPrivateKeyText *dialogPrivateKeyText=[[DialogPrivateKeyText alloc] initWithPrivateKeyStr:response];
                [dialogPrivateKeyText showInWindow:self.window];
            
            }
            bpassword=nil;
            response=nil;
        } ];
    }

}
-(void)decrypted:(NSString*)password callback:(IdResponseBlock )callback{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^{
        BTKey * key =[BTKey keyWithBitcoinj:_btAddress.encryptPrivKey andPassphrase:password];
        __block NSString * privateKey=key.privateKey;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (callback) {
                callback(privateKey);
            }
        });
        key=nil;
    });
}

@end
