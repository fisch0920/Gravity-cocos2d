//
//  GravitationalBodyNode.h
//  Gravity
//
//  Created by Travis Fischer on 3/17/14.
//  Copyright 2014 Transitive Bullshit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface GravitationalBodyNode : CCNode

@property (nonatomic) CGFloat radius;
@property (nonatomic) BOOL debug;

- (void)debugDraw;

@end
