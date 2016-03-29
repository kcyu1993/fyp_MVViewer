//
//  MVViewController.m
//  MV_Viewer
//
//  Created by Jack Yu on 5/1/2016.
//
//

#import "ARViewController.h"
#import <AR/gsub_es.h>
#import "ARAppCore/ARMarkerSquare.h"
#import "ARAppCore/ARMarkerMulti.h"
#import "ARAppCore/ARMarkerQRcode.h"
#import "ARAppCore/VirtualEnvironment.h"

#define VIEW_DISTANCE_MIN   5.0f
#define VIEW_DISTANCE_MAX   2000.0f

@implementation ARViewController {
    BOOL            running;
    NSInteger       runLoopInterval;
    NSTimeInterval  runLoopTimePrevious;
    BOOL            videoPaused;
    
    // Video acquisition
    AR2VideoParamT  *gVid;
    
    // Marker detection
    ARHandle        *gARHandle;
    ARPattHandle    *gARPattHandle;
    long            gCallCountMarkerDetect;
    
    // Transformation matrix retrieval
    AR3DHandle      *gAR3DHandle;
    
    // Markers.
    NSMutableArray  *markers;
    
    // Drawing
    ARParamLT       *gCparamLT;
    ARView          *glView;
    VirtualEnvironment *virtualEnvironment;
    // MVView          *glView;
    // MVVirtualEnvironment  *virtualEnvironment;
    ARGL_CONTEXT_SETTINGS_REF   arglContextSettings;
    
    /* Helen */
    CameraVideo *cameraVideo;
    NSArray *cObjects;
    
}

@synthesize glView, virtualEnvironment, markers;
@synthesize arglContextSettings;
@synthesize running, runLoopInterval;

- (void) loadView {
    // self.wantsFullScreenLayout = YES; deprecated
    self.edgesForExtendedLayout = YES;
    
    // This is could be a fancy loading box.
    // This will be overlaid with the actual AR view.
    NSString *irisImage = nil;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        irisImage = @"Iris-iPad.png";
    }  else { // UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone
        CGSize result = [[UIScreen mainScreen] bounds].size;
        if (result.height == 568) {
            irisImage = @"Iris-568h.png"; // iPhone 5, iPod touch 5th Gen, etc.
        } else { // result.height == 480
            irisImage = @"Iris.png";
        }
    }
    UIView *irisView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:irisImage]];
    irisView.userInteractionEnabled = YES;
    self.view = irisView;
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Init instance variables.
    glView = nil;
    virtualEnvironment = nil;
    markers = nil;
    gVid = NULL;
    gCparamLT = NULL;
    gARHandle = NULL;
    gARPattHandle = NULL;
    gCallCountMarkerDetect = 0;
    gAR3DHandle = NULL;
    arglContextSettings = NULL;
    running = FALSE;
    videoPaused = FALSE;
    runLoopTimePrevious = CFAbsoluteTimeGetCurrent();
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self start];
}

// Orientation
- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (void) startRunLoop {
    if(!running) {
        // start point to load frames from Camera video
        if(ar2VideoCapStart(gVid) != 0) {
            NSLog(@"Error: unable to begin cmaera data capture");
            [self stop];
            return;
        }
        running = TRUE;
    }
}

- (void) stopRunLoop   {
    if(running) {
        ar2VideoCapStop(gVid);
        running = FALSE;
    }
}

- (void) setRunLoopInterval:(NSInteger) interval {
    if (interval >= 1) {
        runLoopInterval = interval;
        if(running){
            [self stopRunLoop];
            [self startRunLoop];
        }
    }
}

- (BOOL) isPaused {
    if(!running) return (NO);
    return (videoPaused);
}

- (void) setPaused:(BOOL)paused {
    if (!running) return;
    
    if(videoPaused != paused) {
        if(paused)  ar2VideoCapStop(gVid);
        else        ar2VideoCapStart(gVid);
        videoPaused = paused;
    }
}

/** C function */
static void startCallback (void *userData);

// Start point of the video.
-(IBAction)start {
    char *vconf = "";
    if(!(gVid = ar2VideoOpenAsync(vconf, startCallback, (__bridge void *)(self)))){
        NSLog(@"ERROR: Unable to open camera video");
        [self stop];
        return;
    }
    
}

static void startCallback(void* userData) {
    ARViewController *vc = (__bridge ARViewController *) userData;
    [vc start2];
}
 // Helen : I need to change here !!!
- (void) start2 {

    int xsize, ysize;
    if (ar2VideoGetSize(gVid, &xsize, &ysize)){
        NSLog(@"ERROR: sizeGetError");
        [self stop];
        return;
    }
    
    AR_PIXEL_FORMAT pixFormat = ar2VideoGetPixelFormat(gVid);
    
    if(pixFormat == AR_PIXEL_FORMAT_INVALID){
        NSLog(@"ERROR: invalid pixel format");
        [self stop];
        return;
    }
   
    // Front camera omitted
    //ar2VideoSetParami(gVid, AR_Video_PARAM_IOS_FOCUS, AR_VIDEO_IOS_FOCUS_0_3M);
    
    
    ARParam cparam;
    if(ar2VideoGetCParam(gVid, &cparam) < 0) {
        // Load camera parameters.
        char cparam_name[] = "Data/camera_para.dat";
        NSLog(@"Unable to automatically determine camera parameters. Using default.\n");
        if (arParamLoad(cparam_name, 1, &cparam) < 0) {
            NSLog(@"Error: Unable to load parameter file %s for camera.\n", cparam_name);
            [self stop];
            return;
        }
    }
    if (cparam.xsize != xsize || cparam.ysize != ysize) {
#ifdef DEBUG
        fprintf(stdout, "*** Camera Parameter resized from %d, %d. ***\n", cparam.xsize, cparam.ysize);
#endif
        arParamChangeSize(&cparam, xsize, ysize, &cparam);
    }
#ifdef DEBUG
    fprintf(stdout, "*** Camera Parameter ***\n");
    arParamDisp(&cparam);
#endif
    if ((gCparamLT = arParamLTCreate(&cparam, AR_PARAM_LT_DEFAULT_OFFSET)) == NULL) {
        NSLog(@"Error: arParamLTCreate.\n");
        [self stop];
        return;
    }
    
    // AR init.
    if ((gARHandle = arCreateHandle(gCparamLT)) == NULL) {
        NSLog(@"Error: arCreateHandle.\n");
        [self stop];
        return;
    }
    if (arSetPixelFormat(gARHandle, pixFormat) < 0) {
        NSLog(@"Error: arSetPixelFormat.\n");
        [self stop];
        return;
    }
    if ((gAR3DHandle = ar3DCreateHandle(&gCparamLT->param)) == NULL) {
        NSLog(@"Error: ar3DCreateHandle.\n");
        [self stop];
        return;
    }
    
    // libARvideo on iPhone uses an underlying class called CameraVideo. Here, we
    // access the instance of this class to get/set some special types of information.
    
    cameraVideo = ar2VideoGetNativeVideoInstanceiPhone(gVid->device.iPhone);
//    CameraVideo *cameraVideo = [[CameraVideo alloc] init];
    if (!cameraVideo) {
        NSLog(@"Error: Unable to set up AR camera: missing CameraVideo instance.\n");
        [self stop];
        return;
    }
    
    // The camera will be started by -startRunLoop.
    [cameraVideo setTookPictureDelegate:self];
    [cameraVideo setTookPictureDelegateUserData:NULL];
    
    // Other ARToolKit setup.
    arSetMarkerExtractionMode(gARHandle, AR_USE_TRACKING_HISTORY_V2);
    //arSetMarkerExtractionMode(gARHandle, AR_NOUSE_TRACKING_HISTORY);
    //arSetLabelingThreshMode(gARHandle, AR_LABELING_THRESH_MODE_MANUAL); // Uncomment to use  manual thresholding.
    
    // Allocate the OpenGL view.
    glView = [[ARView alloc] initWithFrame:[[UIScreen mainScreen] bounds] pixelFormat:kEAGLColorFormatRGBA8 depthFormat:kEAGLDepth16 withStencil:NO preserveBackbuffer:NO] ; // Don't retain it, as it will be retained when added to self.view.
    glView.arViewController = self;
    
    [self.view addSubview:glView];
    
    
    // Create the OpenGL projection from the calibrated camera parameters.
    // If flipV is set, flip.
    /**
     // -- Kaicheng
     // For OpenGL parameter creation
     */
    GLfloat frustum[16];
    arglCameraFrustumRHf(&gCparamLT->param, VIEW_DISTANCE_MIN, VIEW_DISTANCE_MAX, frustum);
    [glView setCameraLens:frustum];
    glView.contentFlipV = FALSE;
    
    // Set up content positioning.
    glView.contentScaleMode = ARViewContentScaleModeFill;
    glView.contentAlignMode = ARViewContentAlignModeCenter;
    glView.contentWidth = gARHandle->xsize;
    glView.contentHeight = gARHandle->ysize;
    BOOL isBackingTallerThanWide = (glView.surfaceSize.height > glView.surfaceSize.width);
    if (glView.contentWidth > glView.contentHeight) glView.contentRotate90 = isBackingTallerThanWide;
    else glView.contentRotate90 = !isBackingTallerThanWide;
#ifdef DEBUG
    NSLog(@"[ARViewController start] content %dx%d (wxh) will display in GL context %dx%d%s.\n", glView.contentWidth, glView.contentHeight, (int)glView.surfaceSize.width, (int)glView.surfaceSize.height, (glView.contentRotate90 ? " rotated" : ""));
#endif
    
    // Setup ARGL to draw the background video.
    /**
     // -- Kaicheng
     // Setting buffer size, context settings for ARGL.
     */
    arglContextSettings = arglSetupForCurrentContext(&gCparamLT->param, pixFormat);
    
    arglSetRotate90(arglContextSettings, (glView.contentWidth > glView.contentHeight ? isBackingTallerThanWide : !isBackingTallerThanWide));
    // if (flipV) arglSetFlipV(arglContextSettings, TRUE);
    int width, height;
    ar2VideoGetBufferSize(gVid, &width, &height);
    arglPixelBufferSizeSet(arglContextSettings, width, height);
    
    // Prepare ARToolKit to load patterns.
    if (!(gARPattHandle = arPattCreateHandle())) {
        NSLog(@"Error: arPattCreateHandle.\n");
        [self stop];
        return;
    }
    arPattAttach(gARHandle, gARPattHandle);
    
    // Load marker(s).
    
    /**
     // -- Notice for Helen!
     //
    */
    
    
    //NSString *markerConfigDataFilename = @"Data/markers.dat";
    int mode = AR_MATRIX_CODE_DETECTION;
    
    markers = [ARMarker newQRcodeMarker];
    //Helen
    /*
    if ((markers = [ARMarker newMarkersFromConfigDataFile:markerConfigDataFilename arPattHandle:gARPattHandle arPatternDetectionMode:&mode]) == nil) {
        NSLog(@"Error loading markers.\n");
        [self stop];
        return;
    }*/
    
#ifdef DEBUG
    NSLog(@"Marker count = %lu\n", (unsigned long)[markers count]);
#endif
    // Set the pattern detection mode (template (pictorial) vs. matrix (barcode) based on
    // the marker types as defined in the marker config. file.
    arSetPatternDetectionMode(gARHandle, mode); /** Default = AR_TEMPLATE_MATCHING_COLOR */
    
    // Other application-wide marker options. Once set, these apply to all markers in use in the application.
    // If you are using standard ARToolKit picture (template) markers, leave commented to use the defaults.
    // If you are usign a different marker design (see http://www.artoolworks.com/support/app/marker.php )
    // then uncomment and edit as instructed by the marker design application.
    //arSetLabelingMode(gARHandle, AR_LABELING_BLACK_REGION); // Default = AR_LABELING_BLACK_REGION
    //arSetBorderSize(gARHandle, 0.25f); // Default = 0.25f
    //arSetMatrixCodeType(gARHandle, AR_MATRIX_CODE_3x3); // Default = AR_MATRIX_CODE_3x3
    
    // Set up the virtual environment.
    // -- Kaicheng Notes
    /**
     * Main part to modify
     * Add the heart models to this virtual environment
     *
     */
    self.virtualEnvironment = [[VirtualEnvironment alloc] initWithARViewController:self] ;
    [self.virtualEnvironment addObjectsFromObjectListFile:@"Data/models.dat" connectToARMarkers:markers];
    
    // Because in this example we're not currently assigning a world coordinate system
    // (we're just using local marker coordinate systems), set the camera pose now, to
    // the default (i.e. the identity matrix).
    float pose[16] = {1.0f, 0.0f, 0.0f, 0.0f,  0.0f, 1.0f, 0.0f, 0.0f,  0.0f, 0.0f, 1.0f, 0.0f,  0.0f, 0.0f, 0.0f, 1.0f};
    [glView setCameraPose:pose];
    
    // For FPS statistics.
    arUtilTimerReset();
    gCallCountMarkerDetect = 0;
    
    //Create our runloop timer
    [self setRunLoopInterval:2]; // Target 30 fps on a 60 fps device.
    [self startRunLoop];

}

- (void) cameraVideoTookPicture:(id)sender userData:(void *)data
{
    AR2VideoBufferT *buffer = ar2VideoGetImage(gVid);
    if (buffer) [self processFrame:buffer];
}

- (void) processFrame:(AR2VideoBufferT *)buffer
{
    if (buffer) {
        
        // Upload the frame to OpenGL.
        if (buffer->bufPlaneCount == 2) arglPixelBufferDataUploadBiPlanar(arglContextSettings, buffer->bufPlanes[0], buffer->bufPlanes[1]);
        else arglPixelBufferDataUpload(arglContextSettings, buffer->buff);
        
        gCallCountMarkerDetect++; // Increment ARToolKit FPS counter.
#ifdef DEBUG
        NSLog(@"video frame %ld.\n", gCallCountMarkerDetect);
#endif
#ifdef DEBUG
        if (gCallCountMarkerDetect % 150 == 0) {
            NSLog(@"*** Camera - %f (frame/sec)\n", (double)gCallCountMarkerDetect/arUtilTimer());
            gCallCountMarkerDetect = 0;
            arUtilTimerReset();
        }
#endif
        //Helen
        cObjects = [cameraVideo codeObjects];
        
        int markerNum = (int)[cObjects count];
        NSLog(@"MetaObject count = %lu", (unsigned long)[cObjects count]);

        
        gARHandle->marker_num = markerNum;
        ARMarkerInfo *markerInfo = arGetMarker(gARHandle);
        
        CGPoint cgpoint;
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGFloat screenWidth = gARHandle->xsize;
        CGFloat screenHeight = gARHandle->ysize;
        NSLog(@"screen width%f", screenWidth);
        NSLog(@"screen height%f", screenHeight);

        if (markerNum > 0)
        {
            int i=0;
            NSArray *metacorners=[(AVMetadataMachineReadableCodeObject *) cObjects[0] corners];
            while (i < 4)
            {

                CGPointMakeWithDictionaryRepresentation((CFDictionaryRef) metacorners[i], &cgpoint);
                markerInfo[0].vertex[i][0]=(ARdouble)cgpoint.x * screenHeight; //need to turn the iPad to test it
                markerInfo[0].vertex[i][1]=(ARdouble)cgpoint.y * screenWidth;
                
                i++;
            }
            markerInfo->id=1;
            markerInfo->dir=0;
                        
            markerInfo->cf=1.0;
        }

        /*for (AVMetadataObject *metadataObject in cObjects)
        {
            int i=0;
            for (NSValue *point in [(AVMetadataMachineReadableCodeObject *) metadataObject corners]){
                NSLog(@"point %@\n", point);
                
            }
        }*/
        
        
        
        
        
        // Detect the markers in the video frame.
        //Helen
        /*
        if (arDetectMarker(gARHandle, buffer->buff) < 0) return;
        int markerNum = arGetMarkerNum(gARHandle);
        ARMarkerInfo *markerInfo = arGetMarker(gARHandle);
         */
        
#ifdef DEBUG
        //NSLog(@"found %d marker(s).\n", markerNum);
#endif
        NSLog(@"markers has: %lu", (unsigned long)[markers count]);
        for (ARMarker *marker in markers) {
            if ([marker isKindOfClass:[ARMarkerQRcode class]]) {
                NSLog(@"Found");
                [(ARMarkerQRcode *)marker updateWithDetectedMarkers:markerInfo count:markerNum ar3DHandle:gAR3DHandle];
            } else {
                [marker update];
            }
        }

        
        // Update all marker objects with detected markers.
        /*Helen
         for (ARMarker *marker in markers) {
            if ([marker isKindOfClass:[ARMarkerSquare class]]) {
                [(ARMarkerSquare *)marker updateWithDetectedMarkers:markerInfo count:markerNum ar3DHandle:gAR3DHandle];
            } else if ([marker isKindOfClass:[ARMarkerMulti class]]) {
                [(ARMarkerMulti *)marker updateWithDetectedMarkers:markerInfo count:markerNum ar3DHandle:gAR3DHandle];
            } else {
                [marker update];
            }
        }*/
        
        // Get current time (units = seconds).
        /**
         * // -- Kaicheng
         * Virtual Environment update time interval.
         *
         */
        NSTimeInterval runLoopTimeNow;
        runLoopTimeNow = CFAbsoluteTimeGetCurrent();
        [virtualEnvironment updateWithSimulationTime:(runLoopTimeNow - runLoopTimePrevious)];
        
        // The display has changed.
        [glView drawView:self];
        
        // Save timestamp for next loop.
        runLoopTimePrevious = runLoopTimeNow;
    }
}

- (IBAction)stop
{
    [self stopRunLoop];
    
    self.virtualEnvironment = nil;

    markers = nil;
    
    if (arglContextSettings) {
        arglCleanup(arglContextSettings);
        arglContextSettings = NULL;
    }
    [glView removeFromSuperview]; // Will result in glView being released.
    glView = nil;
    
    if (gARHandle) arPattDetach(gARHandle);
    if (gARPattHandle) {
        arPattDeleteHandle(gARPattHandle);
        gARPattHandle = NULL;
    }
    if (gAR3DHandle) ar3DDeleteHandle(&gAR3DHandle);
    if (gARHandle) {
        arDeleteHandle(gARHandle);
        gARHandle = NULL;
    }
    arParamLTFree(&gCparamLT);
    if (gVid) {
        ar2VideoClose(gVid);
        gVid = NULL;
    }
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewWillDisappear:(BOOL)animated {
    [self stop];
    [super viewWillDisappear:animated];
}


/*// ARToolKit-specific methods.
- (BOOL)markersHaveWhiteBorders
{
    int mode;
    arGetLabelingMode(gARHandle, &mode);
    return (mode == AR_LABELING_WHITE_REGION);
}

- (void)setMarkersHaveWhiteBorders:(BOOL)markersHaveWhiteBorders
{
    arSetLabelingMode(gARHandle, (markersHaveWhiteBorders ? AR_LABELING_WHITE_REGION : AR_LABELING_BLACK_REGION));
}

*/


@end