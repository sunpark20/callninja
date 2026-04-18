# 프로젝트: CallNinja (콜닌자)

## 기술 스택
- iOS 16.0+, Swift 5.9+
- CallKit (CXCallDirectoryExtension)
- SwiftUI
- xcodegen

## 확정 파라미터
- K = 1,000,000 (익스텐션당 차단 건수)
- N = 10 (익스텐션 수, NinjaBlock00~09)
- maxConcurrent = 1 (순차 reload, 병렬 금지)
- 와일드카드 = 6자리 (항상 100만개)
- App Group: `group.com.callninja.shared`
- Bundle ID: `com.callninja.app` / `com.callninja.app.NinjaBlock0X`

## 아키텍처 규칙
- CRITICAL: 모든 익스텐션은 `NinjaBlockBase/CallDirectoryHandler.swift` 하나를 공유. 복사본 금지
- CRITICAL: 차단 번호는 E.164 Int64 오름차순 등록 (CallKit 요구사항)
- CRITICAL: addBlockingEntry 루프에서 힙 할당 금지. Int64 값 타입만 사용
- CRITICAL: 익스텐션 reload는 1개씩 순차 실행. 병렬 시 SQLite lock 경합
- CRITICAL: App Group UserDefaults `.synchronize()` 호출 후 `reloadExtension` 호출

## 데이터 흐름
```
사용자 번호 입력 → E.164 변환 → prefix 추출 (뒤 6자리 와일드카드)
→ App Group에 prefix+enabled 저장 → 익스텐션 reload
→ 익스텐션이 App Group에서 prefix 읽기 → prefix*1M ~ prefix*1M+999999 등록
```

## 데이터 저장
- App Group UserDefaults: `slot_N_prefix` (Int64), `slot_N_enabled` (Bool) — 익스텐션 전용
- 일반 UserDefaults: display, input, order, country, onboarding — 앱 전용

## SpamCall070과의 핵심 차이
- 고정 범위 → 동적 사용자 입력 (런타임 App Group 읽기)
- 58 익스텐션 × 175만 → 10 익스텐션 × 100만
- 번들 ID 기반 범위 계산 → App Group 기반 prefix 읽기
- 1 슬롯 = 1 익스텐션 = 1 패턴 = 100만개 (1:1 매핑)

## 명령어
```bash
./generate_extensions.sh        # 10개 익스텐션 디렉토리 생성
xcodegen generate               # project.yml → xcodeproj
xcodebuild build -project CallNinja.xcodeproj -scheme CallNinja -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO
```

## 개발 프로세스
- 커밋: conventional commits (feat:, fix:, docs:, refactor:)
- 실기기 테스트 필수 (시뮬레이터는 CallKit 미지원)
