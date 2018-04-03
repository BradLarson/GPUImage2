//
//  NSObject+Exception.m
//  GPUImage2
//
//  Created by Josh Bernfeld on 11/23/17.
//
//  Source: https://stackoverflow.com/a/36454808/1275014

#import "NSObject+Exception.h"

@implementation NSObject (Exception)

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error {
    @try {
        tryBlock();
        return YES;
    }
    @catch (NSException *exception) {
        *error = [[NSError alloc] initWithDomain:exception.name code:0 userInfo:exception.userInfo];
        return NO;
    }
}

@end
