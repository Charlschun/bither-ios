//
//  ColdAddressListCell.m
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

#import "ColdAddressListCell.h"
#import "UIBaseUtil.h"
#import "StringUtil.h"
#import "QrUtil.h"
#import "NSString+Size.h"
#import "DialogBlackQrCode.h"
#import "ColdAddressViewController.h"
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

#define kAddressGroupSize (4)
#define kAddressLineSize (12)

@interface ColdAddressListCell()<DialogPrivateKeyOptionsDelegate,DialogPasswordDelegate>{
    BTAddress * _btAddress;
    PrivateKeyQrCodeType _qrcodeType;

}
@property (weak, nonatomic) IBOutlet UIImageView *ivType;
@property (weak, nonatomic) IBOutlet UILabel *lblAddress;
@property (weak, nonatomic) IBOutlet UIView *vAddressContainer;
@property (weak, nonatomic) IBOutlet UIImageView *ivQr;
@property (weak, nonatomic) IBOutlet UIView *vQr;
@property (weak, nonatomic) IBOutlet UIView *vContainer;
@property (strong, nonatomic) UILongPressGestureRecognizer * longPress;
@end

@implementation ColdAddressListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
    }
    return self;
}
-(void)showAddress:(BTAddress *)address{
    _btAddress = address;
    self.lblAddress.text = [StringUtil formatAddress:address.address groupSize:kAddressGroupSize lineSize:kAddressLineSize];
    if (self.longPress==nil) {
        self.longPress=[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTableviewCellLongPressed:)];
        
    }
    if (![[self.ivType gestureRecognizers] containsObject:self.longPress]) {
        [self.ivType addGestureRecognizer:self.longPress];
    }
    [self configureAddressFrame];
    self.ivQr.image = [QrUtil qrCodeOfContent:address.address andSize:self.ivQr.frame.size.width withTheme:[QrCodeTheme black]];
}

-(void)configureAddressFrame{
    CGSize lblSize = [self.lblAddress.text sizeWithRestrict:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) font:self.lblAddress.font];
    lblSize.height = ceilf(lblSize.height);
    lblSize.width = ceilf(lblSize.width);
    CGSize containerSize = CGSizeMake(lblSize.width + self.lblAddress.frame.origin.x * 2, lblSize.height + self.lblAddress.frame.origin.y * 2);
    self.vAddressContainer.frame = CGRectMake(self.vAddressContainer.frame.origin.x, (self.vContainer.frame.size.height - containerSize.height)/2, containerSize.width, containerSize.height);
    CGFloat qrSize = containerSize.height;
    self.vQr.frame = CGRectMake(self.vContainer.frame.size.width - qrSize - self.vAddressContainer.frame.origin.x, self.vAddressContainer.frame.origin.y, qrSize, qrSize);
}

- (IBAction)qrPressed:(id)sender {
    [[[DialogBlackQrCode alloc]initWithContent:_btAddress.address]showInWindow:self.window];
}

- (IBAction)copyAddressPressed:(id)sender {
    [UIPasteboard generalPasteboard].string = _btAddress.address;
    UIViewController *ctr = self.getUIViewController;
    if([ctr isKindOfClass:[ColdAddressViewController class]]){
        ColdAddressViewController* cctr = (ColdAddressViewController*)ctr;
        if([cctr respondsToSelector:@selector(showMsg:)]){
            [cctr showMsg:NSLocalizedString(@"Address copied.", nil)];
        }
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    [super setHighlighted:highlighted animated:animated];
}

- (void) handleTableviewCellLongPressed:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state==UIGestureRecognizerStateBegan) {
        DialogAddressLongPressOptions *dialogPrivateKeyOptons=[[DialogAddressLongPressOptions alloc] initWithAddress:_btAddress andDelegate:self];
        [dialogPrivateKeyOptons showInWindow:self.window];
       
    }
    
}

//DialogPrivateKeyOptionsDelegate
-(void)stopMonitorAddress{
  
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
            response=nil;
            bpassword=nil;
            
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
