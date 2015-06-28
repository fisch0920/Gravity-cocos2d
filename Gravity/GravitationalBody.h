//
//  GravitationalBody.h
//  Gravity
//
//  Created by Travis Fischer on 3/14/14.
//  Copyright 2014 Transitive Bullshit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GravitationalBody : CCNode

- (id)initWithNumNodes:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor;

@property (nonatomic) NSInteger numNodes;
@property (nonatomic) CGFloat threshold;
@property (nonatomic) CGFloat compression;

@property (nonatomic) CGFloat radius;
@property (nonatomic) CGFloat scaleFactor;

@end
