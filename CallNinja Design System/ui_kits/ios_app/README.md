# CallNinja iOS — UI Kit

A React-based clickable recreation of the real SwiftUI app. Matches the source in `callninja/CallNinja/Views/*.swift`.

## Files

- `index.html` — interactive click-thru prototype. Load this.
- `ios-frame.jsx` — iOS 17/26 device bezel + status bar + nav scaffolding.
- `components.jsx` — `CNButton`, `CNToggle`, `CNList`, `CNRow`, SF-Symbols-to-SVG icon map.
- `screens.jsx` — `OnboardingCountry`, `OnboardingExtensions`, `MainScreen`, `NumberInputSheet`, `SlotDetailSheet`, `Sheet`.

## Flow covered

1. **Onboarding · Country** — picker with `.ultraThinMaterial` selected-card, `+82 대한민국` default.
2. **Onboarding · Extensions** — "설정 열기" button increments the fake enabled counter. At 10/10 the `시작하기` CTA appears.
3. **Main** — 10 slot list, pre-seeded with 3 active slots. Tap an empty slot → number-input sheet. The **hero pattern preview** (green `070-85XX-XXXX`) appears live as you type. Tap a filled slot → detail sheet with range + delete/change.
4. **Country picker modal** — search + select.

Toolbar controls light/dark theme and a Reset that rewinds to onboarding.

## What's faithful

- Section-grouped `List` layout, 10pt internal padding, 12pt corner radii, 0.5px separators.
- `.borderedProminent` CTA is full-width at bottom of every sheet.
- Monospaced phone patterns; secondary copy exactly matches the real strings (`100만개 차단 중`, `연락처에 저장된 번호는…`).
- Toggle and progress animations mirror iOS timings.
- Dark mode uses `#000000` grouped bg (OLED) with `#1C1C1E` surfaces.

## What's simplified

- The E.164 converter is a tiny KR-only stub; the real app in `E164Converter.swift` handles all countries with leading-zero rules and exhaustive errors.
- CallKit is not reachable from the web — the "설정 열기" button just bumps a counter instead of deep-linking.
- No SlotError variants shown in the click-thru (the static preview cards cover them).
