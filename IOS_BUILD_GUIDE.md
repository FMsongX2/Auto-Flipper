# iOS 빌드 가이드

이 문서는 Auto-Flipper 앱을 iOS용으로 빌드하는 방법을 설명합니다.

## 필수 요구사항

- **macOS** (Xcode는 macOS에서만 실행 가능)
- **Xcode** (최신 버전 권장)
- **Flutter SDK** 
- **CocoaPods** (iOS 의존성 관리)
- **Apple Developer 계정** (실제 기기에 설치하려면 필요)

## iOS 빌드 전 확인사항

### 1. Flutter Doctor 확인

터미널에서 다음 명령어를 실행하여 iOS 개발 환경이 올바르게 설정되었는지 확인합니다:

```bash
flutter doctor -v
```

iOS 관련 항목이 모두 체크되어 있어야 합니다.

### 2. CocoaPods 설치 확인

```bash
pod --version
```

설치되어 있지 않다면:

```bash
sudo gem install cocoapods
```

### 3. iOS 의존성 설치

프로젝트 루트 디렉토리에서:

```bash
cd ios
pod install
cd ..
```

## iOS 빌드 방법

### 방법 1: Xcode를 사용한 빌드 (권장)

1. **Xcode에서 프로젝트 열기**

```bash
open ios/Runner.xcworkspace
```

2. **서명 설정**
   - Xcode에서 왼쪽 프로젝트 네비게이터에서 "Runner" 선택
   - "Signing & Capabilities" 탭 선택
   - "Automatically manage signing" 체크
   - Team 선택 (Apple Developer 계정 필요)

3. **빌드 및 실행**
   - 상단 메뉴에서 타겟 기기 선택 (시뮬레이터 또는 연결된 기기)
   - Product → Run (⌘R) 또는 재생 버튼 클릭

### 방법 2: Flutter CLI를 사용한 빌드

#### 시뮬레이터용 빌드

```bash
flutter build ios --simulator
```

#### 실제 기기용 빌드 (서명 필요)

```bash
flutter build ios --release
```

## IPA 파일 생성 (배포용)

### Archive 생성 (Xcode 필요)

1. Xcode에서 프로젝트 열기
2. Product → Archive 선택
3. Archive가 완료되면 Organizer 창이 열림
4. "Distribute App" 선택
5. 배포 방법 선택:
   - **App Store Connect**: App Store 배포용
   - **Ad Hoc**: 특정 기기용
   - **Enterprise**: 엔터프라이즈 배포용
   - **Development**: 개발/테스트용

### 명령줄에서 IPA 생성

```bash
flutter build ipa --release
```

생성된 IPA 파일 위치: `build/ios/ipa/Auto-Flipper.ipa`

## iOS 권한 설정

iOS에서 앱이 정상 작동하려면 다음 권한이 필요합니다:

### Info.plist 권한 추가

`ios/Runner/Info.plist`에 다음 권한이 자동으로 추가됩니다:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>악보 이미지를 선택하기 위해 사진 라이브러리 접근 권한이 필요합니다.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>악보 이미지를 저장하기 위해 사진 라이브러리 접근 권한이 필요합니다.</string>
```

## iOS 호환성 확인

이 앱은 다음 iOS 기능을 사용하며 모두 정상 작동합니다:

- ✅ **PDF 뷰어** (`flutter_pdfview`) - iOS 지원
- ✅ **파일 선택** (`file_picker`) - iOS 지원
- ✅ **권한 관리** (`permission_handler`) - iOS 지원
- ✅ **화면 유지** (`wakelock_plus`) - iOS 지원
- ✅ **진동 피드백** (`vibration`) - iOS 지원
- ✅ **로컬 저장소** (`shared_preferences`) - iOS 지원
- ✅ **경로 관리** (`path_provider`) - iOS 지원

## 문제 해결

### CocoaPods 오류

```bash
cd ios
pod deintegrate
pod install
cd ..
```

### 서명 오류

Xcode에서 "Signing & Capabilities"에서 올바른 Team을 선택하고, Bundle Identifier가 고유한지 확인하세요.

### 빌드 오류

```bash
flutter clean
cd ios
pod install
cd ..
flutter pub get
flutter build ios
```

## 참고

- iOS 최소 버전: iOS 13.0 이상
- 지원 기기: iPhone, iPad
- 앱 이름: Auto Flipper
- Bundle Identifier: `com.example.drumProjcet` (변경 권장)

## 배포

생성된 IPA 파일을 다음 방법으로 배포할 수 있습니다:

1. **TestFlight**: 베타 테스팅용
2. **App Store**: 공식 배포
3. **직접 설치**: Ad Hoc 또는 Enterprise 배포로 특정 기기에 직접 설치

## 추가 정보

- [Flutter iOS 배포 가이드](https://docs.flutter.dev/deployment/ios)
- [Xcode 문서](https://developer.apple.com/documentation/xcode)

