//
//  HangulWrapper.m
//  libhangul Objective-C Wrapper
//
//  Created for libhangul project
//  Objective-C wrapper implementation for libhangul Korean input library
//

#import "HangulWrapper.h"

// C 라이브러리 타입들을 다른 이름으로 정의하여 충돌 방지
#define HangulKeyboard CHangulKeyboard
#define HangulInputContext CHangulInputContext

#include "hangul.h"

// 원래 이름으로 복원
#undef HangulKeyboard
#undef HangulInputContext

// C 타입들에 대한 별칭 정의
typedef struct _HangulKeyboard        CHangulKeyboard;
typedef struct _HangulInputContext    CHangulInputContext;

// Utility function to convert C string to NSString safely
static NSString* SafeStringFromCString(const char* cString) {
    return cString ? [NSString stringWithUTF8String:cString] : @"";
}

// Utility function to convert ucschar array to NSString
static NSString* StringFromUCSCharArray(const ucschar* ucsString) {
    if (!ucsString) return @"";
    
    NSMutableString *result = [NSMutableString string];
    int i = 0;
    while (ucsString[i] != 0) {
        // Convert Unicode code point to NSString
        NSString *character = [[NSString alloc] initWithBytes:&ucsString[i] 
                                                       length:sizeof(ucschar) 
                                                     encoding:NSUTF32LittleEndianStringEncoding];
        if (character) {
            [result appendString:character];
        }
        i++;
    }
    return [result copy];
}

#pragma mark - HangulCharType Implementation

@implementation HangulCharType

+ (BOOL)isChoseong:(uint32_t)character {
    return hangul_is_choseong(character);
}

+ (BOOL)isJungseong:(uint32_t)character {
    return hangul_is_jungseong(character);
}

+ (BOOL)isJongseong:(uint32_t)character {
    return hangul_is_jongseong(character);
}

+ (BOOL)isSyllable:(uint32_t)character {
    return hangul_is_syllable(character);
}

+ (BOOL)isJamo:(uint32_t)character {
    return hangul_is_jamo(character);
}

+ (BOOL)isCJamo:(uint32_t)character {
    return hangul_is_cjamo(character);
}

+ (uint32_t)jamoToSyllableWithChoseong:(uint32_t)choseong 
                             jungseong:(uint32_t)jungseong 
                             jongseong:(uint32_t)jongseong {
    return hangul_jamo_to_syllable(choseong, jungseong, jongseong);
}

+ (void)syllableToJamo:(uint32_t)syllable 
             choseong:(uint32_t *)choseong 
            jungseong:(uint32_t *)jungseong 
            jongseong:(uint32_t *)jongseong {
    hangul_syllable_to_jamo(syllable, choseong, jungseong, jongseong);
}

@end

#pragma mark - HangulKeyboard Implementation

@implementation HangulKeyboard {
    CHangulKeyboard* _keyboard;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _keyboard = hangul_keyboard_new();
        if (!_keyboard) {
            return nil;
        }
    }
    return self;
}

- (instancetype)initWithFile:(NSString *)filePath {
    // 파일에서 키보드를 로드하는 기능은 현재 지원하지 않음
    return [self init];
}

- (void)dealloc {
    if (_keyboard) {
        hangul_keyboard_delete(_keyboard);
    }
}

- (void)setType:(HangulKeyboardType)type {
    if (_keyboard) {
        hangul_keyboard_set_type(_keyboard, (int)type);
    }
}

- (CHangulKeyboard*)hangulKeyboard {
    return _keyboard;
}

#pragma mark - Static Methods

+ (NSUInteger)keyboardCount {
    return hangul_keyboard_list_get_count();
}

+ (nullable NSString *)keyboardIdAtIndex:(NSUInteger)index {
    const char* keyboardId = hangul_keyboard_list_get_keyboard_id((unsigned int)index);
    return SafeStringFromCString(keyboardId);
}

+ (nullable NSString *)keyboardNameAtIndex:(NSUInteger)index {
    const char* keyboardName = hangul_keyboard_list_get_keyboard_name((unsigned int)index);
    return SafeStringFromCString(keyboardName);
}

+ (nullable HangulKeyboard *)keyboardWithId:(NSString *)keyboardId {
    const char* cKeyboardId = [keyboardId UTF8String];
    const CHangulKeyboard* cKeyboard = hangul_keyboard_list_get_keyboard(cKeyboardId);
    
    if (!cKeyboard) return nil;
    
    // Create a wrapper instance
    HangulKeyboard* wrapper = [[HangulKeyboard alloc] init];
    if (wrapper) {
        // Replace the internal keyboard with the one from the list
        if (wrapper->_keyboard) {
            hangul_keyboard_delete(wrapper->_keyboard);
        }
        // Note: This is not a deep copy, but libhangul manages the lifetime
        wrapper->_keyboard = (CHangulKeyboard*)cKeyboard;
    }
    return wrapper;
}

@end

#pragma mark - HangulInputContext Implementation

@implementation HangulInputContext {
    CHangulInputContext* _inputContext;
}

- (instancetype)initWithKeyboard:(NSString *)keyboardId {
    self = [super init];
    if (self) {
        const char* cKeyboardId = [keyboardId UTF8String];
        _inputContext = hangul_ic_new(cKeyboardId);
        if (!_inputContext) {
            return nil;
        }
    }
    return self;
}

- (void)dealloc {
    if (_inputContext) {
        hangul_ic_delete(_inputContext);
    }
}

#pragma mark - Input Processing

- (BOOL)processKey:(int)ascii {
    if (!_inputContext) return NO;
    return hangul_ic_process(_inputContext, ascii);
}

- (void)reset {
    if (_inputContext) {
        hangul_ic_reset(_inputContext);
    }
}

- (BOOL)backspace {
    if (!_inputContext) return NO;
    return hangul_ic_backspace(_inputContext);
}

#pragma mark - State Queries

- (BOOL)isEmpty {
    if (!_inputContext) return YES;
    return hangul_ic_is_empty(_inputContext);
}

- (BOOL)hasChoseong {
    if (!_inputContext) return NO;
    return hangul_ic_has_choseong(_inputContext);
}

- (BOOL)hasJungseong {
    if (!_inputContext) return NO;
    return hangul_ic_has_jungseong(_inputContext);
}

- (BOOL)hasJongseong {
    if (!_inputContext) return NO;
    return hangul_ic_has_jongseong(_inputContext);
}

- (BOOL)isTransliteration {
    if (!_inputContext) return NO;
    return hangul_ic_is_transliteration(_inputContext);
}

#pragma mark - Options

- (BOOL)getOption:(HangulInputContextOption)option {
    if (!_inputContext) return NO;
    return hangul_ic_get_option(_inputContext, (int)option);
}

- (void)setOption:(HangulInputContextOption)option value:(BOOL)value {
    if (_inputContext) {
        hangul_ic_set_option(_inputContext, (int)option, value);
    }
}

- (void)setOutputMode:(HangulOutputMode)mode {
    if (_inputContext) {
        hangul_ic_set_output_mode(_inputContext, (int)mode);
    }
}

- (void)setKeyboard:(HangulKeyboard *)keyboard {
    if (_inputContext && keyboard) {
        hangul_ic_set_keyboard(_inputContext, [keyboard hangulKeyboard]);
    }
}

- (void)selectKeyboard:(NSString *)keyboardId {
    if (_inputContext) {
        const char* cKeyboardId = [keyboardId UTF8String];
        hangul_ic_select_keyboard(_inputContext, cKeyboardId);
    }
}

#pragma mark - Output

- (NSString *)preeditString {
    if (!_inputContext) return @"";
    const ucschar* preedit = hangul_ic_get_preedit_string(_inputContext);
    return StringFromUCSCharArray(preedit);
}

- (NSString *)commitString {
    if (!_inputContext) return @"";
    const ucschar* commit = hangul_ic_get_commit_string(_inputContext);
    return StringFromUCSCharArray(commit);
}

- (NSString *)flush {
    if (!_inputContext) return @"";
    const ucschar* flush = hangul_ic_flush(_inputContext);
    return StringFromUCSCharArray(flush);
}

@end

