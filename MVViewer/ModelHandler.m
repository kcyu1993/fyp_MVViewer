//
//  ModelHandler.m
//  ARToolKit5iOS
//
//  Created by Jack Yu on 10/4/2016.
//
//

#import "ModelHandler.h"

@implementation ModelHandler{
    NSComparisonResult (^comparitor)(id,id);}


- (instancetype)init
{
    self = [super init];
    if (self) {
        factor = [NSNumber numberWithFloat:0.1];
        patientNameLocation = [[NSMutableDictionary alloc]  init];
        patientNameBase = [[NSMutableDictionary alloc] init];
        patientNameValve = [[NSMutableDictionary alloc] init];
        
        comparitor = ^(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSString* first = (NSString*) obj1;
            NSString* second = (NSString*) obj2;
            NSRange bar = [first rangeOfString:@"_" options:NSBackwardsSearch];
            first = [first substringFromIndex:bar.location+1];
            NSRange dot = [first rangeOfString:@".obj" options:NSBackwardsSearch];
            first = [first substringToIndex:dot.location];
            int fir = (int)[first intValue];
            bar = [second rangeOfString:@"_" options:NSBackwardsSearch];
            second = [second substringFromIndex:bar.location+1];
            dot = [second rangeOfString:@".obj" options:NSBackwardsSearch];
            second = [second substringToIndex:dot.location];
            int sed = [second intValue];
            
            if (fir < sed) {
                return (NSComparisonResult) NSOrderedAscending;
            }
            if (fir > sed) {
                return (NSComparisonResult) NSOrderedDescending;
            }
            return (NSComparisonResult) NSOrderedSame;
        };

    }
    return self;
}

-(NSUInteger) readPatientFoldersWithRootFolder:(NSString *)rootFolderPath
{
    NSString* factorStr = [[factor stringValue] stringByAppendingString:@"_F"];
    int count = 0;
    
    rootFolder = rootFolderPath;
    NSLog(@"Root folder %@ ",rootFolder);
    if (![rootFolderPath hasPrefix:@"/"]) {
        rootFolder = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/"] stringByAppendingString:rootFolderPath];
    }
    
    NSError* error;
    NSArray* directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:rootFolder error:&error];
    NSString* tempDirectory;
    NSString* patientName;
    
    for (int i = 0; i < directoryContent.count; i++) {
        
        patientName = (NSString*) [directoryContent objectAtIndex:i];
        
        tempDirectory = [[rootFolderPath stringByAppendingString:@"/"] stringByAppendingString:patientName];
        BOOL isDirectory = NO;
        // BOOL isFile = [[NSFileManager defaultManager] fileExistsAtPath:tempDirectory];
        if ([[NSFileManager defaultManager] fileExistsAtPath:tempDirectory isDirectory:&isDirectory] && isDirectory) {
            //Is directory and could further break down.
            [patientNameLocation setObject:[[tempDirectory stringByAppendingString:@"/" ] stringByAppendingString:factorStr] forKey:patientName];
            count ++;
        }
    }
    
    int index = 0;
    for (NSString* key in [patientNameLocation allKeys]) {
        NSLog(@"Key: %@",key);
        [self loadPatientModelsWithFolderPath: key directory:[patientNameLocation objectForKey:key] index:index];
        index++;
       
    }
    // [[NSBundle mainBundle] resourcePath]
    
    return count;
}

-(NSUInteger) loadPatientModelsWithFolderPath:(NSString *)patientName  directory: (NSString*) directory index: (NSUInteger) index
{
    NSLog(@"Loading patient %@ at index %li", patientName,(unsigned long)index);
    
    NSError* error;
    NSArray* directoryContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:&error];
    
    
    NSArray* objFiles = [directoryContents filteredArrayUsingPredicate: [NSPredicate predicateWithFormat:@"self ENDSWITH '.obj'"]];
    NSMutableArray* directoryContentsWithFullPath = [[NSMutableArray alloc] initWithArray:objFiles];
    // Get the full path.
    for (NSUInteger i = 0; i < [directoryContentsWithFullPath count]; i++) {
        
        NSString* objectPath = [directoryContentsWithFullPath objectAtIndex:i];
        NSString* objectFullPath;
        if ([objectPath hasPrefix:@"/"]) {
            objectFullPath = objectPath;
        }
        else {
            objectFullPath = [[directory stringByAppendingString:@"/"]stringByAppendingString:objectPath];
        }
        [directoryContentsWithFullPath replaceObjectAtIndex:i withObject:objectFullPath];
    }
    
    
    NSArray* baseFiles = [directoryContentsWithFullPath filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self CONTAINS 'base'"]];
    NSArray* valveFiles = [directoryContentsWithFullPath filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self CONTAINS 'valve'"]];
    
    
    NSArray* sortedBaseFiles = [baseFiles sortedArrayUsingComparator:comparitor];
    NSArray* sortedValveFiles = [valveFiles sortedArrayUsingComparator:comparitor];
    
    [patientNameBase setObject:sortedBaseFiles forKey:patientName];
    [patientNameValve setObject:sortedValveFiles forKey:patientName];
    
    baseFiles = sortedBaseFiles;
    valveFiles = sortedValveFiles;
    if (baseFiles) {
        NSLog(@"Base ObjFiles count %li", [baseFiles count]);
        
//        for (NSString* tmpStr in baseFiles){
//            NSLog(@"Path: %@", tmpStr);
//            
//        }
    }
    
    if (valveFiles) {
        NSLog(@"Base ObjFiles count %li", [valveFiles count]);
//        for (NSString* tmpStr in valveFiles){
//            NSLog(@"Path: %@", tmpStr);
//        }
    }
    
    
    return [baseFiles count];
}


-(BOOL) checkPatientExistence:(NSString*) patientName
{
    return [patientNameLocation objectForKey:patientName] == nil ? NO : YES;
}

-(NSUInteger) getPatientSize
{
    return [patientNameLocation count];
}

-(NSArray*) getPatientBaseModelPaths:(NSString*) patientName
{
    return [patientNameBase objectForKey:patientName];
}

-(NSArray*) getPatientValveModelPaths:(NSString*) patientName
{
    return [patientNameValve objectForKey: patientName];
}

- (NSArray*) getPatientFullList
{
    return [patientNameLocation allKeys];
    
}







@end