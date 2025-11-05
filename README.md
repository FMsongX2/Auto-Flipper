# Auto Flipper

드럼 연주 시 악보를 자동으로 넘겨주는 Flutter 기반 모바일 애플리케이션입니다.

## 📱 다운로드

**최신 APK 파일**: [Auto-Fliper.apk](Auto-Fliper.apk) 직접 다운로드

또는 [GitHub Releases](https://github.com/FMsongX2/Auto-Flipper/releases)에서 최신 버전을 다운로드하세요.

---


## 프로젝트 목적

합주나 연주 중에 악보를 수동으로 넘기는 것은 번거로우며, 타이밍을 놓칠 수 있습니다. 이 프로젝트는 BPM(Beats Per Minute)과 박자표를 기반으로 악보 페이지를 자동으로 넘겨주어, 드럼 연주자가 음악에 집중할 수 있도록 돕기 위해 개발되었습니다.

## 주요 기능

- **PDF/이미지 악보 뷰어**: PDF 및 이미지 형식의 드럼 악보를 지원합니다
- **BPM 기반 자동 페이지 넘김**: 입력된 BPM과 박자표를 기반으로 정확한 타이밍에 악보 페이지를 자동으로 넘깁니다
- **1마디 카운트다운**: 재생 전 1마디 카운트다운(4, 3, 2, 1)을 통해 정확한 시작 타이밍을 제공합니다
- **폴더 관리**: 악보를 폴더별로 정리하고 관리할 수 있습니다
- **플레이어 모드**: 전체화면 플레이어 모드로 악보에 집중할 수 있습니다
- **커스텀 미리보기**: 악보별 커스텀 미리보기 이미지를 추가할 수 있습니다

## 기술 스택 및 오픈소스 라이브러리

이 프로젝트는 다음 오픈소스 라이브러리들을 사용하여 구현되었습니다:

### 프레임워크
- **[Flutter](https://flutter.dev/)** - 크로스 플랫폼 모바일 앱 개발 프레임워크

### 상태 관리
- **[provider](https://pub.dev/packages/provider)** (v6.1.1) - 상태 관리 및 의존성 주입

### 파일 처리
- **[flutter_pdfview](https://pub.dev/packages/flutter_pdfview)** (v1.3.2) - PDF 뷰어
- **[file_picker](https://pub.dev/packages/file_picker)** (v10.3.3) - 파일 선택 기능
- **[path_provider](https://pub.dev/packages/path_provider)** (v2.1.1) - 파일 경로 관리
- **[path](https://pub.dev/packages/path)** (v1.8.3) - 경로 처리 유틸리티

### 데이터 저장
- **[shared_preferences](https://pub.dev/packages/shared_preferences)** (v2.2.2) - 로컬 데이터 저장

### 유틸리티
- **[wakelock_plus](https://pub.dev/packages/wakelock_plus)** (v1.4.0) - 화면 꺼짐 방지
- **[vibration](https://pub.dev/packages/vibration)** (v3.1.4) - 진동 피드백
- **[uuid](https://pub.dev/packages/uuid)** (v4.3.3) - UUID 생성
- **[image](https://pub.dev/packages/image)** (v4.1.3) - 이미지 처리

### 개발 도구
- **[json_annotation](https://pub.dev/packages/json_annotation)** (v4.8.1) - JSON 직렬화
- **[flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)** (v0.13.1) - 앱 아이콘 생성


## 라이센스

이 프로젝트는 **Apache 2.0** 라이센스를 따릅니다. 자유롭게 사용, 수정, 배포할 수 있습니다.


