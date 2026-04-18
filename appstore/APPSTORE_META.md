# App Store 메타데이터 — 콜닌자 (CallNinja)

## 기본 정보
- **앱 이름 (한국)**: 콜닌자 - 스팸 전화 패턴 차단
- **앱 이름 (영어)**: CallNinja - Spam Call Blocker
- **부제 (한국)**: 번호 하나 입력하면 100만개 차단
- **부제 (영어)**: Enter one number, block 1 million
- **카테고리**: 유틸리티
- **가격**: 무료
- **연령 등급**: 4+
- **프라이버시 정책 URL**: https://homeninja.vercel.app/privacy/callninja

---

## App Store 설명 (한국어)

```
070-7737-4896, 070-7738-0792, 070-7749-8029…
뒷자리만 바꿔가며 끊임없이 오는 스팸 전화,
하나씩 차단해도 소용없었죠?

콜닌자는 번호 범위를 통째로 차단합니다.
070-77XX-XXXX — 이 패턴 안의 100만 개 번호를 한 번에 막습니다.

다른 차단 앱과 다릅니다.
다른 앱은 "스팸 의심" 알림을 띄우지만, 전화벨은 울립니다.
콜닌자는 iOS 시스템 레벨에서 원천 차단합니다.
벨소리가 울리지 않습니다.

[사용 방법]
1. 나라를 선택합니다 (최초 1회)
2. 설정에서 10개 항목을 켭니다 (최초 1회)
3. 스팸 전화에서 본 번호를 그대로 입력합니다
4. 해당 범위가 자동으로 차단됩니다

예) 070-7737-4540 입력
→ 070-77XX-XXXX 범위 100만 개 번호 즉시 차단
→ 뒷자리를 아무리 바꿔도 전부 차단됩니다

[핵심 특징]
• 범위 차단: 뒷자리를 바꿔가며 오는 스팸을 한 번에 차단
• 원천 차단: 벨소리가 울리기 전에 시스템 레벨에서 차단
• 최대 10개 범위, 총 1,000만 개 번호 차단 가능
• 번호 입력 후 약 12초면 차단 완료
• 이후 별도 조작 없이 영구 동작

[안심하세요]
• 연락처에 저장된 번호는 차단되지 않습니다
• 카카오톡, FaceTime 등 인터넷 전화에는 영향 없습니다
• 개인정보 수집 없음, 네트워크 통신 없음
• 249개국 전화번호 형식 지원
```

## App Store 설명 (영어)

```
Spammers change the last few digits and call again.
Blocking them one by one doesn't work.

CallNinja blocks an entire number range at once.
070-77XX-XXXX — 1 million numbers in this range, blocked instantly.

Unlike other call-blocking apps:
Other apps show a "suspected spam" popup, but your phone still rings.
CallNinja blocks calls at the iOS system level.
Your phone doesn't ring. The call never reaches you.

[How to use]
1. Select your country (one time)
2. Enable 10 items in Settings (one time)
3. Enter the spam number exactly as you received it
4. The matching range is automatically blocked

Example: Enter 070-7737-4540
→ Blocks all 070-77XX-XXXX (1,000,000 numbers)
→ No matter what last digits they use, all blocked.

[Key Features]
• Range blocking: Block all spam variants at once
• True blocking: Calls stopped at system level, before ringing
• Up to 10 ranges, 10 million numbers total
• Blocking completes in ~12 seconds
• Permanent — works without the app running

[Don't worry]
• Numbers in your Contacts are never blocked
• Does not affect FaceTime, WhatsApp, or VoIP apps
• No data collection, no network communication
• Supports 249 countries
```

---

## 키워드 (한국어)
스팸차단, 전화차단, 보이스피싱, 스팸전화, 패턴차단, 070차단, 콜차단, 스팸필터, 스팸번호, 전화번호차단

## 키워드 (영어)
spam blocker, call blocker, spam call, block calls, phone spam, pattern block, call filter, robocall, telemarketer, unwanted calls

---

## 심사 노트 (App Review Notes)

```
This app lets users block spam calls by entering a single phone number. The app automatically calculates the matching number pattern and blocks up to 1 million numbers per slot using iOS CallKit Call Directory Extension.

Technical explanation for 10 extensions:
- iOS CallKit Call Directory Extension has a per-extension limit of approximately 1 million entries
- The app provides 10 extension slots, each capable of blocking 1 million numbers
- All 10 extensions share a single source file (NinjaBlockBase/CallDirectoryHandler.swift)
- Each extension reads its assigned prefix from App Group shared UserDefaults at reload time
- The user controls exactly which number patterns to block via the in-app interface

How blocking works:
- User enters a spam phone number (e.g., 070-8582-4444)
- The app converts it to E.164 format and extracts a 6-digit prefix (e.g., 827085)
- All numbers from 827085000000 to 827085999999 (1 million numbers) are registered with CallKit
- iOS blocks matching incoming calls at the system level, before the phone rings

Default behavior:
- On first install, all 10 slots are empty (no numbers blocked)
- Users must explicitly enter a number and confirm to activate blocking
- All blocking is user-initiated and user-controlled

Country support:
- The app supports 249 countries via an embedded E.164 country code database
- Country selection determines how local phone numbers are converted to E.164 format
- The stripLeadingZero flag handles countries where domestic numbers start with 0

Privacy:
- No network communication whatsoever
- No personal data collection
- No access to call content or contacts
- App Store privacy label: "Data Not Collected"
```

---

## App Store 프라이버시 라벨
- **데이터 수집**: 수집하지 않음 (Data Not Collected)

---

## 스크린샷 가이드

6.7인치 (iPhone 16 Pro Max) 필수, 최소 3장

### 1장: 텍스트 설명 카드
```
스팸 번호 하나만 입력하세요.
100만 개 번호를 자동으로 차단합니다.

✓ 번호 입력 → 패턴 자동 계산
✓ 12초 만에 차단 완료
✓ 벨소리도 울리지 않음
✓ 개인정보 수집 없음
```
배경: Paradise Pink (#E4455E) + 다크

### 2장: 메인 화면
- 슬롯 2~3개 활성화 상태
- "070-85XX-XXXX 100만개 차단 중" 표시

### 3장: 번호 입력 히어로 모먼트
- 전화번호 입력 상태
- 녹색 패턴 프리뷰 "070-85XX-XXXX" + "패턴 모두 차단 (1,000,000개)" 표시

### 4장 (선택): 다크모드
- 메인 화면 다크모드 버전

---

## 앱 이름 규칙
- App Store Connect 기본 이름: 30자 이내
- 부제: 30자 이내
- 키워드: 100자 이내 (쉼표 구분)
