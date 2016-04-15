//
//  ModelHandler.h
//  ARToolKit5iOS
//
//  Created by Jack Yu on 10/4/2016.
//
//

#ifndef ModelHandler_h
#define ModelHandler_h


#endif /* ModelHandler_h */

#import <Foundation/Foundation.h>
#import "PatientsArray.h"

@interface ModelHandler : NSObject {
    NSMutableDictionary* patientNameLocation;
    NSMutableDictionary* patientNameBase;
    NSMutableDictionary* patientNameValve;
    NSString* rootFolder;
    
    NSNumber* factor;
}

-(NSUInteger) readPatientFoldersWithRootFolder:(NSString *)rootFolder;

-(BOOL) checkPatientExistence:(NSString*) patientName;

-(NSUInteger) getPatientSize;

- (NSArray*) getPatientFullList;

-(NSArray*) getPatientBaseModelPaths:(NSString*) patientName;

-(NSArray*) getPatientValveModelPaths:(NSString*) patientName;




@end