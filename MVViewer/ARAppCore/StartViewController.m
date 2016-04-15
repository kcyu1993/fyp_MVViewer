//
//  StartViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/9.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//
#import <CRToast/CRToast.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "StartViewController.h"


@interface StartViewController () 

@property (strong, nonatomic) NSDictionary *options;
@property (strong, nonatomic) NSString *titleMessage;
@property (strong, nonatomic) NSString* subtitleMessage;
@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        // self.minimalNotification.presentFromTop = YES;
    
    _titleMessage = @"TITLE";
    _subtitleMessage = @"Subtitle";
    float padding = 1.0f;
    
    self.options = [@{kCRToastNotificationTypeKey: @(CRToastTypeNavigationBar),
                      kCRToastNotificationPresentationTypeKey   : @(CRToastPresentationTypeCover),
                      kCRToastUnderStatusBarKey                 : @(YES),
                      kCRToastTextKey                           :_titleMessage,
                      kCRToastSubtitleTextKey                   : _subtitleMessage,
                      kCRToastTextAlignmentKey                  : @(NSTextAlignmentLeft),
                      kCRToastTimeIntervalKey                   : @10.0f,
                      kCRToastAnimationInTypeKey                : @(CRToastAnimationTypeSpring),
                      kCRToastAnimationOutTypeKey               : @(CRToastAnimationTypeSpring),
                      kCRToastAnimationInDirectionKey           : @(1),
                      kCRToastAnimationOutDirectionKey          : @(1),
                      kCRToastNotificationPreferredPaddingKey   : @(padding),
                      kCRToastShowActivityIndicatorKey          : @(YES),
                      kCRToastActivityIndicatorAlignmentKey     :@(NSTextAlignmentLeft),
                      kCRToastBackgroundColorKey: [UIColor orangeColor]}
                    mutableCopy];
}
- (IBAction)buttonShowAction:(id)sender {
    [CRToastManager showNotificationWithOptions:[self options]
                                 apperanceBlock:^(void) {
                                     NSLog(@"Appeared");
                                 }
                                completionBlock:^(void) {
                                    NSLog(@"Completed");
                            }];
}



- (IBAction)startActionButton:(UIButton *)sender {
   
}

@end
