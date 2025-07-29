# HangulKit Framework

HangulKit은 macOS IME 개발을 위한 libhangul 기반 프레임워크. 한손 키보드 기능을 포함하여 Swift/Objective-C 환경에서 한글 입력 처리를 위한 솔루션을 제공.

## 프로젝트 구조

```
HangulKit/
├── Scripts/
│   └── create_framework.sh     # Framework 생성 스크립트
├── Sources/
│   ├── HangulWrapper.h         # Objective-C 헤더
│   └── HangulWrapper.m         # Objective-C 구현
├── Tests/
│   └── SimpleSwiftTest.swift   # Swift 테스트
├── Docs/
│   └── IME_Integration_Guide.md # IME 통합 가이드
├── libhangul/                  # libhangul 서브모듈
└── README.md
```

## 빠른 시작

### 1. 저장소 클론 및 빌드

```bash
git clone --recursive https://github.com/Dev0June/HangulKit.git
cd HangulKit
./Scripts/create_framework.sh
```

### 2. 기본 사용법

```swift
import HangulKit

let inputContext = HangulInputContext(keyboard: "1hand-right")
inputContext.processKey(114) // 'r' 키
let result = inputContext.commitString // 완성된 문자
```

## 개발 요구사항

- **macOS**: 10.15 이상
- **Xcode**: 12.0 이상  
- **CMake**: 3.10 이상
