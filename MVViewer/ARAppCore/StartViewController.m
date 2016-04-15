//
//  StartViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/9.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "StartViewController.h"
#import "../JFMinimalNotification/JFMinimalNotification.h"

@interface StartViewController () <JFMinimalNotificationDelegate, UITextFieldDelegate>
@property (nonatomic, strong) JFMinimalNotification* minimalNotification;

@end

@implementation StartViewController

- (void)viewDidLoad {[super viewDidLoad];
    
    self.titleLabelTextField.text = @"Aaaaalsdjfslakjflsjhfoigjsdkjhvloisdjfo;isjdkfjasljfslkjv;isjflgohsidlufhvglsieurhnd,cjvbnlidufhglisejrlgkjhdliufvhdsljf,kjxbvkjdshfglidjflgjsdklffj;sTesting";
    self.subTitleLabelTextField.text = @"This is my awesome sub-title";
    
    /**
     * Create the notification
     */
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleCustom title:self.titleLabelTextField.text subTitle:self.subTitleLabelTextField.text dismissalDelay:0.0 touchHandler:^{
        [self.minimalNotification dismiss];
    }];
    
    self.minimalNotification.edgePadding = UIEdgeInsetsMake(0, 0, 10, 0);
    
    [self.view addSubview:self.minimalNotification];
    
    self.minimalNotification.backgroundColor = [UIColor purpleColor];
    
    self.minimalNotification.titleLabel.textColor = [UIColor whiteColor];
    self.minimalNotification.subTitleLabel.textColor = [UIColor whiteColor];
    
    /**
     * Set the delegate
     */
    self.minimalNotification.delegate = self;
    
    /**
     * Set the desired font for the title and sub-title labels
     * Default is System Normal
     */
    UIFont* titleFont = [UIFont fontWithName:@"STHeitiK-Light" size:22];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont fontWithName:@"STHeitiK-Light" size:16];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    
    
    
    /**
     * Uncomment the following line to present notifications from the top of the screen.
     */
    // self.minimalNotification.presentFromTop = YES;
}


- (void)showToastWithMessage:(NSString *)message {
    if (self.minimalNotification) {
        [self.minimalNotification dismiss];
        [self.minimalNotification removeFromSuperview];
        self.minimalNotification = nil;
    }
    
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:JFMinimalNotificationStyleError
                                                                      title:NSLocalizedString(@"Refresh Error", @"Refresh Error")
                                                                   subTitle:message
                                                             dismissalDelay:10.0];
    
    /**
     * Set the desired font for the title and sub-title labels
     * Default is System Normal
     */
    UIFont* titleFont = [UIFont systemFontOfSize:22.0];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont systemFontOfSize:16.0];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    
    /**
     * Add the notification to a view
     */
    [self.view addSubview:self.minimalNotification];
    
    // show
    [self performSelector:@selector(showNotification) withObject:nil afterDelay:0.1];
}

- (void)showNotification {
    [self.minimalNotification show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startActionButton:(UIButton *)sender {

}
- (IBAction)showMessageButtonAction:(id)sender {
    [self.minimalNotification show];
}



#pragma mark ----------------------
#pragma mark UITextFieldDelegate
#pragma mark ----------------------

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    JFMinimalNotificationStyle style = self.minimalNotification.currentStyle;
    [self.minimalNotification removeFromSuperview];
    self.minimalNotification = nil;
    self.minimalNotification = [JFMinimalNotification notificationWithStyle:style title:self.titleLabelTextField.text subTitle:self.subTitleLabelTextField.text dismissalDelay:0.0f touchHandler:^{
        [self.minimalNotification dismiss];
    }];
    self.minimalNotification.delegate = self;
    UIFont* titleFont = [UIFont fontWithName:@"STHeitiK-Light" size:22];
    [self.minimalNotification setTitleFont:titleFont];
    UIFont* subTitleFont = [UIFont fontWithName:@"STHeitiK-Light" size:16];
    [self.minimalNotification setSubTitleFont:subTitleFont];
    [self.view addSubview:self.minimalNotification];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.minimalNotification show];
    });
    
    return YES;
}

#pragma mark ----------------------
#pragma mark JFMinimalNotificationDelegate
#pragma mark ----------------------

- (void)minimalNotificationWillShowNotification:(JFMinimalNotification*)notification {
    NSLog(@"willShowNotification");
}

- (void)minimalNotificationDidShowNotification:(JFMinimalNotification*)notification {
    NSLog(@"didShowNotification");
}

- (void)minimalNotificationWillDisimissNotification:(JFMinimalNotification*)notification {
    NSLog(@"willDisimissNotification");
}

- (void)minimalNotificationDidDismissNotification:(JFMinimalNotification*)notification {
    NSLog(@"didDismissNotification");
}


@end
