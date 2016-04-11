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


@implementation VEObjectOBJMovie{
    // NSMutableArray *baseOBJArray;
    // NSMutableArray *valveOBJArray;
    // NSMutableIndexSet *timeStampArray;
    NSMutableDictionary* renderedObjects;
    NSArray* timeStampArray;
    NSUInteger size;
    NSUInteger valveSize;
    BOOL hasValve;
    int current;
}


+(void)load{
    VEObjectRegistryRegister(self, @"objs");
}

-(id)initFromListOfFiles:(NSArray *)baseFiles valveFiles:(NSArray *) valveFiles index:(NSArray*) timeStamp translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale
{
    self = [super initFromFile:nil translation:translation rotation:rotation scale:scale];
    
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
    
    timeStampArray = timeStamp;
    
    for (int i = 0; i < [baseFiles count]; i++) {
        
        // Initialize the render model structure
        tmpModel = (RenderModel*) malloc(sizeof(RenderModel));
        
        // Load base file
        file = (NSString *) [baseFiles objectAtIndex:i];
        
        tmpModel->base = glmReadOBJ3([file UTF8String], 0, FALSE, FALSE);
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
            if (!tmpModel->valve) {
                NSLog(@"Error: Unable to load model %@.\n", file);
                return (nil);
            }
            tmpModel->hasValve = TRUE;
            [VEObjectOBJMovie generateArraysWithTransformation:tmpModel->valve translation:translation rotation:rotation scale:scale config:nil];
            valveSize++;
            NSLog(@"MovieOBJ: Loading the valve model %@.\n", file);
        }
        
        // NSNumber
        tmpModel->timeStamp = [(NSNumber*) [timeStamp objectAtIndex:i] intValue];
        /// Need to check which pointer is good for release.
        [renderedObjects setObject: [NSValue valueWithPointer:(tmpModel)] forKey:[timeStamp  objectAtIndex:i]];
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
    return self;
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
            glLightfv(GL_LIGHT0, GL_DIFFUSE, lightWhite100);
            glLightfv(GL_LIGHT0, GL_SPECULAR, lightWhite100);
            glLightfv(GL_LIGHT0, GL_AMBIENT, lightWhite75);            // Default ambient = {0,0,0,0}.
            glLightfv(GL_LIGHT0, GL_POSITION, lightPosition0);
            glEnable(GL_LIGHT0);
            /** Specilaized GL settings getting from Audrey. */
            glEnable(GL_BLEND); // Add this to generate blend effect, for transparency.
            glDisable(GL_LIGHT1);
            glDisable(GL_LIGHT2);
            glDisable(GL_LIGHT3);
            glDisable(GL_LIGHT4);
            glDisable(GL_LIGHT5);
            glDisable(GL_LIGHT6);
            glDisable(GL_LIGHT7);
            glShadeModel(GL_SMOOTH);                // Do not flat shade polygons.
            glStateCacheEnableLighting();
        } else glStateCacheDisableLighting();
        if  (baseModel != NULL)
            glmDrawArrays(baseModel, 0);
        if (valveModel != NULL) {
            glmDrawArrays(valveModel, 0);
        }
        glPopMatrix();
    }
}


-(void) nextTimeStamp
{
    NSUInteger index = [timeStampArray indexOfObject:[NSNumber numberWithInt: current]];
    index++;
    if (index == [timeStampArray count]) {
        index = 0;
    }
    
    current = [[timeStampArray objectAtIndex:index] intValue];
}

@end