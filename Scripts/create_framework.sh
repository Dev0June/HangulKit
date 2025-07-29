#!/bin/bash

# create_framework.sh
# IME용 HangulKit Framework 생성 스크립트

set -e

FRAMEWORK_NAME="HangulKit"
BUILD_DIR="build"
FRAMEWORK_DIR="${BUILD_DIR}/${FRAMEWORK_NAME}.framework"

echo "Creating ${FRAMEWORK_NAME}.framework for macOS IME"

# 1. 프레임워크 디렉토리 구조 생성
echo "Creating framework directory structure..."
rm -rf "$FRAMEWORK_DIR"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Headers"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Resources"
mkdir -p "$FRAMEWORK_DIR/Versions/A/Modules"

# 심볼릭 링크 생성 (표준 프레임워크 구조)
cd "$FRAMEWORK_DIR"
ln -sf Versions/Current/Headers Headers
ln -sf Versions/Current/Resources Resources
ln -sf Versions/Current/Modules Modules
ln -sf Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_NAME
cd Versions
ln -sf A Current
cd ../../../

echo "Framework directory structure created"

# 2. 정적 라이브러리 생성 (Universal Binary)
echo "Building universal static library..."

# Intel (x86_64) 빌드
echo "  Building for x86_64..."
cd libhangul
make clean > /dev/null 2>&1
cmake -DCMAKE_OSX_ARCHITECTURES=x86_64 . > /dev/null 2>&1
make > /dev/null 2>&1
ar rcs ../libhangul_x86_64.a hangul/CMakeFiles/hangul.dir/*.o

# Apple Silicon (arm64) 빌드 (크로스 컴파일)
echo "  Building for arm64..."
make clean > /dev/null 2>&1
cmake -DCMAKE_OSX_ARCHITECTURES=arm64 . > /dev/null 2>&1
make > /dev/null 2>&1
ar rcs ../libhangul_arm64.a hangul/CMakeFiles/hangul.dir/*.o

cd ..

# Universal Binary 생성
echo "  Creating universal binary..."
lipo -create libhangul_x86_64.a libhangul_arm64.a -output "${FRAMEWORK_DIR}/Versions/A/${FRAMEWORK_NAME}"

echo "Universal static library created"

# 3. 헤더 파일 복사
echo "Copying header files..."
cp Sources/HangulWrapper.h "${FRAMEWORK_DIR}/Versions/A/Headers/"
cp libhangul/hangul/hangul.h "${FRAMEWORK_DIR}/Versions/A/Headers/"

echo "Header files copied"

# 4. 모듈 맵 생성
echo "Creating module map..."
cat > "${FRAMEWORK_DIR}/Versions/A/Modules/module.modulemap" << 'EOF'
framework module HangulKit {
    header "HangulWrapper.h"
    header "hangul.h"
    
    export *
    
    // C 라이브러리 링킹 설정
    link "c++"
    
    // 모듈 설정
    module hangul {
        header "hangul.h"
        export *
    }
    
    module wrapper {
        header "HangulWrapper.h"
        export *
    }
}
EOF

echo "Module map created"

# 5. Info.plist 생성
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

# 6. 프레임워크 검증
echo "Verifying framework..."
if [ -f "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}" ]; then
    echo "  Framework binary exists"
    file "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
    
    # 아키텍처 확인
    lipo -info "${FRAMEWORK_DIR}/${FRAMEWORK_NAME}"
else
    echo "  Framework binary not found"
    exit 1
fi

# 7. 정리
echo "Cleaning up temporary files..."
rm -f libhangul_x86_64.a libhangul_arm64.a

echo ""
echo "${FRAMEWORK_NAME}.framework 생성 완료!"
echo "위치: $(pwd)/${FRAMEWORK_DIR}"
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