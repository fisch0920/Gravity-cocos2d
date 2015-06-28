//
//  GravitationalBody.m
//  Gravity
//
//  Created by Travis Fischer on 3/14/14.
//  Copyright 2014 Transitive Bullshit. All rights reserved.
//

#import "GravitationalBody.h"
#import "GravitationalBodyNode.h"

#import <ObjectiveChipmunk/ObjectiveChipmunk.h>
#import <chipmunk/chipmunk.h>

static const CGFloat kGravitationalBodyMaxForce = 5000.0;
static const CGFloat kGravitationalBodyMaxVelocity = 200.0;

static GravitationalBody *s_primaryBody;

@interface GravitationalBody ()

@property (nonatomic) CGPoint *_forces;
@property (nonatomic) BOOL _hasForces;

@property (nonatomic, strong) CCRenderTexture *_renderTexture;
@property (nonatomic, strong) CCGLProgram *_program;

@property (nonatomic) GLint _thresholdUniform;

@property (nonatomic, strong) NSMutableArray *_joints;
@property (nonatomic, strong) NSArray *_originalJointDistances;

@property (nonatomic) BOOL _isPrimary;

@end

@implementation GravitationalBody

- (id)initWithNumNodes:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor
{
    if (self = [super init]) {
        self.numNodes = numNodes;
        
        NSString *key = [self class].description;
        self._program = [[CCShaderCache sharedShaderCache] programForKey:key];
        
        if (!self._program) {
            NSString *vs = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GravitationalBody" ofType:@"vs"] encoding:NSUTF8StringEncoding error:nil];
            const GLchar *vert = (GLchar*)[vs UTF8String];
            
            NSString *fs = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GravitationalBody" ofType:@"fs"] encoding:NSUTF8StringEncoding error:nil];
            const GLchar *frag = (GLchar*)[fs UTF8String];
            
            self._program = [[CCGLProgram alloc] initWithVertexShaderByteArray:vert fragmentShaderByteArray:frag];
            
            [self._program addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
            [self._program addAttribute:kCCAttributeNameColor    index:kCCVertexAttrib_Color];
            [self._program addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
            
            CHECK_GL_ERROR_DEBUG();
            
            NSAssert([self._program link], @"");
            [self._program updateUniforms];
            
            [[CCShaderCache sharedShaderCache] addProgram:self._program forKey:key];
        }
        
        self.threshold = 0.91;
        self.compression = 0.0;
        
        self.radius = radius;
        self.scaleFactor = scaleFactor;
        
        self._thresholdUniform = [self._program uniformLocationForName:@"u_threshold"];
        
        if (!s_primaryBody) {
            self._isPrimary = YES;
            s_primaryBody = self;
            
            self._forces = malloc(sizeof(CGPoint) * numNodes);
            CCPhysicsBody *originBody = nil;
            NSMutableArray *joints = [[NSMutableArray alloc] initWithCapacity:numNodes];
            NSMutableArray *jointDistances = [[NSMutableArray alloc] initWithCapacity:numNodes];
            
            for (NSInteger i = 0; i < numNodes; ++i) {
                GravitationalBodyNode *node = [[GravitationalBodyNode alloc] init];
                
                if (i > 0) {
                    node.position = ccpMult(CCRANDOM_IN_UNIT_CIRCLE(), radius);
                    node.radius = radius / 8.0 + CCRANDOM_0_1() * radius / 2.0;
                    node.color = [CCColor whiteColor];
                } else {
                    node.position = ccp(0, 0);
                    node.radius = radius * 2500;
                    node.visible = NO;
                }
                
                node.physicsBody = [CCPhysicsBody bodyWithCircleOfRadius:node.radius andCenter:node.position];
                node.physicsBody.collisionGroup = [self class];
                node.physicsBody.mass = node.radius;
                node.physicsBody.affectedByGravity = NO;
                
                if (i > 0) {
                    CGFloat maxDist = radius / 10 + CCRANDOM_0_1() * (radius + CCRANDOM_MINUS1_1() * (radius / 10.0));
//                    maxDist = (radius + CCRANDOM_MINUS1_1() * (radius / 10.0));
                    CCPhysicsJoint *joint = [CCPhysicsJoint connectedDistanceJointWithBodyA:originBody bodyB:node.physicsBody anchorA:CGPointZero anchorB:CGPointZero minDistance:0 maxDistance:maxDist];
                    [joints addObject:joint];
                    [jointDistances addObject:[NSNumber numberWithFloat:maxDist]];
                } else {
                    originBody = node.physicsBody;
                    
                    node.physicsBody.type = CCPhysicsBodyTypeStatic;
                }
                
                [self addChild:node];
            }
            
            self._joints = joints;
            self._originalJointDistances = jointDistances;
            self._hasForces = NO;
            
            memset(self._forces, 0, sizeof(CGPoint) * self.numNodes);
        } else {
            self._isPrimary = NO;
        }
        
        CGFloat size = radius * 5 * self.scaleFactor;
        self._renderTexture = [[CCRenderTexture alloc] initWithWidth:size height:size pixelFormat:CCTexturePixelFormat_Default];
        [self addChild:self._renderTexture];
    }
    
    return self;
}

- (void)update:(CCTime)delta
{
    if (!self._isPrimary) {
        return;
    }
    
    const CGPoint minForce = ccp(-kGravitationalBodyMaxForce, -kGravitationalBodyMaxForce);
    const CGPoint maxForce = ccp(kGravitationalBodyMaxForce, kGravitationalBodyMaxForce);
    
    const CGPoint minVelocity = ccp(-kGravitationalBodyMaxVelocity, -kGravitationalBodyMaxVelocity);
    const CGPoint maxVelocity = ccp(kGravitationalBodyMaxVelocity, kGravitationalBodyMaxVelocity);
    
    { // calculate n-body forces
        memset(self._forces, 0, sizeof(CGPoint) * self.numNodes);
        const CGFloat forceMultiplier = 32.0;
        
        for (NSInteger i = 0; i < self.numNodes; ++i) {
            GravitationalBodyNode *node1 = self.children[i];
            CGPoint force = self._forces[i];
            
            for (NSInteger j = i + 1; j < self.numNodes; ++j) {
                GravitationalBodyNode *node2 = self.children[j];
                
                cpVect delta = cpvsub(node1.position, node2.position);
                cpFloat sqdist = cpvlengthsq(delta);
                
                if (sqdist > 0.1) {
                    cpFloat invsqdist = 1.0 / sqdist;
                    
                    force = cpvadd(force, cpvmult(delta, -node2.radius * node2.radius * forceMultiplier * invsqdist));
                    
                    self._forces[j] = cpvadd(self._forces[j], cpvmult(delta, node1.radius * forceMultiplier * invsqdist));
                }
            }
            
            self._forces[i] = force;
        }
        
        for (NSInteger i = 0; i < self.numNodes; ++i) {
            self._forces[i] = ccpClamp(self._forces[i], minForce, maxForce);
        }
    }
    
    { // apply forces to bodies
        for (NSInteger i = 1; i < self.numNodes; ++i) {
            GravitationalBodyNode *node = self.children[i];
            
            [node.physicsBody applyForce:self._forces[i]];
            
            node.physicsBody.force = ccpClamp(node.physicsBody.force, minForce, maxForce);
            node.physicsBody.velocity = ccpClamp(node.physicsBody.velocity, minVelocity, maxVelocity);
            
//            CCPhysicsJoint *joint = self._joints[i - 1];
//            if (!joint.valid) {
//                [joint invalidate];
//                self._joints[i - 1] = [CCPhysicsJoint connectedDistanceJointWithBodyA:((CCNode*)self.children[0]).physicsBody bodyB:node.physicsBody anchorA:CGPointZero anchorB:CGPointZero minDistance:0 maxDistance:[self._originalJointDistances[i - 1] floatValue]];
//            }
        }
    }
}

- (void)visit
{
    { // draw nodes to offscreen texture
        [self._renderTexture beginWithClear:self.color.red g:self.color.green b:self.color.blue a:0];
        
        kmGLPushMatrix();
        kmGLScalef(self.scaleFactor, self.scaleFactor, 1.0);
        kmGLTranslatef(self._renderTexture.boundingBox.size.width / (2 * self.scaleFactor), self._renderTexture.boundingBox.size.height / (2 * self.scaleFactor), 0);
        
        for (NSInteger i = 0; i < self.numNodes; ++i) {
            GravitationalBodyNode *node = (self._isPrimary ? self.children[i] : s_primaryBody.children[i]);
            
            [node visit];
        }
        
        kmGLPopMatrix();
        [self._renderTexture end];
    }
    
    { // draw offscreen texture
        [self draw];
    }
}

- (void)draw
{
    kmGLPushMatrix();
    
    [self transform];
    
//    kmGLScalef(1.0 / self._scaleFactor, 1.0 / self._scaleFactor, 1.0);
    kmGLTranslatef(-self._renderTexture.boundingBox.size.width / 2, -self._renderTexture.boundingBox.size.height / 2, 0);
    
    [self._program use];
    [self._program setUniformsForBuiltins];
    [self._program setUniformLocation:self._thresholdUniform withF1:self.threshold];
    
    [self._renderTexture.sprite draw2];
    
    kmGLPopMatrix();
}

- (void)setCompression:(CGFloat)compression
{
    self->_compression = compression;
    
    if (!self._isPrimary) {
        return;
    }
    
    for (int i = 0; i < self.numNodes - 1; ++i) {
        CCPhysicsJoint *joint = self._joints[i];
        ChipmunkSlideJoint *j = (ChipmunkSlideJoint*)[joint performSelector:@selector(constraint)];
        CGFloat maxDist = [self._originalJointDistances[i] floatValue];
        
        j.max = (self.radius / 5.0) * compression + maxDist * (1.0 - compression);
    }
}

@end
