//
//  ResourceManager.m
//  ARToolKit5iOS
//
//  Created by Jack Yu on 28/3/2016.
//
//


#import "ResourceManager.h"

@implementation ResourceManager {
    
}

- (ResourceManager *) initWithApplicationLaunch
{
    // Read all folder under given resource folder.
    NSString* rootResourceFolderPath = [[NSBundle mainBundle] resourcePath];
    NSLog(@"Given the folder path %@", rootResourceFolderPath);
    
    return self;
}

@end
