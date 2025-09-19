#!/usr/bin/env swift

import Foundation

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

@_silgen_name("hangul_ic_get_commit_string")
func hangul_ic_get_commit_string(_ hic: OpaquePointer) -> UnsafePointer<UInt32>?

@_silgen_name("hangul_ic_get_preedit_string")
func hangul_ic_get_preedit_string(_ hic: OpaquePointer) -> UnsafePointer<UInt32>?

private func ucsToString(_ ucsPtr: UnsafePointer<UInt32>?) -> String {
    guard let ptr = ucsPtr else { return "" }
    var scalars: [UnicodeScalar] = []
    var index = 0
    while ptr[index] != 0 {
        let codePoint = ptr[index]
        if let scalar = UnicodeScalar(codePoint) {
            scalars.append(scalar)
        }
        index += 1
    }
    return String(String.UnicodeScalarView(scalars))
}

private func asciiSequence(_ sequence: String) -> [Int32] {
    return sequence.unicodeScalars.map { Int32($0.value) }
}

private func runSequence(_ hic: OpaquePointer, _ sequence: String) -> String {
    var committed = ""
    for ascii in asciiSequence(sequence) {
        _ = hangul_ic_process(hic, ascii)
        committed += ucsToString(hangul_ic_get_commit_string(hic))
    }
    committed += ucsToString(hangul_ic_flush(hic))
    return committed
}

private func assertEqual(_ actual: String, _ expected: String, _ message: String) {
    if actual == expected {
        print("✅ \(message)")
    } else {
        print("❌ \(message) — expected '\(expected)', got '\(actual)'")
        exit(1)
    }
}

private func testDubeolsikBaseline() {
    guard let hic = hangul_ic_new("2") else {
        fatalError("Failed to create dubeolsik context")
    }
    defer { hangul_ic_delete(hic) }

    hangul_ic_reset(hic)
    let result = runSequence(hic, "gks")
    assertEqual(result, "한", "두벌식 gks -> 한")
}

private func testOneHandRightGalmadeuli() {
    guard let hic = hangul_ic_new("1hand-right") else {
        fatalError("Failed to create one-hand right context")
    }
    defer { hangul_ic_delete(hic) }

    hangul_ic_reset(hic)
    assertEqual(runSequence(hic, "rr"), "소", "한손 오른손 rr -> 소")

    hangul_ic_reset(hic)
    assertEqual(runSequence(hic, "ee"), "주", "한손 오른손 ee -> 주")

    hangul_ic_reset(hic)
    assertEqual(runSequence(hic, "fmth"), "우리", "한손 오른손 fmth -> 우리")
}

private func testResetClearsTransientState() {
    guard let hic = hangul_ic_new("1hand-right") else {
        fatalError("Failed to create one-hand right context")
    }
    defer { hangul_ic_delete(hic) }

    // Prime state with a partial composition, then reset to ensure galmadeuli metadata is cleared.
    let asciiR = Int32("r".unicodeScalars.first!.value)
    _ = hangul_ic_process(hic, asciiR)
    hangul_ic_reset(hic)

    let result = runSequence(hic, "rr")
    assertEqual(result, "소", "hangul_ic_reset 후 첫 갈마들이 rr 유지")
}

private func main() {
    print("🚀 libhangul one-hand regression tests")
    testDubeolsikBaseline()
    testOneHandRightGalmadeuli()
    testResetClearsTransientState()
    print("\n✅ Tests finished")
}

main()
