//
//  VEObjectOBJValve.m
//  ARToolKit5iOS
//
//  Created by Jack Yu on 17/3/2016.
//
//

#import "VEObjectOBJValve.h"


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

@interface VEObjectOBJValve()
@end

@implementation VEObjectOBJValve{

}

- (id) initFromFile:(NSString *)file translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale
{
    
    return self;
}

@end