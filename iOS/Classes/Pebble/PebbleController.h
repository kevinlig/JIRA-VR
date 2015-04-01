//
//  PebbleController.h
//  Unity-iPhone
//
//  Created by Kevin Li on 3/31/15.
//
//

#import <Foundation/Foundation.h>
#import <PebbleKit/PebbleKit.h>

@interface PebbleController : NSObject

@property (nonatomic, strong) PBWatch *myWatch;

- (PBWatch *)startController;

@end
