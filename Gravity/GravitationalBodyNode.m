//
//  GravitationalBodyNode.m
//  Gravity
//
//  Created by Travis Fischer on 3/17/14.
//  Copyright 2014 Transitive Bullshit. All rights reserved.
//

#import <math.h>
#import <stdlib.h>

#import "GravitationalBodyNode.h"
#import <chipmunk/chipmunk.h>
#import "CCDrawingPrimitives.h"

@interface GravitationalBodyNode ()

@property (nonatomic, strong) CCGLProgram *_program;
@property (nonatomic) int _colorLocation;
@property (nonatomic) int _pointSizeLocation;

@end

static GLfloat *s_vertices;
static GLfloat *s_texCoords;
static const NSUInteger NUM_CIRCLE_SEGMENTS = 16;

@implementation GravitationalBodyNode

- (id)init
{
    if (self = [super init]) {
        NSString *key = [[self class] description];
        self._program = [[CCShaderCache sharedShaderCache] programForKey:key];
        
        if (!self._program) {
            NSString *vs = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GravitationalBodyNode" ofType:@"vs"] encoding:NSUTF8StringEncoding error:nil];
            const GLchar *vert = (GLchar*)[vs UTF8String];
            
            NSString *fs = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"GravitationalBodyNode" ofType:@"fs"] encoding:NSUTF8StringEncoding error:nil];
            const GLchar *frag = (GLchar*)[fs UTF8String];
            
            self._program = [[CCGLProgram alloc] initWithVertexShaderByteArray:vert fragmentShaderByteArray:frag];
            //        self._program = [[CCShaderCache sharedShaderCache] programForKey:kCCShader_PositionTexture];
            
            CHECK_GL_ERROR_DEBUG();
            
            [self._program addAttribute:kCCAttributeNamePosition index:kCCVertexAttrib_Position];
            [self._program addAttribute:kCCAttributeNameTexCoord index:kCCVertexAttrib_TexCoords];
            
            NSAssert([self._program link], @"");
            [self._program updateUniforms];
            
            CHECK_GL_ERROR_DEBUG();
            [[CCShaderCache sharedShaderCache] addProgram:self._program forKey:key];
        }
        
        if (!s_vertices) {
            NSUInteger segs = NUM_CIRCLE_SEGMENTS;
            CGPoint center = CGPointZero;
            
            s_vertices  = calloc(sizeof(GLfloat) * 2 * (segs + 2), 1);
            s_texCoords = calloc(sizeof(GLfloat) * 2 * (segs + 2), 1);
            
            const float coef = 2.0f * (float)M_PI / segs;
            
            for(NSUInteger i = 0; i <= segs; ++i) {
                CGFloat rads = i * coef;
                
                GLfloat j = cosf(rads) + center.x;
                GLfloat k = sinf(rads) + center.y;
                
                s_vertices[i*2] = j;
                s_vertices[i*2+1] = k;
                
                s_texCoords[i*2] = cosf(rads);
                s_texCoords[i*2+1] = sinf(rads);
            }
            
            s_vertices[(segs+1)*2]    = center.x;
            s_vertices[(segs+1)*2+1]  = center.y;
            s_texCoords[(segs+1)*2]   = 0.5;
            s_texCoords[(segs+1)*2+1] = 0.5;
        }
    }
    
    return self;
}

- (void) draw
{
    if (self.debug) {
        [self debugDraw];
        return;
    }
    
    [self transform];
    kmGLScalef(self.radius, self.radius, 1.0);
    
	[self._program use];
	[self._program setUniformsForBuiltins];
    
	ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position | kCCVertexAttribFlag_TexCoords);
    
	glVertexAttribPointer(kCCVertexAttrib_Position,  2, GL_FLOAT, GL_FALSE, 0, s_vertices);
	glVertexAttribPointer(kCCVertexAttrib_TexCoords, 2, GL_FLOAT, GL_FALSE, 0, s_texCoords);
    
    glBlendFunc(GL_ONE, GL_ONE);
    
	glDrawArrays(GL_TRIANGLE_FAN, 0, NUM_CIRCLE_SEGMENTS + 1);
	
	CC_INCREMENT_GL_DRAWS(1);
}

- (void)debugDraw
{
    [self transform];
    
    ccDrawColor4F(self.color.red, self.color.green, self.color.blue, 0.3);
    ccDrawSolidCircle(CGPointZero, self.radius, 32);
}

@end
