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

#include "enginputcontext.h"

#undef EngInputContext
#undef EngKeyboardType

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
            case EngKeyboardTypeHalfQwertyWide:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_WIDE;
                break;
            case EngKeyboardTypeHalfQwertyLeft:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_LEFT;
                break;
            case EngKeyboardTypeHalfQwertyRight:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_RIGHT;
                break;
            default:
                cType = ENG_KEYBOARD_TYPE_HALF_QWERTY_WIDE; // QWERTY WIDE를 기본으로 설정
                break;
        }
        _context = eng_ic_new(cType);
    }
    return self;
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

// Space key handling
- (BOOL)isSpaceDown {
    if (!_context) return NO;
    return eng_ic_is_space_down(_context);
}

- (BOOL)isSpaceUsed {
    if (!_context) return NO;
    return eng_ic_is_space_used(_context);
}

- (void)resetSpaceState {
    if (!_context) return;
    eng_ic_reset_space_state(_context);
}

// Timeout settings
- (void)setSpaceTimeout:(int)timeoutMs {
    if (_context) {
        eng_ic_set_space_timeout(_context, timeoutMs);
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
        // Space 상태만 리셋 (영어 입력에서는 전체 리셋이 불필요)
        eng_ic_reset_space_state(_context);
        return result;
    }
    return @"";
}

@end