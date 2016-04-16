//
//  ScanViewController.h
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/10.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScanViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIView *scanFrame;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;

@property (strong, nonatomic) IBOutlet UIView *progressView;
@property (strong, nonatomic) IBOutlet UILabel *progressBarLabel;
@property (strong, nonatomic) IBOutlet UIProgressView *progressBar;

@property (strong, nonatomic) IBOutlet UINavigationItem *navigationBar;

@property (strong, nonatomic) IBOutlet UIButton *startAnimation;

@property (strong, nonatomic) IBOutlet UIToolbar *bottomBar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *confirmButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *selectPatientFromList;
@property (weak, nonatomic) IBOutlet UITextField *titleLabelTextField;
@property (weak, nonatomic) IBOutlet UITextField *subTitleLabelTextField;

@end
