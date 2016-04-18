//
//  TryNavigation.m
//  MVViewer_FYP_15011
//
//  Created by Jack Yu on 18/4/2016.
//
//

#import <Foundation/Foundation.h>
#import "TryNavigation.h"



@interface TryNavigation()

@property (weak, nonatomic) IBOutlet UINavigationBar *navigation;

@end

@implementation TryNavigation

- (void) viewDidLoad
{
    [self setNavigation:_navigation];
    [self.navigationBar setHidden:FALSE];
    [self.navigationBar setAlpha:0.5];
    
    
    
}

@end