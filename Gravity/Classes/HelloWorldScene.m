//
//  HelloWorldScene.m
//  Gravity
//
//  Created by Travis Fischer on 3/14/14.
//  Copyright Transitive Bullshit 2014. All rights reserved.
//
// -----------------------------------------------------------------------

#import "HelloWorldScene.h"
#import "IntroScene.h"
#import "GravitationalBody.h"
#import "GravitationalBodyNode.h"
@import CoreMotion;

@implementation HelloWorldScene
{
    CCPhysicsNode *_physicsWorld;
    GravitationalBody *_body;
    
    UISlider *_slider;
    GravitationalBodyNode *_node;
    
    NSOperationQueue *_queue;
    CMMotionManager *_manager;
    
    CMAttitude *_referenceAttitude;
}

#pragma mark - Create & Destroy

+ (HelloWorldScene *)scene
{
    return [[self alloc] init];
}

- (id)init
{
    if (self = [super init]) {
        _queue = [NSOperationQueue new];
        
        self.userInteractionEnabled = YES;
        
        CCNodeColor *background = [CCNodeColor nodeWithColor:[CCColor colorWithRed:0 green:0 blue:0 alpha:1.0f]];
        [self addChild:background];
        
        _physicsWorld = [CCPhysicsNode node];
//        _physicsWorld.gravity = ccp(0, -1);
        _physicsWorld.debugDraw = NO;
        _physicsWorld.collisionDelegate = self;
        _physicsWorld.positionType = CCPositionTypeNormalized;
        _physicsWorld.position = ccp(0.5, 0.5);
        [self addChild:_physicsWorld];
        
//        for (int i = 0; i < 12; ++i) {
//            GravitationalBody *body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0/3.2];
//            body.position = ccp(CCRANDOM_MINUS1_1() * 100, CCRANDOM_MINUS1_1() * 250);
//            body.color = [CCColor colorWithRed:CCRANDOM_0_1() / 10.0 green:0.0 blue:0.0];
//            [_physicsWorld addChild:body];
//        }
        
//        _body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0/3.2];
//        _body.position = ccp(-160, -80);
//        _body.color = [CCColor colorWithRed:0.1 green:0.0 blue:0.0];
//        [_physicsWorld addChild:_body];
//        
//        _body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0/4.0];
//        _body.position = ccp(-160, 80);
//        _body.color = [CCColor colorWithRed:0.1 green:0.0 blue:0.0];
//        [_physicsWorld addChild:_body];
//
        
        // 50 works well too
        _body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0 / 1.2];
        _body.position = ccp(0, 0);
        _body.color = [CCColor colorWithRed:0.0 green:0.0 blue:0.0];
        
//        _body.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:100 andCenter:_body.position];
//        _body.physicsBody.collisionGroup = [GravitationalBody class];
//        _body.physicsBody.affectedByGravity = YES;
        
        [_physicsWorld addChild:_body];
//
//        _body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0/2.2];
//        _body.color = [CCColor colorWithRed:0.1 green:0.0 blue:0.0];
//        _body.position = ccp(160, 80);
//        [_physicsWorld addChild:_body];
//        
//        _body = [[GravitationalBody alloc] initWithNumNodes:75 andRadius:100 andScaleFactor:1.0/2.35];
//        _body.color = [CCColor colorWithRed:0.1 green:0.0 blue:0.0];
//        _body.position = ccp(160, -80);
//        [_physicsWorld addChild:_body];
        
//        CGPoint *points = malloc(sizeof(CGPoint) * 3);
//        points[0] = ccp(-80, -80);
//        points[1] = ccp(80, -80);
//        points[2] = ccp(0, 80);
//        
//        CCNode *boundary = [CCNode node];
//        boundary.physicsBody = [CCPhysicsBody bodyWithPolylineFromPoints:points count:3 cornerRadius:1.0 looped:YES];
//        [_physicsWorld addChild:boundary];
        
        CCButton *backButton = [CCButton buttonWithTitle:@"[ Menu ]" fontName:@"Verdana-Bold" fontSize:18.0f];
        backButton.positionType = CCPositionTypeNormalized;
        backButton.position = ccp(0.85f, 0.95f);
        [backButton setTarget:self selector:@selector(onBackClicked:)];
        [self addChild:backButton];
    }
    
	return self;
}

- (void)thresholdSliderChanged:(id)sender
{
    for (CCNode *node in _physicsWorld.children) {
        if ([node isKindOfClass:[GravitationalBody class]]) {
            GravitationalBody *body = (GravitationalBody*)node;
            
            body.threshold = ((UISlider*)sender).value;
        }
    }
}

- (void)onEnter
{
    [super onEnter];
    
    _slider = [[UISlider alloc] initWithFrame:CGRectMake(8, self.boundingBox.size.height - 40, self.boundingBox.size.width / 2 - 16, 30)];
    [_slider setMinimumValue:0.0];
    [_slider setMaximumValue:0.995];
    [_slider setValue:0.91];
    [_slider addTarget:self action:@selector(thresholdSliderChanged:) forControlEvents:UIControlEventValueChanged];
    _slider.backgroundColor = [UIColor clearColor];
    [[[CCDirector sharedDirector] view] addSubview:_slider];
    
    _manager = [CMMotionManager new];
    
    if (_manager.deviceMotionAvailable) {
        [_manager startDeviceMotionUpdatesToQueue:_queue
                                      withHandler:
         ^(CMDeviceMotion *data, NSError *error) {
             if (!_referenceAttitude) {
                 _referenceAttitude = _manager.deviceMotion.attitude;
             }
             
             [data.attitude multiplyByInverseOfAttitude:_referenceAttitude];
             double rotation = -data.attitude.yaw * 180.0 / M_PI;
             
             _body.rotation = rotation;
         }];
    }
}

- (void)onExit
{
    [_manager stopDeviceMotionUpdates];
    [_slider removeFromSuperview];
    _referenceAttitude = nil;
    
    [super onExit];
}

//-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    GravitationalBodyNode *node = [[GravitationalBodyNode alloc] init];
//    CGPoint pos = ccpMult([touch locationInNode:_body], 0.5);
//    
//    node.position = pos;
//    node.radius = 60;
//    node.color = [CCColor greenColor];
//    node.debug = YES;
//    
//    node.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:node.radius andCenter:node.position];
//    node.physicsBody.mass = node.radius;
//    node.physicsBody.type = CCPhysicsBodyTypeStatic;
//    
//    _node = node;
//    [_body addChild:node];
////    self.paused = !self.paused;
//}
//
//- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    [_body removeChild:_node];
//    GravitationalBodyNode *node = [[GravitationalBodyNode alloc] init];
//    
//    CGPoint pos = ccpMult([touch locationInNode:_body], 0.5);
//    node.position = pos;
//    node.radius = 60;
//    node.color = [CCColor greenColor];
//    node.debug = YES;
//    
//    node.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:node.radius andCenter:node.position];
//    node.physicsBody.mass = node.radius;
//    node.physicsBody.type = CCPhysicsBodyTypeStatic;
//    
//    _node = node;
//    [_body addChild:node];
//}
//
//- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
//{
//    [_body removeChild:_node];
//    _node = nil;
//}

-(void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    for (CCNode *node in _physicsWorld.children) {
        if ([node isKindOfClass:[GravitationalBody class]]) {
            GravitationalBody *body = (GravitationalBody*)node;
            body.compression = 1;
        }
    }
}

- (void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    for (CCNode *node in _physicsWorld.children) {
        if ([node isKindOfClass:[GravitationalBody class]]) {
            GravitationalBody *body = (GravitationalBody*)node;
            body.compression = 0;
        }
    }
}

- (void)onBackClicked:(id)sender
{
    [[CCDirector sharedDirector] replaceScene:[IntroScene scene]
                               withTransition:[CCTransition transitionCrossFadeWithDuration:0.3]];
}

@end
