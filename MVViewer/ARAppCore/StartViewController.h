//
//  ViewController.h
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/9.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StartViewController : UIViewController

- (void)showToastWithMessage:(NSString *)message;
- (void)showNotification;

@property (weak, nonatomic) IBOutlet UIButton *startButton;

@property (strong, nonatomic) IBOutlet UIButton *showMessage;

@property (weak, nonatomic) IBOutlet UITextField *titleLabelTextField;
@property (weak, nonatomic) IBOutlet UITextField *subTitleLabelTextField;
@end

