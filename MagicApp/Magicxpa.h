//
//  uniPaaS.h
//  uniPaaS
//
//  Created by iMac on 3/21/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Magicxpa : NSObject

+ (void) start:(UIWindow*) window WrapperDelegate:(id)wrapperDelegate;

+(UIView *) getControlByName:(NSString *) controlName TaskGeneration:(int)generation;

+ (void)invokeExternalEvent:(NSString *)str;

+ (void)invokeUserEvent:(NSString *)name Params:(NSArray *)params;

@end
