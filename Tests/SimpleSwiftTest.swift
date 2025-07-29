#!/usr/bin/env swift

//
//  SimpleSwiftTest.swift
//  Basic Swift test for libhangul
//

import Foundation

// Direct C bindings for libhangul
// Since we're keeping it simple, we'll use direct C calls

// C function declarations
@_silgen_name("hangul_keyboard_list_get_count")
func hangul_keyboard_list_get_count() -> UInt32

@_silgen_name("hangul_keyboard_list_get_keyboard_id")
func hangul_keyboard_list_get_keyboard_id(_ index: UInt32) -> UnsafePointer<CChar>?

@_silgen_name("hangul_keyboard_list_get_keyboard_name")
func hangul_keyboard_list_get_keyboard_name(_ index: UInt32) -> UnsafePointer<CChar>?

@_silgen_name("hangul_ic_new")
func hangul_ic_new(_ keyboard: UnsafePointer<CChar>) -> OpaquePointer?

@_silgen_name("hangul_ic_delete")
func hangul_ic_delete(_ hic: OpaquePointer)

@_silgen_name("hangul_ic_process")
func hangul_ic_process(_ hic: OpaquePointer, _ ascii: Int32) -> Bool

@_silgen_name("hangul_ic_reset")
func hangul_ic_reset(_ hic: OpaquePointer)

@_silgen_name("hangul_ic_flush")
func hangul_ic_flush(_ hic: OpaquePointer) -> UnsafePointer<UInt32>?

@_silgen_name("hangul_ic_get_preedit_string")
func hangul_ic_get_preedit_string(_ hic: OpaquePointer) -> UnsafePointer<UInt32>?

@_silgen_name("hangul_ic_get_commit_string")
func hangul_ic_get_commit_string(_ hic: OpaquePointer) -> UnsafePointer<UInt32>?

// Helper function to convert UCS string to Swift String
func ucsToString(_ ucsPtr: UnsafePointer<UInt32>?) -> String {
    guard let ptr = ucsPtr else { return "" }
    
    var result = ""
    var i = 0
    while ptr[i] != 0 {
        let codePoint = ptr[i]
        if let scalar = UnicodeScalar(codePoint) {
            result += String(Character(scalar))
        } else {
            // Debug: show the code point if it can't be converted
            result += "[U+\(String(codePoint, radix: 16, uppercase: true))]"
        }
        i += 1
    }
    return result
}

// Helper function to show both string and Unicode values
func debugString(_ str: String) -> String {
    var result = "'\(str)'"
    if !str.isEmpty {
        result += " ("
        for scalar in str.unicodeScalars {
            result += "U+\(String(scalar.value, radix: 16, uppercase: true)) "
        }
        result += ")"
    }
    return result
}

// Helper function to convert C string to Swift String
func cStringToSwift(_ cStr: UnsafePointer<CChar>?) -> String {
    guard let cStr = cStr else { return "" }
    return String(cString: cStr)
}

func testBasicFunctionality() {
    print("=== 기본 기능 테스트 ===")
    
    // 키보드 목록
    let keyboardCount = hangul_keyboard_list_get_count()
    print("사용 가능한 키보드: \(keyboardCount)개")
    
    for i in 0..<min(keyboardCount, 5) {
        let id = cStringToSwift(hangul_keyboard_list_get_keyboard_id(i))
        let name = cStringToSwift(hangul_keyboard_list_get_keyboard_name(i))
        print("  [\(i)] \(id): \(name)")
    }
    
    // 기본 입력 테스트 (dubeolsik)
    print("\n=== 기본 입력 테스트 (gks -> 한) ===")
    
    guard let hic = hangul_ic_new("2") else {
        print("입력 컨텍스트 생성 실패")
        return
    }
    
    // g, k, s 순서로 입력
    let keys: [Int32] = [103, 107, 115] // g, k, s
    let keyNames = ["g", "k", "s"]
    
    for (i, key) in keys.enumerated() {
        let processed = hangul_ic_process(hic, key)
        let preedit = ucsToString(hangul_ic_get_preedit_string(hic))
        let commit = ucsToString(hangul_ic_get_commit_string(hic))
        
        print("'\(keyNames[i])' 입력:")
        print("  처리됨: \(processed)")
        print("  preedit: '\(preedit)'")
        print("  commit: '\(commit)'")
    }
    
    let final = ucsToString(hangul_ic_flush(hic))
    print("최종 결과: '\(final)'")
    
    hangul_ic_delete(hic)
}

func testGalmadeuli() {
    print("\n=== 갈마들이 테스트 ===")
    
    // 오른손 키보드 테스트
    print("오른손 키보드 테스트:")
    if let hicRight = hangul_ic_new("1hand-right") {
        
        // rr -> 소
        hangul_ic_reset(hicRight)
        hangul_ic_process(hicRight, 114) // r
        hangul_ic_process(hicRight, 114) // r
        let result1 = ucsToString(hangul_ic_flush(hicRight))
        print("  rr -> \(debugString(result1)) \(result1 == "소" ? "✅" : "❌")")
        
        // ee -> 주
        hangul_ic_reset(hicRight)
        hangul_ic_process(hicRight, 101) // e
        hangul_ic_process(hicRight, 101) // e
        let result2 = ucsToString(hangul_ic_flush(hicRight))
        print("  ee -> \(debugString(result2)) \(result2 == "주" ? "✅" : "❌")")
        
        hangul_ic_delete(hicRight)
    } else {
        print("  오른손 키보드 생성 실패 ❌")
    }
    
    // 왼손 키보드 테스트
    print("\n왼손 키보드 테스트:")
    if let hicLeft = hangul_ic_new("1hand-left") {
        
        // uu -> 소
        hangul_ic_reset(hicLeft)
        hangul_ic_process(hicLeft, 117) // u
        hangul_ic_process(hicLeft, 117) // u
        let result1 = ucsToString(hangul_ic_flush(hicLeft))
        print("  uu -> \(debugString(result1)) \(result1 == "소" ? "✅" : "❌")")
        
        // ii -> 주
        hangul_ic_reset(hicLeft)
        hangul_ic_process(hicLeft, 105) // i
        hangul_ic_process(hicLeft, 105) // i
        let result2 = ucsToString(hangul_ic_flush(hicLeft))
        print("  ii -> \(debugString(result2)) \(result2 == "주" ? "✅" : "❌")")
        
        hangul_ic_delete(hicLeft)
    } else {
        print("  왼손 키보드 생성 실패 ❌")
    }
}

func testContinuousInput() {
    print("\n=== 연속 입력 테스트 ===")
    
    // 오른손 키보드로 "아름" (fgtjn) 테스트
    print("사용 가능한 키보드 ID 목록:")
    for i in 0..<hangul_keyboard_list_get_count() {
        let id = cStringToSwift(hangul_keyboard_list_get_keyboard_id(i))
        let name = cStringToSwift(hangul_keyboard_list_get_keyboard_name(i))
        print("  [\(i)] '\(id)': \(name)")
    }
    
    if let hicRight = hangul_ic_new("1hand-right") {
        print("오른손 키보드 생성 성공")
        hangul_ic_reset(hicRight)
        
        let sequence = "fgtjn"
        var result = ""
        
        print("오른손 키보드로 '\(sequence)' 입력:")
        
        for char in sequence {
            let ascii = Int32(char.asciiValue!)
            let processed = hangul_ic_process(hicRight, ascii)
            
            let commit = ucsToString(hangul_ic_get_commit_string(hicRight))
            let preedit = ucsToString(hangul_ic_get_preedit_string(hicRight))
            
            if !commit.isEmpty {
                result += commit
                print("  '\(char)' (ASCII:\(ascii)) -> processed:\(processed), commit: \(debugString(commit)), preedit: \(debugString(preedit))")
            } else {
                print("  '\(char)' (ASCII:\(ascii)) -> processed:\(processed), preedit: \(debugString(preedit)), commit: empty")
            }
        }
        
        let final = ucsToString(hangul_ic_flush(hicRight))
        result += final
        
        print("최종 결과: \(debugString(result)) \(result == "아름" ? "✅" : "❌")")
        
        hangul_ic_delete(hicRight)
    } else {
        print("❌ 오른손 키보드 생성 실패!")
    }
    
    // 왼손 키보드로 "바람" (hhyhb) 테스트
    if let hicLeft = hangul_ic_new("1hand-left") {
        print("\n왼손 키보드 생성 성공")
        hangul_ic_reset(hicLeft)
        
        let sequence = "hhyhb"
        var result = ""
        
        print("\n왼손 키보드로 '\(sequence)' 입력:")
        
        for char in sequence {
            let ascii = Int32(char.asciiValue!)
            let processed = hangul_ic_process(hicLeft, ascii)
            
            let commit = ucsToString(hangul_ic_get_commit_string(hicLeft))
            let preedit = ucsToString(hangul_ic_get_preedit_string(hicLeft))
            
            if !commit.isEmpty {
                result += commit
                print("  '\(char)' (ASCII:\(ascii)) -> processed:\(processed), commit: \(debugString(commit)), preedit: \(debugString(preedit))")
            } else {
                print("  '\(char)' (ASCII:\(ascii)) -> processed:\(processed), preedit: \(debugString(preedit)), commit: empty")
            }
        }
        
        let final = ucsToString(hangul_ic_flush(hicLeft))
        result += final
        
        print("최종 결과: \(debugString(result)) \(result == "바람" ? "✅" : "❌")")
        
        hangul_ic_delete(hicLeft)
    } else {
        print("❌ 왼손 키보드 생성 실패!")
    }
}

// 메인 함수
func main() {
    print("🚀 libhangul Swift 기본 테스트")
    print("================================")
    
    testBasicFunctionality()
    testGalmadeuli()
    testContinuousInput()
    
    print("\n✅ 모든 테스트 완료!")
}

// 실행
main()