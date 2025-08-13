//
//  EngWrapper.h
//  libhangul English Input Wrapper
//
//  Created for libhangul project
//  Objective-C wrapper for libhangul English input library
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class EngInputContext;

// Constants
typedef NS_ENUM(NSInteger, EngKeyboardType) {
    EngKeyboardTypeHalfQwertyWide = 0,
    EngKeyboardTypeHalfQwertyLeft = 1,
    EngKeyboardTypeHalfQwertyRight = 2
};

// English Input Context
@interface EngInputContext : NSObject
- (instancetype)initWithKeyboardType:(EngKeyboardType)type;

// Input processing
- (BOOL)processKey:(int)ascii;
- (BOOL)processKeyDown:(int)ascii;
- (BOOL)processKeyUp:(int)ascii;

// Space key handling
- (BOOL)isSpaceDown;
- (BOOL)isSpaceUsed;
- (void)resetSpaceState;

// Timeout settings
- (void)setSpaceTimeout:(int)timeoutMs;

// Output
- (NSString *)preeditString;
- (NSString *)commitString;
- (NSString *)flush;

@end

NS_ASSUME_NONNULL_END