//
//  IntroScene.m
//  Gravity
//
//  Created by Travis Fischer on 3/14/14.
//  Copyright Transitive Bullshit 2014. All rights reserved.
//
// -----------------------------------------------------------------------

// Import the interfaces
#import "IntroScene.h"
#import "HelloWorldScene.h"

@implementation IntroScene

+ (IntroScene *)scene
{
	return [[self alloc] init];
}

- (id)init
{
    if (self = [super init]) {
        CCNodeColor *background = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0 green:0 blue:0 alpha:1.0f]];
        [self addChild:background];
        
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Gravity" fontName:@"Chalkduster" fontSize:36.0f];
        label.positionType = CCPositionTypeNormalized;
        label.color = [CCColor whiteColor];
        label.position = ccp(0.5f, 0.5f);
        [self addChild:label];
        
        CCButton *helloWorldButton = [CCButton buttonWithTitle:@"[ Start ]" fontName:@"Verdana-Bold" fontSize:18.0f];
        helloWorldButton.positionType = CCPositionTypeNormalized;
        helloWorldButton.position = ccp(0.5f, 0.35f);
        [helloWorldButton setTarget:self selector:@selector(onStartTapped:)];
        [self addChild:helloWorldButton];
    }
    
	return self;
}

- (void)onStartTapped:(id)sender
{
    [[CCDirector sharedDirector] replaceScene:[HelloWorldScene scene]
                               withTransition:[CCTransition transitionCrossFadeWithDuration:0.3]];
}

@end
