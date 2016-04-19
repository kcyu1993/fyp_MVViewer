//
//  MVViewController.h
//  MV_Viewer
//
//  Created by Jack Yu on 5/1/2016.
//
//

// Partial code is inspired from ARToolKit's library.


#import <UIKit/UIKit.h>


#import "../ARAppCore/ARView.h"
#import "../ARAppCore/VirtualEnvironment.h"
#import "ScanViewController.h"



@interface AnimationControlViewController : UIViewController
{
    
}

@property (nonatomic, weak) VirtualEnvironment* virtualEnvironment;
@property (nonatomic, weak) NSString* patientInfo;


@property (weak, nonatomic) IBOutlet UIToolbar *controlBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *slideBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *textSlide;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *previousSlice;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *playButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *nextSlice;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *pauseButton;


@end

