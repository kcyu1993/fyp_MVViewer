//
//  MVViewController.h
//  MV_Viewer
//
//  Created by Jack Yu on 5/1/2016.
//
//

// Partial code is inspired from ARToolKit's library.


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <AR/ar.h>
#import <AR/video.h>
#import <AR/gsub_es.h>
#import "ARAppCore/ARMarker.h"
#import <AR/sys/CameraVideo.h>
#import "ARAppCore/ARView.h"
#import "ARAppCore/VirtualEnvironment.h"

//#import "MVView.h"
//#import "MVVirtualEnvironment.h"


@interface ARViewController : UIViewController <CameraVideoTookPictureDelegate>
{
    
}

- (IBAction)start;
- (IBAction)stop;
- (void) processFrame:(AR2VideoBufferT *)buffer;

/** KC defined method */
- (void) loadPatient:(NSString*) patient;

/* Helen */
@property (nonatomic) NSArray *cObjects;

/** KC defined attributes */
@property (nonatomic, setter=loadPatient: ) NSString* patientInfo;

@property (readonly) ARView *glView;
//@property (readonly) MVView *glView;    /** tobe swtiched */
@property (readonly) NSMutableArray *markers;
//@property (nonatomic, retain) MVVirtualEnvironment *virtualEnvironment;
@property (nonatomic,retain) VirtualEnvironment *virtualEnvironment;
@property (readonly) ARGL_CONTEXT_SETTINGS_REF arglContextSettings;

@property (readonly, nonatomic, getter=isRunning) BOOL running;
@property (nonatomic, getter=isPaused) BOOL paused;

// Frame interval defines how many display frames must pass between each time the
// display link fires. The display link will only fire 30 times a second when the
// frame internal is two on a display that refreshes 60 times a second. The default
// frame interval setting of one will fire 60 times a second when the display refreshes
// at 60 times a second. A frame interval setting of less than one results in undefined
// behavior.
@property (nonatomic) NSInteger runLoopInterval;

@property (nonatomic) BOOL markersHaveWhiteBorders;

@end

