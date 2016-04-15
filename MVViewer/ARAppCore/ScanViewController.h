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

@property (weak, nonatomic) IBOutlet UITextField *titleLabelTextField;
@property (weak, nonatomic) IBOutlet UITextField *subTitleLabelTextField;
@end
