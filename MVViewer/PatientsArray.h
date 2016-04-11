//
//  PatientsArray.h
//  ARToolKit5iOS
//
//  Created by Jack Yu on 10/4/2016.
//
//

#import <Foundation/Foundation.h>


@interface PatientsArray : NSObject{
    NSMutableArray *sections;
    
}

@property NSArray* baseFiles;
@property NSArray* valveFiles;
@property NSString* name;

/*
-initWithPatientNumbers:(NSUInteger)intPatientNumber:(NSUInteger)maxTimeSize;
+patientsArrayWithSpecifications:(NSUInteger)intPatientNumber:(NSUInteger)maxTimeSize;
-(NSString*) objectInPatient:(NSUInteger)patientIndex:(NSUInteger)timeStamp;
-(void) setObject:(NSString *)object:(NSUInteger)patientIndex:(NSUInteger)timeStamp;

*/
@end