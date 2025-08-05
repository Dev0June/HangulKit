#!/bin/bash

# create_framework.sh
# IME용 HangulKit Framework 생성 스크립트

set -e

FRAMEWORK_NAME="HangulKit"
FRAMEWORK_DIR="../../${FRAMEWORK_NAME}.framework"

echo "Creating ${FRAMEWORK_NAME}.framework for macOS IME"

# 1. 프레임워크 디렉토리 구조 생성
echo "Creating framework directory structure..."
rm -rf "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Headers"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Modules"

# 심볼릭 링크 생성은 프레임워크 완성 후에 처리

echo "Framework directory structure created"

# 2. 동적 라이브러리 빌드 및 복사
echo "Building dynamic library..."

# libhangul 빌드
echo "  Building libhangul..."
cd ../libhangul

# 이미 빌드된 라이브러리 확인
EXISTING_DYLIB=$(find hangul -name "libhangul.*.*.*.dylib" -type f | head -1)

if [ -n "$EXISTING_DYLIB" ]; then
    echo "  Found existing library: $EXISTING_DYLIB"
else
    echo "  Building new library..."
    # CMake 설정 및 빌드 (Universal Binary)
    if ! cmake -DCMAKE_OSX_ARCHITECTURES="x86_64;arm64" -DBUILD_SHARED_LIBS=ON . > /dev/null 2>&1; then
        echo "  Error: cmake failed"
        exit 1
    fi
    
    if ! make > /dev/null 2>&1; then
        echo "  Warning: make had issues, but checking for dylib files..."
    fi
    
    EXISTING_DYLIB=$(find hangul -name "libhangul.*.*.*.dylib" -type f | head -1)
fi

# 라이브러리 파일 확인
echo "  Checking for built library..."
if [ -n "$EXISTING_DYLIB" ]; then
    echo "  Found: $EXISTING_DYLIB"
    echo "  Architecture info:"
    file "$EXISTING_DYLIB"
else
    echo "  Error: No libhangul dylib files found"
    echo "  Available files in hangul directory:"
    ls -la hangul/
    exit 1
fi

cd ../Scripts

echo "Library check completed"

# 3. Objective-C 래퍼 컴파일 및 결합
echo "Building complete framework with Objective-C wrapper..."

# HangulWrapper.m과 libhangul을 함께 컴파일
if [ -f "../Sources/HangulWrapper.m" ]; then
    echo "  Creating combined library with wrapper..."
    
    # 프레임워크 디렉토리가 존재하는지 확인
    FULL_FRAMEWORK_PATH="${FRAMEWORK_DIR}/Versions/A"
    echo "  FRAMEWORK_DIR: $FRAMEWORK_DIR"
    echo "  FULL_FRAMEWORK_PATH: $FULL_FRAMEWORK_PATH"
    echo "  Checking framework directory: $FULL_FRAMEWORK_PATH"
    if [ ! -d "$FULL_FRAMEWORK_PATH" ]; then
        echo "  Error: Framework directory not found: $FULL_FRAMEWORK_PATH"
        echo "  Current directory: $(pwd)"
        echo "  Let's try to create it..."
        mkdir -p "$FULL_FRAMEWORK_PATH"
        if [ ! -d "$FULL_FRAMEWORK_PATH" ]; then
            echo "  Failed to create framework directory"
            exit 1
        fi
    fi
    echo "  Framework directory ready"
    
    # 새로운 동적 라이브러리 생성
    clang -arch x86_64 -arch arm64 \
        -dynamiclib \
        -install_name @rpath/${FRAMEWORK_NAME}.framework/${FRAMEWORK_NAME} \
        -current_version 1.1.0 \
        -compatibility_version 1.0.0 \
        -mmacosx-version-min=12.7 \
        -I ../libhangul/hangul \
        -I ../Sources \
        -framework Foundation \
        ../Sources/HangulWrapper.m \
        ../libhangul/hangul/libhangul.1.1.0.dylib \
        -o "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
    
    if [ $? -eq 0 ] && [ -f "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}" ]; then
        echo "  Combined library created successfully"
        echo "  Verifying created library:"
        file "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
    else
        echo "  Warning: Failed to create combined library, using libhangul only"
        echo "  Clang exit code: $?"
        echo "  Checking if target file exists: $(ls -la ${FRAMEWORK_DIR}/Versions/A/ 2>/dev/null || echo 'Directory not found')"
        # 원래 라이브러리 사용
        cp ../libhangul/hangul/libhangul.1.1.0.dylib "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
        echo "  Copied original libhangul library"
    fi
else
    echo "  Warning: HangulWrapper.m not found, using libhangul only"
    # 원래 라이브러리 사용
    cp ../libhangul/hangul/libhangul.1.1.0.dylib "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"
fi

echo "Framework library build completed"

# 4. 헤더 파일 복사
echo "Copying header files..."
if [ -f "../Sources/HangulWrapper.h" ]; then
    cp ../Sources/HangulWrapper.h "${FRAMEWORK_DIR}/Versions/A/Headers/"
    echo "  HangulWrapper.h copied"
else
    echo "  Warning: HangulWrapper.h not found"
fi

# hangul.h는 HangulWrapper.h와 심볼 충돌을 일으키므로 포함하지 않음
echo "  Skipping hangul.h to avoid symbol conflicts"

echo "Header files copied"

# 5. 모듈 맵 생성
echo "Creating module map..."
cat > "${FRAMEWORK_DIR}/Versions/A/Modules/module.modulemap" << 'EOF'
framework module HangulKit {
    header "HangulWrapper.h"
    
    export *
    
    // C 라이브러리 링킹 설정
    link "c++"
}
EOF

echo "Module map created"

# 6. Info.plist 생성
echo "Creating Info.plist..."
cat > "${FRAMEWORK_DIR}/Versions/A/Resources/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>com.libhangul.${FRAMEWORK_NAME}</string>
    <key>CFBundleInfoDictionaryVersion</key>  
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${FRAMEWORK_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>FMWK</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>1.1.0</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>MinimumOSVersion</key>
    <string>10.15</string>
    <key>CFBundleSupportedPlatforms</key>
    <array>
        <string>MacOSX</string>
    </array>
</dict>
</plist>
EOF

echo "Info.plist created"

# 7. 프레임워크 심볼릭 링크 생성 (표준 macOS 프레임워크 구조)
echo "Creating framework symbolic links..."
cd "$FRAMEWORK_DIR"
ln -sf Versions/Current/Headers Headers
ln -sf Versions/Current/Resources Resources  
ln -sf Versions/Current/Modules Modules
ln -sf Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_NAME
cd Versions
ln -sf A Current
cd ../../../
echo "Framework symbolic links created"

# 8. 프레임워크 검증
echo "Verifying framework..."
# Scripts 디렉토리로 돌아와서 올바른 상대 경로 사용
cd /Volumes/Data/Project/macime/HangulKit/Scripts
FRAMEWORK_BINARY="${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
if [ -f "$FRAMEWORK_BINARY" ]; then
    echo "  ✓ Framework binary exists at: $FRAMEWORK_BINARY"
    file "$FRAMEWORK_BINARY"
    
    # 아키텍처 확인
    echo "  Architecture info:"
    lipo -info "$FRAMEWORK_BINARY"
else
    echo "  ✗ Framework binary not found at: $FRAMEWORK_BINARY"
    echo "  Checking what files exist in framework:"
    ls -la "${FRAMEWORK_DIR}/" || echo "Framework directory not found"
    ls -la "${FRAMEWORK_DIR}/Versions/A/" || echo "Versions/A directory not found"
    exit 1
fi

# 9. 프레임워크가 이미 프로젝트 루트에 생성됨
echo "Framework created directly in macime project root"
if [ -d "${FRAMEWORK_DIR}" ]; then
    echo "  ✓ Framework successfully created at: ${FRAMEWORK_DIR}"
    ls -la "${FRAMEWORK_DIR}"
else
    echo "  ✗ Framework creation failed"
fi

# 10. 정리
echo "Cleaning up temporary files..."
# 정적 라이브러리 파일들이 생성되지 않으므로 정리할 것이 없음

echo ""
echo "${FRAMEWORK_NAME}.framework 생성 완료!"
echo "위치: ${FRAMEWORK_DIR}"
echo ""
echo "사용법:"
echo "1. IME 프로젝트에서 프레임워크 추가:"
echo "   - Xcode > General > Frameworks, Libraries, and Embedded Content"
echo "   - 'Embed & Sign' 선택"
echo ""
echo "2. Swift/Objective-C에서 import:"
echo "   import HangulKit"
echo ""
echo "3. 갈마들이 기능 사용:"
echo "   let ic = HangulInputContext(keyboard: \"1hand-right\")"
echo "   ic.processKey(114) // 'r'"
echo "   ic.processKey(114) // 'r' -> '소'"
echo ""