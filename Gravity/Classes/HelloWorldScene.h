//
//  HelloWorldScene.h
//  Gravity
//
//  Created by Travis Fischer on 3/14/14.
//  Copyright Transitive Bullshit 2014. All rights reserved.
//
// -----------------------------------------------------------------------

#import "cocos2d.h"
#import "cocos2d-ui.h"

@interface HelloWorldScene : CCScene <CCPhysicsCollisionDelegate>

+ (HelloWorldScene *)scene;
- (id)init;

@end
