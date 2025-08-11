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
    EngKeyboardTypeHalfStandard = 0,
    EngKeyboardTypeHalfQwertyLeft = 1,
    EngKeyboardTypeHalfQwertyRight = 2
};

// Typing statistics
@interface EngTypingStats : NSObject
@property (nonatomic, assign) int totalChars;
@property (nonatomic, assign) int mirrorChars;
@property (nonatomic, assign) int errors;
@property (nonatomic, assign) long startTimeMs;
@property (nonatomic, assign) long endTimeMs;
@property (nonatomic, assign) double wpm;
@property (nonatomic, assign) double accuracy;
@end

// English Input Context
@interface EngInputContext : NSObject

- (instancetype)initWithKeyboardType:(EngKeyboardType)type;

// Convenience initializers
+ (instancetype)newHalfQwertyLeft;
+ (instancetype)newHalfQwertyRight;

// Input processing
- (BOOL)processKey:(int)ascii;
- (BOOL)processKeyDown:(int)ascii;
- (BOOL)processKeyUp:(int)ascii;
- (void)reset;

// Space key handling
- (void)setSpaceDown:(BOOL)down;
- (BOOL)isSpaceDown;

// State queries
- (BOOL)isEmpty;

// Settings
- (void)setKeyboardType:(EngKeyboardType)type;
- (EngKeyboardType)keyboardType;

// Timeout settings
- (void)setSpaceTimeout:(int)timeoutMs;
- (int)spaceTimeout;

// Sticky Keys support
- (void)setStickyKeys:(BOOL)enabled;
- (BOOL)stickyKeys;
- (void)setShiftSticky:(BOOL)sticky;
- (void)setCtrlSticky:(BOOL)sticky;
- (void)setAltSticky:(BOOL)sticky;

// Typing statistics
- (void)startTypingTest;
- (void)endTypingTest;
- (EngTypingStats *)typingStats;
- (void)resetTypingStats;

// Output
- (NSString *)preeditString;
- (NSString *)commitString;
- (NSString *)flush;

@end

NS_ASSUME_NONNULL_END