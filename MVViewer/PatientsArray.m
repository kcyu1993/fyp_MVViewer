//
//  PatientsArray.m
//  ARToolKit5iOS
//
//  Created by Jack Yu on 10/4/2016.
//
//

#import "PatientsArray.h"

@implementation PatientsArray
/*
-(id)initWithPatientNumbers:(NSUInteger)intPatientNumber :(NSUInteger)maxTimeSize
{
    
    if (self == [self init]) {
        sections = [[NSMutableArray alloc] initWithCapacity:intPatientNumber];
        for (int i = 0; i < intPatientNumber; i++) {
            NSMutableArray *temp = [NSMutableArray arrayWithCapacity:maxTimeSize];
            for (int j = 0; j < maxTimeSize; j++){
                [temp insertObject:[NSNull null] atIndex:j];
            }
            [sections addObject:temp];
        }
    }
    return self;
}

- (void)setObject:(NSString *)object :(NSUInteger)patientIndex :(NSUInteger)timeStamp
{
    [[sections objectAtIndex:patientIndex] replaceObjectAtIndex:timeStamp withObject:object];
}

- (NSString*)objectInPatient:(NSUInteger)patientIndex :(NSUInteger)timeStamp
{
    return (NSString*) [[sections objectAtIndex:patientIndex] objectAtIndex:timeStamp];

}

+(id)patientsArrayWithSpecifications:(NSUInteger)intPatientNumber :(NSUInteger)maxTimeSize{
    return [[self alloc] initWithPatientNumbers:intPatientNumber :maxTimeSize];
}
*/

@end