<img width="284" height="638" alt="image" src="https://github.com/user-attachments/assets/17b09d0f-a84a-4cea-8f5a-a762391caae1" /># 🧥 DAILY CLOSET (ILLUSION ARCHIVE)
> **공공 기상 데이터 OpenWeatherMap API와 유저 Closet 아카이브를 결합한 지능형 패션 큐레이션 및 OOTD 착장 일기장 앱**

본 어플리케이션은 사용자의 실시간 GPS 위치 정보를 기반으로 기상 데이터를 수집하고, 해당 기온 및 날씨 환경에 최적화된 의상을 사용자의 개인 소장 옷장 데이터베이스와 대조하여 자동 매칭해주는 UX/UI 중심의 패션 테크 아카이빙 플랫폼입니다.

---

## 📱 1. 주요 실행 화면 (Project Screenshots)

| 01. 3D 입체 인트로 (스플래시) | 02. 실시간 날씨 추천 탭 | 03. 내 옷으로 추천 (큐레이션 뷰) |
| :---: | :---: | :---: |
| ![인트로](door_screenshot.png) | ![추천 탭](maintap_screenshot.png) | ![내 옷 추천](myrecommend_screenshot) |

| 04. 아카이브 클로젯 탭 | 05. OOTD 다이어리 일기장 탭 | 06. 마이 페이지 (친구 인터랙션) |
| :---: | :---: | :---: |
| ![클로젯 탭](closet_screenshot.png) | ![OOTD 탭](ootdtap_screenshot.png) | ![마이 페이지](myfriendtap_screenshot.png) |

---

## ✨ 2. 핵심 구현 기능 (Core Architecture & Features)

### 🚪 3D 가변 그래픽 스플래시 인트로 (Splash Screen)
- **Matrix4 3D 변환 기전**: `Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY()` 수학적 연산을 응용하여 앱 구동 시 좌/우 옷장 문(`door_left.png`, `door_right.png`)이 입체적으로 회전하며 열리는 가변 3D 애니메이션 연출.
- **비동기 초기화(Asynchronous Sync)**: 앱이 켜지는 3초 동안 기상 API 데이터를 백그라운드에서 선제적으로 패치하여 메인 화면 진입 시 지연 없는 사용자 경험(UX) 선사.

### ☀️ 실시간 기상 대시보드 및 지능형 추천 엔진 (Recommend Tab)
- **GPS 위치 연동**: `Geolocator` 플러그인을 활용하여 하드웨어 가상 GPS 위도/경도를 실시간 수신.
- **날씨 스킨 동적 스위칭**: `StyleEngine`을 구축하여 기온 상태 및 우천 여부(OpenWeatherMap Weather ID 200~599 분기)에 따라 앱 전체 테마 컬러(`color`)와 텍스트 폰트를 실시간 분기 처리 (`AnimatedContainer` 가동).
- **'내 옷으로 추천' 알고리즘 (핵심 고도화)**: 가시성이 극대화된 수제 화이트 캡슐 토글 버튼 UI 배치. 켜기 활성화 시 현재 기온 환경을 계산하여 내 옷장(`globalMyCloset`) 내 등록된 실제 의류 중 계절적 밸런스가 완벽한 상/하의 컬렉션을 역추적 큐레이션 완료.

### 🗂 소장 의류 통합 그리드 뷰 (Closet Tab)
- **전체 조회 아카이브**: 사용자가 보관 중인 모든 디지털 의류 자산을 `GridView.builder`를 통해 3열 종대로 정갈하게 정렬 및 시각화.
- **가변 소스 로더**: 앱 내 기본 탑재 에셋 파일(`Image.asset`)과 사용자가 `ImagePicker` 모듈을 통해 직접 스마트폰 갤러리/디바이스에서 업로드한 동적 파일(`Image.file`)을 무결성 예외 처리하여 실시간 동시 가동.

### 🔍 글로벌 타겟 기상 수신 탐색기 (Search Tab)
- **도시명/기온 크로스 검색**: 검색 창에 해외 도시명(`London`, `Tokyo`)을 입력 시 실시간 날씨 API 통신이 작동하며, 기온 수치(`25`, `10`)를 입력 시 즉시 가상 커스텀 날씨 조건으로 수리 연산.
- **원스톱 탭 라우팅**: 검색 연산 성공 직후 첫 번째 추천 대시보드 탭으로 오토 매핑되어 돌아오는 사용자 흐름 자동화 제어.

### 📝 OOTD 착장 일기장 탭 (OOTD Diary Tab - 신규 고도화)
- **멀티 미디어 다이어리**: 오늘 착용한 데일리 룩 이미지를 사진 첨부할 수 있는 `ImagePicker` 연동 존 레이아웃 확보.
- **콘텍스트 데이터 바인딩**: 착장 명칭, 일기 메모 코멘트와 함께 **[등록 당시의 실시간 날씨/기온 정보]** 및 **[오늘 날짜]**를 완벽하게 결합하여 타임라인 카드 히스토리 형태로 데이터 영구 보존 및 누적.

### 👤 프로필 대시보드 및 소셜 피드 프리뷰 (My Page Tab)
- **동적 카운팅 통계**: 내 옷장에 소장 중인 옷 벌 수 데이터와 OOTD 일기장에 기입된 착장 일기 건수를 실시간 갱신하는 동적 통계 카드 탑재. Card 클릭 시 해당 갤러리 및 모달 히스토리 다이얼로그로 하이퍼 연동.
- **소셜 확장 팝업 인터랙션**: 가로 스크롤 형태의 친구 피드 구현. 카드 터치 시 James, Sophie, Dan 등 **친구별 패션 성향 감성에 맞는 고유 아이콘(`checkroom`, `auto_awesome`, `explore`)이 런타임에 동적으로 매핑**되어 팝업창(Dialog) 모달로 강제 전환되며, 개인 계정 피드 가상 방문 버튼 인터랙션 가동.

---

## 🛠 3. 기술 스택 및 외부 라이브러리 (Tech Stack)

- **Language & SDK**: Dart / Flutter SDK (`useMaterial3: true` 디자인 시스템 규격 준수)
- **State Management**: State 변경에 대응하는 구조적 `StatefulWidget` 및 `IndexedStack` 멀티 탭 바 바인딩 구조.
- **Dependencies & Packages**:
```yaml
  dependencies:
    flutter:
      sdk: flutter
    http: ^1.2.0          # OpenWeatherMap API 실시간 JSON 통신용
    geolocator: ^11.0.0   # 모바일 디바이스 GPS 위도/경도 데이터 수신용
    image_picker: ^1.1.0  # 아카이브 내 카메라/갤러리 사진 업로드 및 사진 일기 구현용
