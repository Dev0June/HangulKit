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
├── libhangul/                  # libhangul 서브모듈
└── README.md
```

## 파일
create_framework.sh 로 빌드해서 사용하다. xcode 로 합체.

### 저장소 클론 및 빌드

```bash
git clone --recursive https://github.com/Dev0June/HangulKit.git
cd HangulKit
```

## 개발 요구사항

- **macOS**: 12.7 이상
- **Xcode**: 13.0 이상  
- **CMake**: 3.10 이상
