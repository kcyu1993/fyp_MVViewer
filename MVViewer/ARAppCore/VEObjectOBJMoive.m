//
//  VEObjectOBJMoive.m
//  ARToolKit5iOS
//
//  Created by Jack Yu on 16/2/2016.
//
//

//#import <Foundation/Foundation.h>

#import "VEObjectOBJMovie.h"

#import "VirtualEnvironment.h"
#import "glStateCache.h"
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/param.h>

#import <Eden/EdenMath.h>
#import <Eden/glm.h>

#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "ARView.h"
#import "../ARViewController.h"
/**
 * This is a class that serves for mitral valve heart movie. 
 * Core function is to listen to the marker provided, display and switch 
 * the GL models at a certain time interval.
 
 IT should keep different VEObject, to be specific, VEObjectOBJ to this 
 VEObjectOBJMovie. The VEObject attached to this object should not responds 
 to DefaultNotificationCenter for markers, and should not be added to 
 VirtualEnvironment as well.
 
 
 Workflow:
    1. At load phase, it register the objs as an identifier
    2. In init phase,
        a. Load all base and valve models from file and using the code blocks in VEObjectOBJ
            to generate correspoinding GLModel.
        b. Load it with order of time stamps.
    3. Display phase,
        a. Set up a counter and current display index
        b. draw current display index model when visiable flag is true.
        Note: all the counter modification shall be done in ARViewController processFrame.
 
*/




Class RenderModels;

struct RenderModel {
    GLMmodel* base;
    GLMmodel* valve;
    int timeStamp;
    BOOL hasValve;
};

typedef struct RenderModel RenderModel;




@implementation VEObjectOBJMovie {
    // NSMutableArray *baseOBJArray;
    // NSMutableArray *valveOBJArray;
    // NSMutableIndexSet *timeStampArray;
    
    NSMutableDictionary* renderedObjects;

    NSUInteger size;
    NSUInteger valveSize;
    BOOL hasValve;
    int current;
    
    // From VEObjiectMovie
    NSTimer *deferredVisibilityChangeTimer;
    NSTimer *movieLoopingTimer;
    NSInvocation *movieLoopInvocation;
    float _fps;
    float _disappearLatency;
    
}


+(void)load{
    VEObjectRegistryRegister(self, @"objs");
}

-(id) initFromSettings:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale
{
    self = [super initFromFile:nil translation:translation rotation:rotation scale:scale];
    return self;
}

-(id)initFromListOfFiles: (NSString*) patientID baseFiles:(NSArray *)baseFiles valveFiles:(NSArray *) valveFiles index:(NSArray*) timeStamp translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale
{
    return [self initFromListOfFiles:patientID baseFiles:baseFiles valveFiles:valveFiles index:timeStamp translation:translation rotation:rotation scale:scale delegate:nil];
}



-(id)initFromListOfFiles:(NSString*) patinetID  baseFiles:(NSArray *)baseFiles valveFiles:(NSArray *) valveFiles index:(NSArray*) timeStamp translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale delegate:(ScanViewController *)scanVC
{
    self = [super initFromFile:nil translation:translation rotation:rotation scale:scale];
    
    // self.delegate = scanVC;
    _patientName = patinetID;
    valveSize = 0;
    // Create a new empty array.
    renderedObjects = [[NSMutableDictionary alloc] initWithCapacity:[baseFiles count]];
    
    RenderModel* tmpModel;
    NSString* file;
    
    if (valveFiles == nil) {
        hasValve = NO;
    }
    
    if (timeStamp == nil) {
        NSMutableArray* tempTime = [[NSMutableArray alloc]initWithCapacity:[baseFiles count]];
        for (int i = 0; i < [baseFiles count]; i++) {
            [tempTime addObject:[NSNumber numberWithInt:i]];
        }
        timeStamp = tempTime;
    }
    
    _timeStampArray = timeStamp;
    
    // Initilaize progress bar
    
    int progressFinishCount = 0;
    
    for (int i = 0; i < [baseFiles count]; i++) {
        
        // Initialize the render model structure
        tmpModel = (RenderModel*) malloc(sizeof(RenderModel));
        
        // Load base file
        file = (NSString *) [baseFiles objectAtIndex:i];
        
        tmpModel->base = glmReadOBJ3([file UTF8String], 0, FALSE, FALSE);
        glmVertexNormals(tmpModel->base, 90);
        if (!tmpModel->base) {
            NSLog(@"Error: Unable to load model %@.\n", file);
            return (nil);
        }
        NSLog(@"MovieOBJ: Loading the base model %@.\n", file);
        [VEObjectOBJMovie generateArraysWithTransformation:tmpModel->base translation:translation rotation:rotation scale:scale config:nil];
        
        
        // Load Valve file
        tmpModel->hasValve = FALSE;
        file = (NSString *) [valveFiles objectAtIndex:i];
        if (file != nil) {
            tmpModel->valve = glmReadOBJ3([file UTF8String], 0, FALSE, FALSE);
            glmVertexNormals(tmpModel->valve, 90);
            if (!tmpModel->valve) {
                NSLog(@"Error: Unable to load model %@.\n", file);
                return (nil);
            }
            tmpModel->hasValve = TRUE;
            [VEObjectOBJMovie generateArraysWithTransformation:tmpModel->valve translation:translation rotation:rotation scale:scale config:nil];
            valveSize++;
            NSLog(@"MovieOBJ: Loading the valve model %@.\n", file);
            
            // Update progress
            progressFinishCount++;
            //[progress setCompletedUnitCount:progressFinishCount];
            
            [self.delegate incrementProgressBar];
        }
        
        // NSNumber
        tmpModel->timeStamp = [(NSNumber*) [timeStamp objectAtIndex:i] intValue];
        /// Need to check which pointer is good for release.
        [renderedObjects setObject: [NSValue valueWithPointer:(tmpModel)] forKey:[timeStamp  objectAtIndex:i]];
        
        // Update progress
        progressFinishCount++;
//        [progress setCompletedUnitCount:progressFinishCount];
        if (self.delegate && [self.delegate respondsToSelector:@selector(incrementProgressBar)])
            [self.delegate incrementProgressBar];
    }
    
    /// Add sort later. according to the time stamps.
    /*
    [renderedObjects sortUsingComparator:^NSComparisonResult(RenderModel* obj1, RenderModel* obj2) {
        return obj1->timeStamp < obj2->timeStamp ? obj1 : obj2;
    }];
     */
    size = [renderedObjects count];
    NSLog(@"VEObjectOBJMovie: in total %li base and %li valve", [renderedObjects count], valveSize);
    current = [(NSNumber*)[timeStamp firstObject] intValue];
    _drawable = TRUE;
    
    _fps = 0.1f;
    movieLoopInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(nextTimeStamp)]];
    [movieLoopInvocation setTarget:self];
    [movieLoopInvocation setSelector:@selector(nextTimeStamp)];
    
    _lit = TRUE;
    
    _disappearLatency = .0f;
    deferredVisibilityChangeTimer = nil;
    return self;
}

-(void) loadPatientWithInfo:(NSString*) patinetID  baseFiles:(NSArray *)baseFiles valveFiles:(NSArray *) valveFiles index:(NSArray*) timeStamp translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale
{
    
    _patientName = patinetID;
    valveSize = 0;
    // Create a new empty array.
    renderedObjects = [[NSMutableDictionary alloc] initWithCapacity:[baseFiles count]];
    
    RenderModel* tmpModel;
    NSString* file;
    
    if (valveFiles == nil) {
        hasValve = NO;
    }
    
    if (timeStamp == nil) {
        NSMutableArray* tempTime = [[NSMutableArray alloc]initWithCapacity:[baseFiles count]];
        for (int i = 0; i < [baseFiles count]; i++) {
            [tempTime addObject:[NSNumber numberWithInt:i]];
        }
        timeStamp = tempTime;
    }
    
    _timeStampArray = timeStamp;
    
    // Initilaize progress bar
    
    int progressFinishCount = 0;
    
    for (int i = 0; i < [baseFiles count]; i++) {
        
        // Initialize the render model structure
        tmpModel = (RenderModel*) malloc(sizeof(RenderModel));
        
        // Load base file
        file = (NSString *) [baseFiles objectAtIndex:i];
        
        tmpModel->base = glmReadOBJ3([file UTF8String], 0, FALSE, FALSE);
//        glmFacetNormals(tmpModel->base);
//        glmVertexNormals(tmpModel->base, 30);
        if (!tmpModel->base) {
            NSLog(@"Error: Unable to load model %@.\n", file);
            return ;
        }
        NSLog(@"MovieOBJ: Loading the base model %@.\n", file);
        [VEObjectOBJMovie generateArraysWithTransformation:tmpModel->base translation:translation rotation:rotation scale:scale config:nil];
        
        
        // Load Valve file
        tmpModel->hasValve = FALSE;
        file = (NSString *) [valveFiles objectAtIndex:i];
        if (file != nil) {
            tmpModel->valve = glmReadOBJ3([file UTF8String], 0, FALSE, FALSE);
//            glmFacetNormals(tmpModel->valve);
//            glmVertexNormals(tmpModel->valve, 30);
            if (!tmpModel->valve) {
                NSLog(@"Error: Unable to load model %@.\n", file);
                return ;
            }
            tmpModel->hasValve = TRUE;
            [VEObjectOBJMovie generateArraysWithTransformation:tmpModel->valve translation:translation rotation:rotation scale:scale config:nil];
            valveSize++;
            NSLog(@"MovieOBJ: Loading the valve model %@.\n", file);
            
            // Update progress
            progressFinishCount++;
            //[progress setCompletedUnitCount:progressFinishCount];
            
            [self.delegate incrementProgressBar];
        }
        
        // NSNumber
        tmpModel->timeStamp = [(NSNumber*) [timeStamp objectAtIndex:i] intValue];
        /// Need to check which pointer is good for release.
        [renderedObjects setObject: [NSValue valueWithPointer:(tmpModel)] forKey:[timeStamp  objectAtIndex:i]];
        
        // Update progress
        progressFinishCount++;
        //        [progress setCompletedUnitCount:progressFinishCount];
        if (self.delegate && [self.delegate respondsToSelector:@selector(incrementProgressBar)])
            [self.delegate incrementProgressBar];
    }
    
    /// Add sort later. according to the time stamps.
    /*
     [renderedObjects sortUsingComparator:^NSComparisonResult(RenderModel* obj1, RenderModel* obj2) {
     return obj1->timeStamp < obj2->timeStamp ? obj1 : obj2;
     }];
     */
    size = [renderedObjects count];
    NSLog(@"VEObjectOBJMovie: in total %li base and %li valve", [renderedObjects count], valveSize);
    current = [(NSNumber*)[timeStamp firstObject] intValue];
    _drawable = TRUE;
    
    _fps = 0.1f;
    movieLoopInvocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(nextTimeStamp)]];
    [movieLoopInvocation setTarget:self];
    [movieLoopInvocation setSelector:@selector(nextTimeStamp)];
    
    _lit = TRUE;
    
    _disappearLatency = .0f;
    deferredVisibilityChangeTimer = nil;
}


+(GLMmodel*)generateArraysWithTransformation:(GLMmodel*) glmModel translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale config:(char *)config
{
    BOOL flipV = FALSE;
    if(config){
        char *a = config;
        for (;;) {
            while( *a == ' ' || *a == '\t' ) a++; // Skip whitespace.
            if( *a == '\0' ) break; // End of string.
            
            if (strncmp(a, "TEXTURE_FLIPV", 13) == 0) flipV = TRUE;
            
            while( *a != ' ' && *a != '\t' && *a != '\0') a++; // Move to next token.
        }
        
    }
    if (scale && (scale[0] != 1.0f || scale[1] != 1.0f || scale[2] != 1.0f)) glmScale(glmModel, (scale[0] + scale[1] + scale[2]) / 3.0f);
    if (translation && (translation[0] != 0.0f || translation[1] != 0.0f || translation[2] != 0.0f)) glmTranslate(glmModel, translation);
    if (rotation && (rotation[0] != 0.0f)) glmRotate(glmModel, rotation[0]*DTOR, rotation[1], rotation[2], rotation[3]);
    
    //glmCreateArrays(glmModel, GLM_SMOOTH | GLM_MATERIAL | GLM_TEXTURE);
    glmCreateLargeArrays(glmModel, GLM_SMOOTH | GLM_MATERIAL | GLM_TEXTURE);
    
    return glmModel;
}



- (void) wasAddedToEnvironment:(VirtualEnvironment *)environment
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(draw:) name:ARViewDrawPreCameraNotification object:environment.arViewController.glView];
    [super wasAddedToEnvironment:environment];
}

- (void) willBeRemovedFromEnvironment:(VirtualEnvironment *)environment
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ARViewDrawPreCameraNotification object:environment.arViewController.glView];
    [super willBeRemovedFromEnvironment:environment];
}

- (void) draw: (NSNotification *)notification
{
    /// Main function to override.
    
    const GLfloat green[] = {0, 1, 0, 0.3};
    const GLfloat red[] = {1 , 0, 0, 0.7};
    
    RenderModel* renderCurrentModel = (RenderModel*) [(NSValue*)[renderedObjects objectForKey:[NSNumber numberWithInt:current]] pointerValue];
    if (renderCurrentModel == nil) {
        return;
    }
    GLMmodel *baseModel = renderCurrentModel->base;
    GLMmodel *valveModel = renderCurrentModel->valve;
    // Draw the current context.
    // If animated, then draw with a fresh rate.

    /// Draw the current model.
    
    const GLfloat lightWhite100[]        =    {1.00, 1.00, 1.00, 1.0};    // RGBA all on full.
    const GLfloat lightWhite75[]        =    {0.75, 0.75, 0.75, 1.0};    // RGBA all on three quarters.
    const GLfloat lightPosition0[]     =    {1.0f, 1.0f, 2.0f, 0.0f}; // A directional light (i.e. non-positional).
    
    if (_visible) {
        glPushMatrix();
        glMultMatrixf(_poseInEyeSpace.T);
        glMultMatrixf(_localPose.T);
        if (_lit) {
            /** Specilaized GL settings getting from MV project from CVLab. */
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            glClearDepthf(1.0f);
            glEnable(GL_DEPTH_TEST);
            glEnable(GL_NORMALIZE);
            glDepthFunc(GL_LEQUAL);
            glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
            glShadeModel(GL_SMOOTH);                // Do not flat shade polygons.
            
            /* Light information */
            GLfloat pos[] = {1.0, 3.0, 2.0, 0.0 };
            GLfloat light_ambient[] =  { 0.0f, 0.0f, -2.0f, 0.0f };
            GLfloat light_diffuse[] = { 1.0f, 1.0f, 1.0f, 0.0f };
            glLightfv(GL_LIGHT1, GL_POSITION,pos);
            glLightfv(GL_LIGHT1, GL_AMBIENT, light_ambient);
            glLightfv(GL_LIGHT1, GL_DIFFUSE, light_diffuse);
            
            /* Material */
            GLfloat no_mat[] = { 0.0f, 0.0f, 0.0f, 1.0f };
            GLfloat mat_diffuse[] = { 0.1f, 0.5f, 0.8f, 1.0f };
            GLfloat no_shininess[] = { 0.0f };
            
            /*----- Set material features -----*/
            glMaterialfv(GL_FRONT, GL_AMBIENT, no_mat);
            glMaterialfv(GL_FRONT, GL_DIFFUSE, mat_diffuse);
            glMaterialfv(GL_FRONT, GL_SPECULAR, no_mat);
            glMaterialfv(GL_FRONT, GL_SHININESS, no_shininess);
            glMaterialfv(GL_FRONT, GL_EMISSION, no_mat);

            glEnable(GL_LIGHTING);
            glEnable(GL_LIGHT1);
            
            /* Set light model */
            GLfloat lmodel_ambient[] = { 0.4f, 0.4f, 0.4f, 1.0f };
            glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
            
            /* Not available in OpenGL ES 1 */
            //GLfloat local_view[] = { 0, 0 };
            //glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);
            
            glStateCacheEnableLighting();
        } else glStateCacheDisableLighting();
       
        glClear(GL_DEPTH_BUFFER_BIT);
        
        if (valveModel != NULL) {
            glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, red);
            glmDrawArrays(valveModel, 0);
        }

        glEnable(GL_BLEND); // Add this to generate blend effect, for transparency.
        // glDepthMask(false);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE);
        if (baseModel != NULL){
            glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, green);
            glmDrawArrays(baseModel, 0);
        }
        glDepthMask(true);
        glDisable(GL_BLEND);
        
        glPopMatrix();
    }
}

// Override marker appearing/disappearing default behaviour.
- (void) markerNotification:(NSNotification *)notification
{
    ARMarker *marker = [notification object];
    
    if (marker) {
        if ([notification.name isEqualToString:ARMarkerDisappearedNotification]) {
            if (_disappearLatency) {
                // Don't change visibility immediately, but instead schedule it to occur in 2 seconds time.
                // If, during that time, the marker reappears, we can cancel the timer.
                // We will have the timer directly call setVisible:FALSE, so create an invocation which the
                // timer will use.
                NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:@selector(setVisible:)]];
                [invocation setTarget:self];
                [invocation setSelector:@selector(setVisible:)];
                BOOL arg = FALSE;
                [invocation setArgument:&arg atIndex:2]; // Index 0 is self, index 1 is _cmd.
                
                deferredVisibilityChangeTimer = [NSTimer scheduledTimerWithTimeInterval:(double)_disappearLatency invocation:invocation repeats:NO];
            } else {
                [self setVisible:FALSE];
            }
        } else if ([notification.name isEqualToString:ARMarkerAppearedNotification]) {
            if (deferredVisibilityChangeTimer) { // If the movie is scheduled to be hidden, cancel that.
                [deferredVisibilityChangeTimer invalidate];
                deferredVisibilityChangeTimer = nil;
            }
            [self setVisible:TRUE];
        } else {
            [super markerNotification:notification];
        }
    }
}


- (void) setVisible:(BOOL)visibleIn
{
    if (deferredVisibilityChangeTimer) { // Clean up our reference to timer that has fired.
        [deferredVisibilityChangeTimer invalidate]; // This message will be redundant if the timer has already fired, but setVisible can also be called by user, in which case we should cancel the timer.
        deferredVisibilityChangeTimer = nil;
    }
    if (visibleIn != self.isVisible) {
        if (visibleIn) [self setMoviePaused:FALSE];
        else [self setMoviePaused:TRUE];
    }
    
    if (visibleIn) {
        movieLoopingTimer = [NSTimer scheduledTimerWithTimeInterval:(double) _fps invocation:movieLoopInvocation repeats:YES];
    }
    else{
        [movieLoopingTimer invalidate];
        movieLoopingTimer = nil;
    }
    [super setVisible:visibleIn];
}


- (void) setMoviePaused:(BOOL)isPaused
{
    self.paused = isPaused;
    if (isPaused && movieLoopingTimer) {
        [movieLoopingTimer invalidate];
        movieLoopingTimer = nil;
    }
}

- (BOOL) isPaused
{
    return self.paused;
}


-(void) nextTimeStamp
{
    NSUInteger index = [_timeStampArray indexOfObject:[NSNumber numberWithInt: current]];
    index++;
    if (index == [_timeStampArray count]) {
        index = 0;
    }
    
    current = [[_timeStampArray objectAtIndex:index] intValue];
}

- (void)dealloc{
    for (NSString* key in [renderedObjects allKeys]){
        RenderModel* rdModel = (RenderModel*) [(NSValue*) [renderedObjects valueForKey:key] pointerValue];
        if (rdModel->base) {
            glmDelete(rdModel->base,0);
        }
        if (rdModel->valve) {
            glmDelete(rdModel->valve, 0);
        }
    }
//    
//    renderedObjects = nil;
//    timeStampArray = nil;
}



@end