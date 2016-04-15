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


@property(nonatomic, getter=isPaused) BOOL paused;
@property(readonly) NSComparator renderedObjectComparator;
@property(getter=currentTimeStamp, readonly) int currentTimeStamp;
@property(nonatomic,getter=getPatientName) NSString* patientName;

-(void) nextTimeStamp;
/**
 *  Initialize list of files.
 */
-(id)initFromListOfFiles: (NSString*) patientID baseFiles:(NSArray *)baseFiles valveFiles:(NSArray *) valveFiles index:(NSArray*) timeStamp translation:(const ARdouble [3])translation rotation:(const ARdouble [4])rotation scale:(const ARdouble [3])scale;

@end