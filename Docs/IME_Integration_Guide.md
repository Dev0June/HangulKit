# macOS IME 개발을 위한 HangulKit 가이드

HangulKit Framework를 사용하여 macOS용 한글 입력기 개발

## 1. 프로젝트 설정

### Framework 생성
```bash
./Scripts/create_framework.sh
```

### Xcode 프로젝트에 Framework 추가
1. **General** → **Frameworks, Libraries, and Embedded Content**
2. **Add** → `HangulKit.framework` 선택  
3. **Embed & Sign** 설정

## 2. InputMethodKit 통합

### 기본 IMK Controller 구현

```swift
import InputMethodKit
import HangulKit

@objc(MyInputMethodController)
class MyInputMethodController: IMKInputController {
    private var hangulContext: HangulInputContext?
    
    override func activateServer(_ sender: Any!) {
        super.activateServer(sender)
        // 오른손 갈마들이 키보드로 초기화
        hangulContext = HangulInputContext(keyboard: "1hand-right")
    }
    
    override func handle(_ event: NSEvent!, client sender: Any!) -> Bool {
        guard let context = hangulContext,
              let client = sender as? IMKTextInput else { return false }
        
        let keyCode = Int32(event.keyCode)
        let processed = context.processKey(keyCode)
        
        if processed {
            handleHangulInput(client: client, context: context)
            return true
        }
        
        return false
    }
    
    private func handleHangulInput(client: IMKTextInput, context: HangulInputContext) {
        let commit = context.commitString
        let preedit = context.preeditString
        
        if !commit.isEmpty {
            // 완성된 문자 입력
            client.insertText(commit, replacementRange: NSRange(location: NSNotFound, length: 0))
        } else if !preedit.isEmpty {
            // 조합 중인 문자 표시
            client.setMarkedText(preedit, 
                               selectionRange: NSRange(location: preedit.count, length: 0),
                               replacementRange: NSRange(location: NSNotFound, length: 0))
        } else {
            // 조합 해제
            client.setMarkedText("", 
                               selectionRange: NSRange(location: 0, length: 0),
                               replacementRange: NSRange(location: NSNotFound, length: 0))
        }
    }
}
```

## 3. 키보드 설정

### 지원 키보드 종류
- `"1hand-right"`: 오른손 한손 키보드
- `"1hand-left"`: 왼손 한손 키보드  


### 키보드 전환
```swift
class KeyboardManager {
    private var inputContext: HangulInputContext?
    
    func switchToRightHand() {
        inputContext?.selectKeyboard("1hand-right")
    }
    
    func switchToLeftHand() {
        inputContext?.selectKeyboard("1hand-left")
    }
    
    func getAvailableKeyboards() -> [String] {
        var keyboards: [String] = []
        let count = HangulKeyboard.keyboardCount()
        
        for i in 0..<count {
            if let keyboardId = HangulKeyboard.keyboardId(at: i) {
                keyboards.append(keyboardId)
            }
        }
        return keyboards
    }
}
```

## 4. 상태 관리
```swift
class IMEStateManager {
    private var isHangulMode = true
    private var currentKeyboard = "1hand-right"
    
    func toggleInputMode() {
        isHangulMode.toggle()
        // UI 업데이트 등
    }
    
    func switchHandMode() {
        currentKeyboard = (currentKeyboard == "1hand-right") ? "1hand-left" : "1hand-right"
        inputContext?.selectKeyboard(currentKeyboard)
    }
}
```

## 5. 배포 및 설정

### Info.plist 설정
```xml
<key>InputMethodConnectionName</key>
<string>MyIME_Connection</string>
<key>InputMethodServerControllerClass</key>
<string>MyInputMethodController</string>
<key>NSAppleEventsUsageDescription</key>
<string>한글 입력기 기능을 위해 필요합니다.</string>
```

### 코드 서명
```bash
# Framework 서명
codesign --deep --force --sign "Developer ID" HangulKit.framework
```


## 6. 문제 해결

### Framework 로딩 실패
```bash
otool -L HangulKit.framework/HangulKit
lipo -info HangulKit.framework/HangulKit
```

## 7. API 레퍼런스

### HangulInputContext 주요 메서드
- `init(keyboard: String)`: 컨텍스트 초기화
- `processKey(_: Int32) -> Bool`: 키 입력 처리
- `commitString: String`: 완성된 문자열
- `preeditString: String`: 조합 중인 문자열
- `selectKeyboard(_: String)`: 키보드 전환
- `flush() -> String`: 조합 강제 완성

### HangulKeyboard 유틸리티
- `keyboardCount() -> Int32`: 키보드 개수
- `keyboardId(at: Int32) -> String?`: 키보드 ID 조회