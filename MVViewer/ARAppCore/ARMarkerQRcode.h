//
//  ARMarkerQRcode.h
//  ARToolKit5iOS
//
//  Created by Helen Zheng on 16/1/26.
//
//

#import "ARMarker.h"

@interface ARMarkerQRcode : ARMarker {
}

- (void) updateWithDetectedMarkers:(ARMarkerInfo *)markerInfo count:(int)markerNum ar3DHandle:(AR3DHandle *)ar3DHandle;
@end
