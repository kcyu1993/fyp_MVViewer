//
//  VEObjectOBJ.m
//  ARToolKit for iOS
//
//  Disclaimer: IMPORTANT:  This Daqri software is supplied to you by Daqri
//  LLC ("Daqri") in consideration of your agreement to the following
//  terms, and your use, installation, modification or redistribution of
//  this Daqri software constitutes acceptance of these terms.  If you do
//  not agree with these terms, please do not use, install, modify or
//  redistribute this Daqri software.
//
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Daqri grants you a personal, non-exclusive
//  license, under Daqri's copyrights in this original Daqri software (the
//  "Daqri Software"), to use, reproduce, modify and redistribute the Daqri
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Daqri Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Daqri Software.
//  Neither the name, trademarks, service marks or logos of Daqri LLC may
//  be used to endorse or promote products derived from the Daqri Software
//  without specific prior written permission from Daqri.  Except as
//  expressly stated in this notice, no other rights or licenses, express or
//  implied, are granted by Daqri herein, including but not limited to any
//  patent rights that may be infringed by your derivative works or by other
//  works in which the Daqri Software may be incorporated.
//
//  The Daqri Software is provided by Daqri on an "AS IS" basis.  DAQRI
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE DAQRI SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//  IN NO EVENT SHALL DAQRI BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE DAQRI SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF DAQRI HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright 2015 Daqri LLC. All Rights Reserved.
//  Copyright 2010-2015 ARToolworks, Inc. All rights reserved.
//
//  Author(s): Philip Lamb
//

#import "VEObjectOBJ.h"
#import "VirtualEnvironment.h"
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "glStateCache.h"
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
#import <sys/param.h> // MAXPATHLEN
#import <Eden/EdenMath.h>


#import "ARView.h"
#import "../ARViewController.h"

@interface VEObjectOBJ()
-(void) drawCoordinates;
@end

@implementation VEObjectOBJ {
//    GLMmodel *glmModel;
}

+ (void)load
{
    VEObjectRegistryRegister(self, @"obj");
}

- (id) initFromFile:(NSString *)file translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale config:(char *)config
{
    if ((self = [super initFromFile:file translation:translation rotation:rotation scale:scale config:config])) {
        
        // Process config, if supplied.
        BOOL flipV = FALSE;
        if (config) {
            char *a = config;
            for (;;) {
                while( *a == ' ' || *a == '\t' ) a++; // Skip whitespace.
                if( *a == '\0' ) break; // End of string.
                
                if (strncmp(a, "TEXTURE_FLIPV", 13) == 0) flipV = TRUE;
                
                while( *a != ' ' && *a != '\t' && *a != '\0') a++; // Move to next token.
            }
        }
        
        glmModel = glmReadOBJ3([file UTF8String], 0, FALSE, flipV); // 0 -> contextIndex, FALSE -> read textures later.
        if (!glmModel) {
            NSLog(@"Error: Unable to load model %@.\n", file);
            return (nil);
        }

        if (scale && (scale[0] != 1.0f || scale[1] != 1.0f || scale[2] != 1.0f)) glmScale(glmModel, (scale[0] + scale[1] + scale[2]) / 3.0f);
        if (translation && (translation[0] != 0.0f || translation[1] != 0.0f || translation[2] != 0.0f)) glmTranslate(glmModel, translation);
        if (rotation && (rotation[0] != 0.0f)) glmRotate(glmModel, rotation[0]*DTOR, rotation[1], rotation[2], rotation[3]);
        
        //glmCreateArrays(glmModel, GLM_SMOOTH | GLM_MATERIAL | GLM_TEXTURE);
        glmCreateLargeArrays(glmModel, GLM_SMOOTH | GLM_MATERIAL | GLM_TEXTURE);
        
        _drawable = TRUE;

    }
    return (self);
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

-(void) draw:(NSNotification *)notification
{
    // Lighting setup.
    const GLfloat green[] = {0, 1, 0, 0.3};
    //const GLfloat red[] = {1 , 0, 0, 0.7};
    if (_visible) {
        glPushMatrix();
        glMultMatrixf(_poseInEyeSpace.T);
        glMultMatrixf(_localPose.T);
        
        if (_lit) {
            
            /** Specilaized GL settings getting from Audrey. */

            /* Light information */
            GLfloat pos[] = {1.0, 3.0, 2.0, 0.0 };
            GLfloat light_ambient[] =  { 0.0f, 0.0f, -2.0f, 0.0f };
            GLfloat light_diffuse[] = { 0.25, 0.25, 0.25, 0.0f };
            glLightfv(GL_LIGHT1, GL_POSITION,pos);
            glLightfv(GL_LIGHT1, GL_AMBIENT, light_ambient);
            glLightfv(GL_LIGHT1, GL_DIFFUSE, light_diffuse);
            
            glEnable(GL_LIGHTING);
            glEnable(GL_LIGHT1);
            
            /* Set light model */
            GLfloat lmodel_ambient[] = { 0.4f, 0.4f, 0.4f, 1.0f };
            //            GLfloat local_view[] = { 0, 0 };
            glLightModelfv(GL_LIGHT_MODEL_AMBIENT, lmodel_ambient);
            //            glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);
            
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
            glEnable(GL_BLEND); // Add this to generate blend effect, for transparency.
            glDepthMask(false);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);
            glShadeModel(GL_SMOOTH);                // Do not flat shade polygons.
            glStateCacheEnableLighting();
        } else glStateCacheDisableLighting();
        
        glMaterialfv(GL_FRONT, GL_AMBIENT_AND_DIFFUSE, green);
        glmDrawArrays(glmModel, 0);

        glPopMatrix();
        glDepthMask(true);
        glDisable(GL_LIGHTING);
        glDisable(GL_BLEND);
    }
#ifdef DEBUG
    CHECK_GL_ERROR();
#endif
}

-(void) drawCoordinates
{
    GLfloat axis[4][3] = {{0,0,0},{1,0,0},{0,1,0},{0,0,1}};
    GLbyte indice[3][2] = { { 0,1}, {0,2},{0,3}};
    GLbyte color[3][4] = {{255,0,0,255},{0,255,0,255},{0,0,255,255}};
    
    glVertexPointer(3, GL_FLOAT, 0, axis);
    glLineWidth(2);
    glDrawElements(GL_LINES, 3, GL_BYTE, indice);
    
}

-(void) dealloc
{
    glmDelete(glmModel, 0); // Does an implicit glmDeleteArrays();

}

@end
