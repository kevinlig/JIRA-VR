//
//  PebbleController.m
//  Unity-iPhone
//
//  Created by Kevin Li on 3/31/15.
//
//

#import "PebbleController.h"

@implementation PebbleController

- (PBWatch *)startController {
    PBWatch *thisWatch = [[PBPebbleCentral defaultCentral]lastConnectedWatch];
    
    
    // set up app
    uuid_t myAppUUIDbytes;
    NSUUID *myAppUUID = [[NSUUID alloc] initWithUUIDString:@"60312834-83b4-4ccf-a335-8a7c8138e6c7"];
    [myAppUUID getUUIDBytes:myAppUUIDbytes];
    
    [[PBPebbleCentral defaultCentral] setAppUUID:[NSData dataWithBytes:myAppUUIDbytes length:16]];
    
    return thisWatch;
}

@end
