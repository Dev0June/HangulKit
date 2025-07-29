//
//  HangulWrapper.h
//  libhangul Objective-C Wrapper
//
//  Created for libhangul project
//  Objective-C wrapper for libhangul Korean input library
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class HangulInputContext;
@class HangulKeyboard;

// Constants
typedef NS_ENUM(NSInteger, HangulOutputMode) {
    HangulOutputSyllable = 0,
    HangulOutputJamo = 1
};

typedef NS_ENUM(NSInteger, HangulKeyboardType) {
    HangulKeyboardTypeJamo = 0,
    HangulKeyboardTypeJaso = 1,
    HangulKeyboardTypeRomaja = 2,
    HangulKeyboardTypeJamoYet = 3,
    HangulKeyboardTypeJasoYet = 4
};

typedef NS_ENUM(NSInteger, HangulInputContextOption) {
    HangulInputContextOptionAutoReorder = 0,
    HangulInputContextOptionCombiOnDoubleStroke = 1,
    HangulInputContextOptionNonChoseongCombi = 2
};

// Hangul Character Type Functions
@interface HangulCharType : NSObject

+ (BOOL)isChoseong:(uint32_t)character;
+ (BOOL)isJungseong:(uint32_t)character;
+ (BOOL)isJongseong:(uint32_t)character;
+ (BOOL)isSyllable:(uint32_t)character;
+ (BOOL)isJamo:(uint32_t)character;
+ (BOOL)isCJamo:(uint32_t)character;

+ (uint32_t)jamoToSyllableWithChoseong:(uint32_t)choseong 
                             jungseong:(uint32_t)jungseong 
                             jongseong:(uint32_t)jongseong;

+ (void)syllableToJamo:(uint32_t)syllable 
             choseong:(uint32_t *)choseong 
            jungseong:(uint32_t *)jungseong 
            jongseong:(uint32_t *)jongseong;

@end

// Hangul Keyboard
@interface HangulKeyboard : NSObject

- (instancetype)init;
- (instancetype)initWithFile:(NSString *)filePath;
- (void)setType:(HangulKeyboardType)type;

// Static methods for keyboard management
+ (NSUInteger)keyboardCount;
+ (nullable NSString *)keyboardIdAtIndex:(NSUInteger)index;
+ (nullable NSString *)keyboardNameAtIndex:(NSUInteger)index;
+ (nullable HangulKeyboard *)keyboardWithId:(NSString *)keyboardId;

@end

// Hangul Input Context
@interface HangulInputContext : NSObject

- (instancetype)initWithKeyboard:(NSString *)keyboardId;

// Input processing
- (BOOL)processKey:(int)ascii;
- (void)reset;
- (BOOL)backspace;

// State queries
- (BOOL)isEmpty;
- (BOOL)hasChoseong;
- (BOOL)hasJungseong;
- (BOOL)hasJongseong;
- (BOOL)isTransliteration;

// Options
- (BOOL)getOption:(HangulInputContextOption)option;
- (void)setOption:(HangulInputContextOption)option value:(BOOL)value;
- (void)setOutputMode:(HangulOutputMode)mode;
- (void)setKeyboard:(HangulKeyboard *)keyboard;
- (void)selectKeyboard:(NSString *)keyboardId;

// Output
- (NSString *)preeditString;
- (NSString *)commitString;
- (NSString *)flush;

@end

// Hanja Support
@interface Hanja : NSObject

@property (nonatomic, readonly) NSString *key;
@property (nonatomic, readonly) NSString *value;
@property (nonatomic, readonly) NSString *comment;

@end

@interface HanjaList : NSObject

@property (nonatomic, readonly) NSInteger size;
@property (nonatomic, readonly) NSString *key;

- (nullable Hanja *)hanjaAtIndex:(NSUInteger)index;
- (nullable NSString *)keyAtIndex:(NSUInteger)index;
- (nullable NSString *)valueAtIndex:(NSUInteger)index;
- (nullable NSString *)commentAtIndex:(NSUInteger)index;

@end

@interface HanjaTable : NSObject

- (instancetype)initWithFile:(NSString *)filePath;
- (nullable HanjaList *)matchExact:(NSString *)key;
- (nullable HanjaList *)matchPrefix:(NSString *)key;
- (nullable HanjaList *)matchSuffix:(NSString *)key;

@end

NS_ASSUME_NONNULL_END