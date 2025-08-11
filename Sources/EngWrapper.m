//
//  EngWrapper.m
//  libhangul English Input Wrapper
//
//  Created for libhangul project
//  Objective-C wrapper for libhangul English input library
//

#import "EngWrapper.h"

// C 라이브러리 타입들을 다른 이름으로 정의하여 충돌 방지
#define EngInputContext CEngInputContext
#define EngKeyboardType CEngKeyboardType
#define EngTypingStats CEngTypingStats

#include "enginputcontext.h"

#undef EngInputContext
#undef EngKeyboardType
#undef EngTypingStats

// EngTypingStats implementation
@implementation EngTypingStats
@end

@interface EngInputContext() {
    CEngInputContext* _context;
}
@end

@implementation EngInputContext

- (instancetype)initWithKeyboardType:(EngKeyboardType)type {
    self = [super init];
    if (self) {
        CEngKeyboardType cType;
        switch (type) {
            case EngKeyboardTypeHalfStandard:
                cType = ENG_KEYBOARD_TYPE_HALF_STANDARD;
                break;
            case EngKeyboardTypeHalfQwertyLeft:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT;
                break;
            case EngKeyboardTypeHalfQwertyRight:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_RIGHT;
                break;
            default:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT; // 왼손을 기본으로 설정
                break;
        }
        _context = eng_ic_new(cType);
    }
    return self;
}

// Convenience initializers
+ (instancetype)newHalfQwertyLeft {
    return [[self alloc] initWithKeyboardType:EngKeyboardTypeHalfQwertyLeft];
}

+ (instancetype)newHalfQwertyRight {
    return [[self alloc] initWithKeyboardType:EngKeyboardTypeHalfQwertyRight];
}

- (void)dealloc {
    if (_context) {
        eng_ic_delete(_context);
    }
    [super dealloc];
}

// Input processing
- (BOOL)processKey:(int)ascii {
    if (!_context) return NO;
    return eng_ic_process(_context, ascii);
}

- (BOOL)processKeyDown:(int)ascii {
    if (!_context) return NO;
    return eng_ic_process_key_down(_context, ascii);
}

- (BOOL)processKeyUp:(int)ascii {
    if (!_context) return NO;
    return eng_ic_process_key_up(_context, ascii);
}

- (void)reset {
    if (_context) {
        eng_ic_reset(_context);
    }
}

// Space key handling
- (void)setSpaceDown:(BOOL)down {
    if (_context) {
        eng_ic_set_space_down(_context, down);
    }
}

- (BOOL)isSpaceDown {
    if (!_context) return NO;
    return eng_ic_is_space_down(_context);
}

// State queries
- (BOOL)isEmpty {
    if (!_context) return YES;
    return eng_ic_is_empty(_context);
}

// Settings
- (void)setKeyboardType:(EngKeyboardType)type {
    if (!_context) return;
    
    CEngKeyboardType cType;
    switch (type) {
        case EngKeyboardTypeHalfStandard:
            cType = ENG_KEYBOARD_TYPE_HALF_STANDARD;
            break;
        case EngKeyboardTypeHalfQwertyLeft:
            cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT;
            break;
        case EngKeyboardTypeHalfQwertyRight:
            cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_RIGHT;
            break;
        default:
            cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT;
            break;
    }
    eng_ic_set_keyboard_type(_context, cType);
}

- (EngKeyboardType)keyboardType {
    if (!_context) return EngKeyboardTypeHalfQwertyLeft;
    
    CEngKeyboardType cType = eng_ic_get_keyboard_type(_context);
    switch (cType) {
        case ENG_KEYBOARD_TYPE_HALF_STANDARD:
            return EngKeyboardTypeHalfStandard;
        case ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT:
            return EngKeyboardTypeHalfQwertyLeft;
        case ENG_KEYBOARD_TYPE_HALF_QWERTY_RIGHT:
            return EngKeyboardTypeHalfQwertyRight;
        default:
            return EngKeyboardTypeHalfQwertyLeft;
    }
}

// Timeout settings
- (void)setSpaceTimeout:(int)timeoutMs {
    if (_context) {
        eng_ic_set_space_timeout(_context, timeoutMs);
    }
}

- (int)spaceTimeout {
    if (!_context) return 0;
    return eng_ic_get_space_timeout(_context);
}

// Sticky Keys support
- (void)setStickyKeys:(BOOL)enabled {
    if (_context) {
        eng_ic_set_sticky_keys(_context, enabled);
    }
}

- (BOOL)stickyKeys {
    if (!_context) return NO;
    return eng_ic_get_sticky_keys(_context);
}

- (void)setShiftSticky:(BOOL)sticky {
    if (_context) {
        eng_ic_set_shift_sticky(_context, sticky);
    }
}

- (void)setCtrlSticky:(BOOL)sticky {
    if (_context) {
        eng_ic_set_ctrl_sticky(_context, sticky);
    }
}

- (void)setAltSticky:(BOOL)sticky {
    if (_context) {
        eng_ic_set_alt_sticky(_context, sticky);
    }
}

// Typing statistics
- (void)startTypingTest {
    if (_context) {
        eng_ic_start_typing_test(_context);
    }
}

- (void)endTypingTest {
    if (_context) {
        eng_ic_end_typing_test(_context);
    }
}

- (EngTypingStats *)typingStats {
    if (!_context) return nil;
    
    CEngTypingStats cStats = eng_ic_get_typing_stats(_context);
    EngTypingStats *stats = [[EngTypingStats alloc] init];
    stats.totalChars = cStats.total_chars;
    stats.mirrorChars = cStats.mirror_chars;
    stats.errors = cStats.errors;
    stats.startTimeMs = cStats.start_time_ms;
    stats.endTimeMs = cStats.end_time_ms;
    stats.wpm = cStats.wpm;
    stats.accuracy = cStats.accuracy;
    return [stats autorelease];
}

- (void)resetTypingStats {
    if (_context) {
        eng_ic_reset_typing_stats(_context);
    }
}

// Output
- (NSString *)preeditString {
    if (!_context) return @"";
    
    const char* preedit = eng_ic_get_preedit_string(_context);
    if (preedit) {
        return [NSString stringWithUTF8String:preedit];
    }
    return @"";
}

- (NSString *)commitString {
    if (!_context) return @"";
    
    const char* commit = eng_ic_get_commit_string(_context);
    if (commit) {
        return [NSString stringWithUTF8String:commit];
    }
    return @"";
}

- (NSString *)flush {
    if (!_context) return @"";
    
    // 영어 입력에서는 flush가 별도로 필요없음
    const char* commit = eng_ic_get_commit_string(_context);
    if (commit) {
        NSString *result = [NSString stringWithUTF8String:commit];
        eng_ic_reset(_context);
        return result;
    }
    return @"";
}

@end