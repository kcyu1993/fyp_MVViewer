//
//  ResourceManager.h
//  ARToolKit5iOS
//
//  Created by Jack Yu on 28/3/2016.
//
//

#ifndef ResourceManager_h
#define ResourceManager_h


#endif /* ResourceManager_h */
#import <Foundation/Foundation.h>

/**
 Implement a ResourceManager that can
 Get folder names from /Documents/ (The file directory that can be access from iTunes
 Pass the list to GUI, let user to choose
 Pass the choice (file directory path or simply folder name
*/


@class ResourceManager;
@interface ResourceManager : NSObject {
    
}

- (ResourceManager *) initWithApplicationLaunch;

@property NSMutableArray* patientFolderList;

@end
