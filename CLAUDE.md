# 작업 가이드 (Claude Code용)

Flutter(웹 우선) + Firebase 앱. 개요와 환경 설정은 [README.md](README.md).

## 문구 원칙

- **서술형 문장을 최대한 쓰지 않는다.** 제목·버튼·라벨은 명사형 단어로 짧게 쓴다 ("디자인 선택", "부서 만들기"). "~를 골라요", "~해 주세요" 같은 안내 문장과 부차적인 설명(부제, 예시)은 두지 않는다. 오류·확인처럼 꼭 필요한 곳만 한 줄로 쓴다.

## 구조 규칙

- **Feature-first + MVVM**, 추가 상태관리 패키지 없음. 기능 폴더는 `data`(저장소) · `view_model` · `view`.
- 화면은 저장소를 직접 부르지 않고 ViewModel만 쓴다. ViewModel은 `core/mvvm/view_model.dart`를 상속하고 `run()`으로 busy/error를 관리한다.
- ViewModel은 `ViewModelBuilder`로 만들고 저장소는 `AppScope.read(context)`로 꺼낸다. 스트림은 ViewModel 생성자에서 한 번만 만든다(build마다 새로 만들면 재구독으로 깜빡인다).
- 공통 UI는 `core/layout`(PageFrame, CardGrid, SubPage, showAppDialog), 색·모서리는 `core/theme.dart`(`AppColors`, `AppRadius`).
- 레이아웃: 내용은 `kContentWidth`(880) 가운데 고정, `kNarrow`(800) 미만이면 모바일(하단 탭). 모서리는 부드럽게(`AppRadius`: 컨트롤 12 · 카드 16 · 대화상자/패널 24), 카드는 `AppShadow.soft`/카드 테마의 옅은 그림자로 띄운다. 배색은 소프트 인디고+코랄(`AppPalette`).

## 데이터·권한

- 모든 교회 데이터는 `churches/{churchId}/...` 아래. 권한은 **`firestore.rules`가 강제**한다 (화면에서 숨기는 것만으로는 안 된다).
- 역할: 앱 운영자(`platformAdmin` 클레임, 교회 소속 아님) / 교회 운영자(`admin`) / 교역자(`staff`) / 교인(`member`).
- 로그인은 아이디+비밀번호. `loginIds/{id}`가 아이디→이메일을 연결한다. 예약 아이디(`admin` 등)는 가상 이메일(`LoginId.aliasEmail`)로 로그인한다.
- 교회는 앱 운영자의 승인(`churchRequests`)이나 직접 등록으로만 만들어지고, 입장은 만료 있는 초대 코드(`inviteCodes`)로만 가능하다.
- **기능은 기도제목 · 모임 · 성경 셋뿐이다.** 레이아웃 다양화·페이지 편집·공지/일정/사진첩/설교영상은 없앴다. 새 기능은 왼쪽 메뉴(서랍)나 하단 탭(`ChurchShell`)에 항목만 더한다.
- 성경(말씀묵상) 글은 `churches/{id}/devotions`에 있고 `ContentKind`와 `firestore.rules`가 일치해야 한다. 이미지 업로드는 교회·회원 썸네일뿐이다(`storage.rules`).
- 모임은 `churches/{id}/meetings`에 있다 (모임장 · 정원 · 참여자 · 좋아요 · 조회수). 목록 모양은 알록달록 / 심플 중 사용자가 고른다(`ListStyleController`).
- 말씀묵상 글(구절 한 단락)에는 교인이 자기 글을 남긴다: `churches/{id}/devotions/{글}/reflections/{uid}` (한 사람 한 편에 한 개, `firestore.rules`의 reflections 규칙, 길이 1000자는 `DevotionReflection.maxLength`와 일치).
- 말씀묵상 글 쓰기는 교역자 이상, 기도 설정·교회 정보는 교회 운영자(`admin`)만 한다.
- 로그인하면 승인된 교회가 있을 때 `/churches`가 마지막 교회의 메인으로 바로 넘어간다. 목록을 보려면 `Routes.churchList`.
- 새 필드를 추가하면 모델·저장소·`firestore.rules`의 `hasOnly([...])` 목록을 **같이** 고친다. 이모티콘 종류도 `lib/data/models/reaction.dart`와 규칙이 일치해야 한다.

## 자주 쓰는 명령

```
flutter analyze
dart format lib
flutter build web --no-wasm-dry-run
firebase deploy --only firestore            # 규칙 + 인덱스
firebase deploy --only storage              # 이미지 저장소 규칙
firebase deploy --only firestore:rules --dry-run   # 규칙 문법 검사
```

## 주의할 점

- **Windows PowerShell 5.1**에서 `Set-Content -Encoding utf8`은 BOM을 붙인다. `firestore.rules`에 BOM이 들어가면 컴파일이 실패한다. 규칙 파일은 BOM 없이 저장한다.
- 파일을 PowerShell 문자열로 치환할 때 `$(database)` 같은 `$` 표현이 변수로 해석되지 않게 작은따옴표 here-string을 쓴다.
- 로그인 정보나 비밀번호, 운영자 계정 비밀번호는 저장소에 커밋하지 않는다.
- 웹 핫 리로드는 불안정하다. 이상하면 완전히 다시 실행한다. 개발 실행은 `.vscode/launch.json`의 "웹 (로그인 유지)"(포트 5000 + 고정 Chrome 프로필).
- 개인정보 제3자 제공 동의 문구(`features/auth/view/consent_checkbox.dart`)는 초안이다.
