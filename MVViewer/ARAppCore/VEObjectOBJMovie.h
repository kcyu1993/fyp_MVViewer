//
//  VEObjectOBJMovie.h
//  ARToolKit5iOS
//
//  Created by Jack Yu on 21/2/2016.
//
//

#ifndef VEObjectOBJMovie_h
#define VEObjectOBJMovie_h


#endif /* VEObjectOBJMovie_h */

#import "VEObject.h"

@interface VEObjectOBJMovie : VEObject{

    
}
@property(readonly) NSComparator renderedObjectComparator;
@property(getter=currentTimeStamp, readonly) int currentTimeStamp;
-(void) nextTimeStamp;

@end