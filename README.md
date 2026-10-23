# 함께 지어져 가는 공동체 (built_in_together)

등록교인이 서로의 기도제목을 안전하게 나누는 앱입니다. 댓글 대신 이모티콘으로 조용히 응원하고,
교역자에게만 전하고 싶은 기도제목은 비공개로 보관합니다. Flutter(웹 우선) + Firebase로 만들었습니다.

## 주요 기능

- **로그인/가입**: 아이디 + 비밀번호(이메일 인증, 이름, 전화번호, 개인정보 제3자 제공 동의). Google 로그인은 첫 로그인 때 같은 정보를 입력받습니다.
- **교회**: 초대 코드(7일 유효)로 입장 신청 → 교역자 승인. 교회 생성은 요청 후 앱 운영자 승인. 한 사용자가 여러 교회에 속할 수 있습니다.
- **기도제목**: 공개/교역자 전용, 부서 전용 공간, 이모티콘 응원(누른 사람은 비공개), 교역자 댓글·답변, 소프트 삭제(사유 기록).
- **역할**: 앱 운영자 / 교회 운영자 / 교역자 / 교인. 앱 운영자는 교회에 소속되지 않는 독립 관리자 패널을 씁니다.

권한은 화면이 아니라 `firestore.rules`가 서버에서 강제합니다.

## 구조 (Feature-first + MVVM, 추가 패키지 없음)

```
lib/
  app/        앱 시작, 의존성 주입(AppScope)
  core/       테마, 공통 레이아웃, MVVM 기반(ViewModel, ViewModelBuilder), 주소 검색, 전화번호 형식
  data/       모델, Firestore 경로
  features/
    auth/     로그인·가입·이메일 인증·프로필 입력   (data / view_model / view)
    church/   내 교회, 입장·생성 요청, 부서 선택
    members/  교인 저장소
    prayers/  피드, 상세, 작성, 응원
    shell/    교회 안 화면 틀(상단 메뉴 / 모바일 하단 탭)
    admin/    교회 관리(기도제목·교인·초대 코드·부서)
    platform/ 앱 운영자 패널(대시보드·교회 관리·회원 관리)
firestore.rules, firestore.indexes.json   보안 규칙과 인덱스
tool/create_admin.ps1                      앱 운영자 계정 생성/비밀번호 재설정
```

화면(view)은 저장소를 직접 부르지 않고 ViewModel만 씁니다. 자세한 작업 규칙은 [CLAUDE.md](CLAUDE.md)를 보세요.

## 다른 컴퓨터에서 이어서 작업하기

1. **도구 설치**: Flutter SDK(stable), Git, Node.js, Firebase CLI(`npm i -g firebase-tools`). VS Code를 쓰면 Dart/Flutter 확장도 설치합니다.
2. **받기**
   ```
   git clone https://github.com/pantokr/built-in-together.git
   cd built-in-together
   flutter pub get
   ```
3. **Firebase 로그인**: `firebase login` (프로젝트는 `.firebaserc`의 `being-built-together`가 기본값입니다).
4. **실행**: VS Code에서 `웹 (로그인 유지)` 구성을 선택해 실행하세요(포트 5000, 로그인 유지용 Chrome 프로필 사용).
   터미널이라면 `flutter run -d chrome --web-port=5000`.
5. **보안 규칙·인덱스 배포**(규칙을 바꾼 경우에만): `firebase deploy --only firestore`

`lib/firebase_options.dart`와 `android/app/google-services.json`은 저장소에 포함되어 있어 `flutterfire configure`를 다시 할 필요가 없습니다.
(새 Firebase 프로젝트를 쓰려면 `dart pub global activate flutterfire_cli` 후 `flutterfire configure`.)

## Firebase 콘솔 사전 설정 (프로젝트에 한 번만)

- Authentication → Sign-in method: **이메일/비밀번호**와 **Google**을 사용 설정합니다.
  (이메일/비밀번호가 꺼져 있으면 아이디 로그인과 가입이 모두 `PASSWORD_LOGIN_DISABLED`로 실패합니다.)
- Authentication → 설정 → 승인된 도메인: 배포 도메인을 추가합니다 (`localhost`는 기본 포함).
- Authentication → 템플릿: 인증 메일 문구를 한국어로 바꿀 수 있습니다.

## 앱 운영자 계정

아이디 `admin`으로 로그인하는 계정이며, 권한은 계정의 `platformAdmin` 커스텀 클레임입니다.
비밀번호는 저장소에 없습니다. 만들거나 비밀번호를 다시 정하려면:

```
powershell -File tool\create_admin.ps1
```

`admin`은 예약 아이디라 일반 회원이 만들 수 없습니다.

## 알려진 한계

- 아이디 → 이메일 조회 문서(`loginIds`)가 공개라, 아이디를 알면 그 이메일이 보입니다. 서버에서 조회하려면 Cloud Functions(Blaze 플랜)가 필요합니다.
- 푸시 알림, 비공개 글 열람 기록의 위·변조 방지는 Cloud Functions 없이는 완전하지 않습니다.
- 주소 검색(카카오 우편번호)은 웹에서만 동작합니다. 모바일 앱은 직접 입력합니다.
- 개인정보 제3자 제공 동의 문구는 초안입니다. 공개 전에 법률 검토가 필요합니다.
