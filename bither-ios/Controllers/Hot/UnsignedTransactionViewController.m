//
//  UnsignedTransactionViewController.m
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

#import "UnsignedTransactionViewController.h"
#import "BitherSetting.h"
#import "ScanQrCodeTransportViewController.h"
#import "QrCodeViewController.h"
#import "StringUtil.h"
#import "NSString+Base58.h"
#import "ScanQrCodeViewController.h"
#import "DialogProgress.h"
#import "UserDefaultsUtil.h"
#import "UIViewController+PiShowBanner.h"
#import "DialogSendTxConfirm.h"
#import "NSString+Base58.h"
#import "QRCodeTxTransport.h"
#import "PeerUtil.h"
#import "TransactionsUtil.h"
#import <Bitheri/BTAddressManager.h>
#import <Bitheri/BTSettings.h>
#import <Bitheri/BTPeerManager.h>

#define kBalanceFontSize (15)
#define kSendButtonQrIconSize (20)

@interface UnsignedTransactionViewController ()<UITextFieldDelegate,ScanQrCodeDelegate,DialogSendTxConfirmDelegate>
@property (weak, nonatomic) IBOutlet UILabel *lblBalancePrefix;
@property (weak, nonatomic) IBOutlet UILabel *lblBalance;
@property (weak, nonatomic) IBOutlet UILabel *lblPayTo;
@property (weak, nonatomic) IBOutlet UITextField *tfAddress;
@property (weak, nonatomic) IBOutlet UITextField *tfAmount;
@property (weak, nonatomic) IBOutlet UIButton *btnSend;
@property (weak, nonatomic) IBOutlet UIView *vTopBar;

@property BTTx* tx;
@end

@implementation UnsignedTransactionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    UIImageView *ivSendQr = [[UIImageView alloc]initWithImage:[UIImage imageNamed:@"unsigned_transaction_button_icon"]];
    CGFloat ivSendQrMargin = (self.btnSend.frame.size.height - kSendButtonQrIconSize)/2;
    ivSendQr.frame = CGRectMake(self.btnSend.frame.size.width - kSendButtonQrIconSize - ivSendQrMargin, ivSendQrMargin, kSendButtonQrIconSize, kSendButtonQrIconSize);
    [self.btnSend addSubview:ivSendQr];
    [self configureBalance];
    self.tfAddress.delegate = self;
    self.tfAmount.delegate = self;
    [self configureTextField:self.tfAddress];
    [self configureTextField:self.tfAmount];
    if(self.toAddress){
        self.tfAddress.text = self.toAddress;
        self.tfAddress.enabled = NO;
        if(self.amount > 0){
            self.tfAmount.text = [StringUtil stringForAmount:self.amount];
        }
    }
    [self check];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [BTSettings instance].feeBase = ([[UserDefaultsUtil instance] getTransactionFeeMode] == Low ? 1000 : 10000);
    if(self.tx){
        self.btnSend.enabled = YES;
    }
    if (![[BTPeerManager sharedInstance] connected]) {
        [[PeerUtil instance] startPeer];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if(!self.tx){
        if(self.tfAddress.enabled){
            [self.tfAddress becomeFirstResponder];
        }else{
            [self.tfAmount becomeFirstResponder];
        }
    }
}

- (IBAction)sendPressed:(id)sender {
    if([self checkValues]){
        [self hideKeyboard];
        self.btnSend.enabled = NO;
        DialogProgress *dp = [[DialogProgress alloc]initWithMessage:NSLocalizedString(@"Please wait…", nil)];
        [dp showInWindow:self.view.window completion:^{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
                u_int64_t value = [StringUtil amountForString:self.tfAmount.text];
                NSError * error;
                self.tx = [self.address txForAmounts:@[@(value)] andAddress:@[self.tfAddress.text] andError:&error];
                if (error) {
                    NSString * msg=[TransactionsUtil getCompleteTxForError:error];
                    [self showSendResult:msg dialog:dp];
                }else{
                    if(!self.tx){
                        [self showSendResult:NSLocalizedString(@"Send failed.", nil) dialog:dp];
                        return;
                    }
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [dp dismissWithCompletion:^{
                            DialogSendTxConfirm *dialog = [[DialogSendTxConfirm alloc]initWithTx:self.tx from:self.address to:self.tfAddress.text delegate:self];
                            [dialog showInWindow:self.view.window];
                        }];
                    });
                }
            });
        }];
    }
}


-(void)onSendTxConfirmed:(BTTx*)tx{
    if(!tx){
        return;
    }
    QrCodeViewController *qr = [self.storyboard instantiateViewControllerWithIdentifier:@"QrCode"];
    qr.qrCodeTitle = NSLocalizedString(@"Sign Trasaction", nil);
    qr.qrCodeMsg = NSLocalizedString(@"Scan with Bither Cold", nil);
    qr.cancelWarning = NSLocalizedString(@"Give up signing?", nil);
    QRCodeTxTransport *txTrans = [[QRCodeTxTransport alloc]init];
    txTrans.fee = self.tx.feeForTransaction;
    txTrans.to = [tx amountSentTo:self.tfAddress.text];
    txTrans.myAddress = self.address.address;
    txTrans.toAddress = self.tfAddress.text;
    NSMutableArray *array = [[NSMutableArray alloc]init];
    NSArray *hashDataArray = tx.unsignedInHashes;
    for(NSData *data in hashDataArray){
        [array addObject:[NSString hexWithData:data]];
    }
    txTrans.hashList = array;
    qr.content = [QRCodeTxTransport getPreSignString:txTrans];
    [qr setFinishAction:NSLocalizedString(@"Scan Bither Cold to sign", nil) target:self selector:@selector(scanBitherColdToSign)];
    [self.navigationController pushViewController:qr animated:YES];
}

-(void)scanBitherColdToSign{
    self.btnSend.enabled = NO;
    ScanQrCodeTransportViewController *scan = [[ScanQrCodeTransportViewController alloc]initWithDelegate:self title:NSLocalizedString(@"Scan Bither Cold to sign", nil) pageName:NSLocalizedString(@"Signed TX QR Code", nil)];
    [self presentViewController:scan animated:YES completion:^{
        [self.navigationController popToViewController:self animated:NO];
    }];
}

-(void)finalSend{
    DialogProgress *dp = [[DialogProgress alloc]initWithMessage:NSLocalizedString(@"Please wait…", nil)];
    [dp showInWindow:self.view.window completion:^{
        [[BTPeerManager sharedInstance] publishTransaction:self.tx completion:^(NSError *error) {
            if(!error){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [dp dismissWithCompletion:^{
                        [self.navigationController popViewControllerAnimated:YES];
                        if(self.sendDelegate && [self.sendDelegate respondsToSelector:@selector(sendSuccessed:)]){
                            [self.sendDelegate sendSuccessed:self.tx];
                        }
                    }];
                });
            }else{
                [self showSendResult:NSLocalizedString(@"Send failed.", nil) dialog:dp];
            }
        }];
    }];
}

-(void)onSendTxCanceled{
    self.tx = nil;
    self.btnSend.enabled = YES;
}

-(void)showSendResult:(NSString*)msg dialog:(DialogProgress*)dp{
    dispatch_async(dispatch_get_main_queue(), ^{
        [dp dismissWithCompletion:^{
            [self showBannerWithMessage:msg belowView:self.vTopBar];
        }];
    });
}

- (IBAction)scanPressed:(id)sender {
    ScanQrCodeViewController *scan = [[ScanQrCodeViewController alloc]initWithDelegate:self title:NSLocalizedString(@"Scan Bitcoin Address", nil) message:NSLocalizedString(@"Scan QR Code for Bitcoin address", nil)];
    [self presentViewController:scan animated:YES completion:nil];
}

-(void)handleResult:(NSString*)result byReader:(ScanQrCodeViewController*)reader{
    [reader dismissViewControllerAnimated:YES completion:^{
        if(![reader isKindOfClass:[ScanQrCodeTransportViewController class]]){
            if(result.isValidBitcoinAddress){
                [reader playSuccessSound];
                [reader vibrate];
                self.tfAddress.text = result;
                [self check];
                [self.tfAmount becomeFirstResponder];
            }
        }else{
            self.btnSend.enabled = NO;
            NSArray *strs = [result componentsSeparatedByString:QR_CODE_SPLIT];
            NSMutableArray *sigs = [[NSMutableArray alloc]init];
            for(NSString *s in strs){
                [sigs addObject:[s hexToData]];
            }
            [self.tx signWithSignatures:sigs];
            if([self.tx verifySignatures]){
                [self finalSend];
            }else{
                self.btnSend.enabled = YES;
                self.tx = nil;
                [self showBannerWithMessage:NSLocalizedString(@"Send failed.", nil) belowView:self.vTopBar];
            }
        }
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self check];
    });
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == self.tfAmount){
        [self sendPressed:self.btnSend];
    }
    return YES;
}

-(BOOL)checkValues{
    BOOL validAddress = [self.tfAddress.text isValidBitcoinAddress];
    int64_t amount = [StringUtil amountForString:self.tfAmount.text];
    return validAddress && amount > 0;
}

-(void)check{
    self.btnSend.enabled = [self checkValues];
    if([StringUtil compareString:self.tfAddress.text compare:DONATE_ADDRESS]){
        [self.btnSend setTitle:NSLocalizedString(@"Donate", nil) forState:UIControlStateNormal];
        self.lblPayTo.text = NSLocalizedString(@"Donate to developers", nil);
    }else{
        [self.btnSend setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        self.lblPayTo.text = NSLocalizedString(@"Pay to", nil);
    }
}

-(void)configureBalance{
    self.lblBalance.attributedText = [StringUtil stringWithSymbolForAmount:self.address.balance withFontSize:kBalanceFontSize color:self.lblBalance.textColor];
    [self configureBalanceLabelWidth:self.lblBalance];
    [self configureBalanceLabelWidth:self.lblBalancePrefix];
    self.lblBalance.frame = CGRectMake(CGRectGetMaxX(self.lblBalancePrefix.frame) + 5, self.lblBalance.frame.origin.y, self.lblBalance.frame.size.width, self.lblBalance.frame.size.height);
}

-(void)hideKeyboard{
    if(self.tfAddress.isFirstResponder){
        [self.tfAddress resignFirstResponder];
    }
    if(self.tfAmount.isFirstResponder){
        [self.tfAmount resignFirstResponder];
    }
}

-(void)configureBalanceLabelWidth:(UILabel*)lbl{
    CGRect frame = lbl.frame;
    [lbl sizeToFit];
    frame.size.width = lbl.frame.size.width;
    lbl.frame = frame;
}

- (IBAction)backPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)configureTextField:(UITextField*)tf{
    UIView *leftView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, tf.frame.size.height)];
    leftView.backgroundColor = [UIColor clearColor];
    UIView *rightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 10, tf.frame.size.height)];
    rightView.backgroundColor = [UIColor clearColor];
    tf.leftView = leftView;
    tf.rightView = rightView;
    tf.leftViewMode = UITextFieldViewModeAlways;
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    if(touch.view != self.tfAddress && touch.view != self.tfAmount){
        [self hideKeyboard];
    }
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    if(touch.view != self.tfAddress && touch.view != self.tfAmount){
        [self hideKeyboard];
    }
}

@end
