//
//  GravitationalBodyCache.h
//  Gravity
//
//  Created by Travis Fischer on 3/28/14.
//  Copyright (c) 2014 Transitive Bullshit. All rights reserved.
//

#import <Foundation/Foundation.h>

@class GravitationalBody;

@interface GravitationalBodyCache : NSObject

+ (GravitationalBodyCache*)sharedCache;

- (GravitationalBody*)getBody:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor;
//- (void)removeBody:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor;

@end
