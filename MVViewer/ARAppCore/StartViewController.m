//
//  StartViewController.m
//  StoryboardTest
//
//  Created by Helen zheng on 16/4/9.
//  Copyright © 2016年 Helen Zheng. All rights reserved.
//

#import "StartViewController.h"

@interface StartViewController ()

@end

@implementation StartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //scale the background image to fill
    UIGraphicsBeginImageContext(self.view.frame.size);
    [[UIImage imageNamed:@"Data/sky.jpg"] drawInRect:self.view.bounds];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:image];
    
    //load title image
    // self.titleView.image = [UIImage imageNamed:@"title.png"];
        // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startActionButton:(UIButton *)sender {
    
    // St
}


@end
