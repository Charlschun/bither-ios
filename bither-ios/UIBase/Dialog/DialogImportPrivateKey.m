//
//  DialogImportPrivateKey.m
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

#import "DialogImportPrivateKey.h"
#import "KeyboardController.h"
#import "StringUtil.h"
#import "UIBaseUtil.h"
#import "NSString+Base58.h"
#import <AudioToolbox/AudioToolbox.h>

#define kOuterPadding (1)
#define kInnerMargin (10)
#define kWidth (240)

#define kTextFieldFontSize (14)
#define kTextFieldHeight (35)
#define kTextFieldHorizontalMargin (10)

#define kButtonFontSize (15)
#define kButtonHeight (36)

#define kTitleFontSize (18)
#define kTitleHeight (20)

#define kSubTitleFontSize (12)
#define kSubTitleHeight (13)

#define kShakeTime (7)
#define kShakeDuration (0.04f)
#define kShakeWaveSize (5)

#define kCheckingFontSize (16)

@interface DialogImportPrivateKey()<UITextFieldDelegate, KeyboardControllerDelegate>
@property UIView *vChecking;
@property UIView *vContent;
@property UILabel *lblSubTitle;
@property UITextField *tfPassword;
@property UIButton *btnConfirm;
@property UIButton *btnCancel;

@property KeyboardController *kc;
@end

@implementation DialogImportPrivateKey

-(instancetype)initWithDelegate:(id<DialogImportPrivateKeyDelegate>)delegate{
    self = [super init];
    if(self){
        self.delegate = delegate;
        [self firstConfigure];
        [self configureKeyboard];
    }
    return self;
}

-(void)confirmPressed:(id)sender{
    NSString* p = self.tfPassword.text;
    if ([p isValidBitcoinPrivateKey]) {
        [self dismissWithPassword:p];
    }else{
        [self showError:NSLocalizedString(@"Not match private key format", nil)];
    }
}

-(void)dismissWithPassword:(NSString*)p{
    [self dismissWithCompletion:^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(onPrivateKeyEntered:)]){
            [self.delegate onPrivateKeyEntered:p];
        }
    }];
}

-(void)showError:(NSString*)error{
    self.lblSubTitle.text = error;
    self.lblSubTitle.textColor = [UIColor redColor];
    [self shake];
}

-(void)shake{
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    [self shakeTime:kShakeTime interval:kShakeDuration length:kShakeWaveSize];
}

-(void)dismissError{
    self.lblSubTitle.text = [self subTitle];
    self.lblSubTitle.textColor = [UIColor whiteColor];
}

-(void)dialogWillDismiss{
    if([self.tfPassword isFirstResponder]){
        [self.tfPassword resignFirstResponder];
    }
    [super dialogWillDismiss];
}

-(void)cancelPressed:(id)sender{
    [self dismiss];
}

-(void)dialogDidShow{
    [super dialogDidShow];
    [self.tfPassword becomeFirstResponder];
}

-(void)configureKeyboard{
    self.kc = [[KeyboardController alloc]initWithDelegate:self];
}

-(void)firstConfigure{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, kWidth, kOuterPadding * 2 + kTextFieldHeight * 2 + kSubTitleHeight + kTitleHeight + kButtonHeight + kInnerMargin * 4);
    self.touchOutSideToDismiss = NO;
    
    self.vChecking = [[UIView alloc]initWithFrame:self.vContent.frame];
    self.vChecking.backgroundColor = [UIColor clearColor];
    self.vChecking.autoresizingMask = self.vContent.autoresizingMask;
    [self addSubview:self.vChecking];
    
    self.vContent = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    self.vContent.backgroundColor = [UIColor clearColor];
    self.vContent.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self addSubview:self.vContent];
    UILabel *lblSubTitle = [[UILabel alloc]initWithFrame:CGRectMake(kOuterPadding, kOuterPadding, kWidth - kOuterPadding, kSubTitleHeight)];
    lblSubTitle.font = [UIFont systemFontOfSize:kSubTitleFontSize];
    lblSubTitle.textColor = [UIColor whiteColor];
    lblSubTitle.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    lblSubTitle.text = [self subTitle];
    self.lblSubTitle = lblSubTitle;
    
  
    [self.vContent addSubview:lblSubTitle];
    
    
    self.tfPassword = [[UITextField alloc]initWithFrame:CGRectMake(kOuterPadding, CGRectGetMaxY(lblSubTitle.frame) + kInnerMargin, kWidth - kOuterPadding * 2, kTextFieldHeight)];
    self.tfPassword.attributedPlaceholder = [[NSAttributedString alloc] initWithString: NSLocalizedString(@"Enter your private key text", nil) attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1 alpha:0.5]}];
    [self configureTextField:self.tfPassword];
    self.tfPassword.returnKeyType = UIReturnKeyDone;
    CGFloat buttonTop = CGRectGetMaxY(self.tfPassword.frame) + kInnerMargin;
    [self.vContent addSubview:self.tfPassword];

    self.btnCancel = [[UIButton alloc]initWithFrame:CGRectMake(kOuterPadding, buttonTop, (kWidth - kOuterPadding * 2 - kInnerMargin)/2, kButtonHeight)];
    [self.btnCancel setBackgroundImage:[UIImage imageNamed:@"dialog_btn_bg_normal"] forState:UIControlStateNormal];
    self.btnCancel.titleLabel.font = [UIFont systemFontOfSize:kButtonFontSize];
    [self.btnCancel setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [self.btnCancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnCancel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self.btnCancel addTarget:self action:@selector(cancelPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.btnConfirm = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.btnCancel.frame) + kInnerMargin, buttonTop, (kWidth - kOuterPadding * 2 - kInnerMargin)/2, kButtonHeight)];
    [self.btnConfirm setBackgroundImage:[UIImage imageNamed:@"dialog_btn_bg_normal"] forState:UIControlStateNormal];
    self.btnConfirm.titleLabel.font = [UIFont systemFontOfSize:kButtonFontSize];
    [self.btnConfirm setTitle:NSLocalizedString(@"OK", nil) forState:UIControlStateNormal];
    [self.btnConfirm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.btnConfirm.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    [self.btnConfirm addTarget:self action:@selector(confirmPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, CGRectGetMaxY(self.btnConfirm.frame) + kOuterPadding);
    
    [self.vContent addSubview:self.btnCancel];
    [self.vContent addSubview:self.btnConfirm];
    
    UIActivityIndicatorView* activity = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    activity.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    UILabel *lblChecking = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
    lblChecking.font = [UIFont systemFontOfSize:kCheckingFontSize];
    lblChecking.textColor = [UIColor whiteColor];
    lblChecking.text = NSLocalizedString(@"Checking password…", nil);
    lblChecking.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    CGRect rect =  [lblChecking.text boundingRectWithSize:CGSizeMake(self.frame.size.width - activity.frame.size.width - kInnerMargin, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName: lblChecking.font, NSParagraphStyleAttributeName:[NSParagraphStyle defaultParagraphStyle]} context:nil];
    rect.size.width = ceilf(rect.size.width);
    rect.size.height = ceilf(rect.size.height);
    CGFloat width = activity.frame.size.width + kInnerMargin + rect.size.width;
    CGFloat left = (self.frame.size.width - width)/2;
    activity.frame = CGRectMake(left, (self.frame.size.height - activity.frame.size.height)/2, activity.frame.size.width, activity.frame.size.height);
    lblChecking.frame = CGRectMake(CGRectGetMaxX(activity.frame) + kInnerMargin, (self.frame.size.height - rect.size.height)/2, rect.size.width, rect.size.height);
    activity.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;
    lblChecking.autoresizingMask = activity.autoresizingMask;
    [activity startAnimating];
    [self.vChecking addSubview:activity];
    [self.vChecking addSubview:lblChecking];
    self.vChecking.hidden = YES;
    
    [self.vContent bringSubviewToFront:self.tfPassword];
   
}

-(void)keyboardFrameChanged:(CGRect)frame{
    CGFloat totalHeight = frame.origin.y;
    CGFloat top = (totalHeight - self.frame.size.height)/2;
    self.frame = CGRectMake(self.frame.origin.x, top, self.frame.size.width, self.frame.size.height);
}


-(NSString*)subTitle{
    return NSLocalizedString(@"private key", nil);
}

-(void)configureTextField:(UITextField*)tf{
    tf.textColor = [UIColor whiteColor];
    tf.background = [UIImage imageNamed:@"textfield_activated_holo_light"];
    tf.delegate = self;
    tf.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    tf.font = [UIFont systemFontOfSize:kTextFieldFontSize];
    tf.borderStyle = UITextBorderStyleNone;
    UIView *leftView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, kTextFieldHorizontalMargin, tf.frame.size.height)];
    leftView.backgroundColor = [UIColor clearColor];
    UIView *rightView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, kTextFieldHorizontalMargin, tf.frame.size.height)];
    rightView.backgroundColor = [UIColor clearColor];
    tf.leftView = leftView;
    tf.rightView = rightView;
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.rightViewMode = UITextFieldViewModeAlways;
    tf.enablesReturnKeyAutomatically = YES;
    tf.keyboardType = UIKeyboardTypeASCIICapable;

}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    [self dismissError];
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField{
    if(textField == self.tfPassword){
        [self confirmPressed:self.btnConfirm];
    }
    return YES;
}

@end
