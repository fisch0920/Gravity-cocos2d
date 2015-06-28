//
//  GravitationalBodyCache.m
//  Gravity
//
//  Created by Travis Fischer on 3/28/14.
//  Copyright (c) 2014 Transitive Bullshit. All rights reserved.
//

#import "GravitationalBodyCache.h"
#import "GravitationalBody.h"

@interface GravitationalBodyCache ()

@property (nonatomic, strong) NSCache *_bodyCache;

@end

@implementation GravitationalBodyCache

+ (GravitationalBodyCache*)sharedCache
{
    static GravitationalBodyCache *s_cache;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^{
        s_cache = [GravitationalBodyCache new];
    });
    
    return s_cache;
}

- (id)init
{
    if (self = [super init]) {
        self._bodyCache = [[NSCache alloc] init];
        self._bodyCache.countLimit = 8;
    }
    
    return self;
}

- (GravitationalBody*)getBody:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor
{
    NSString *key = [self cacheKey:numNodes andRadius:radius andScaleFactor:scaleFactor];
    GravitationalBody *body = [self._bodyCache objectForKey:key];
    
    if (body) {
        return body;
    } else {
        body = [[GravitationalBody alloc] initWithNumNodes:numNodes andRadius:radius andScaleFactor:scaleFactor];
        
        [self._bodyCache setObject:body forKey:key];
        
        return body;
    }
}

//- (void)removeBody:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor
//{
//    NSString *key = [self cacheKey:numNodes andRadius:radius andScaleFactor:scaleFactor];
//    
//    [self._bodyCache removeObjectForKey:key];
//}

- (NSString*)cacheKey:(NSInteger)numNodes andRadius:(CGFloat)radius andScaleFactor:(CGFloat)scaleFactor
{
    return [NSString stringWithFormat:@"%ld,%.2f,%.2f", (long)numNodes, radius, scaleFactor];
}

@end
