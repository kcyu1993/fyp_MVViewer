//
//  ARMarkerQRcode.m
//  ARToolKit5iOS
//
//  Created by Helen Zheng on 16/1/26.
//
//
#import "ARMarkerQRcode.h"
@implementation ARMarkerQRcode{}

- (id) init
{
    if ((self = [super init])) {
        marker_width=80;
        marker_height=80;
        NSLog(@"init succeeded");
    }
    return (self);
}


- (void) updateWithDetectedMarkers:(ARMarkerInfo *)markerInfo count:(int)markerNum ar3DHandle:(AR3DHandle *)ar3DHandle
{
    ARdouble err;

    
    validPrev = valid;
    if (markerInfo && markerNum > 0 && ar3DHandle) {
        // Check through the marker_info array for highest confidence
        // visible marker matching our preferred pattern.

            valid = TRUE;
            // Get the transformation between the marker and the real camera into trans.
        for ( int i=0; i<4; ++i )
            for (int j=0; j<2; ++j)
                NSLog(@"markerinfo %f", markerInfo[0].vertex[i][j]);
        NSLog(@"direction %d", markerInfo[0].dir);
        err = arGetTransMatSquare(ar3DHandle, &markerInfo[0], marker_width, trans);
        //NSLog(@"err= %f", err);
        //for ( int i=0; i<3; ++i )
        //    for (int j=0; j<4; ++j)
        //        NSLog(@"trans %f", trans[i][j]);
        
    } else {
        valid = FALSE;
    }
    
    [super update];
}

-(void) update
{
    [self updateWithDetectedMarkers:NULL count:0 ar3DHandle:NULL];
}

@end
