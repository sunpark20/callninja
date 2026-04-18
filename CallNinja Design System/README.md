# CallNinja (콜닌자) Design System

An iOS call-blocking app. Users enter one spam phone number; CallNinja silently blocks one million numbers in that pattern range. The brand is a ninja — sharp, fast, precise, invisible.

## Sources referenced

- **Codebase:** `callninja/` (local mount). SwiftUI + CallKit, iOS 16+. Entry points: `CallNinjaApp.swift`, `ContentView.swift`, `Views/*`. Core models: `BlockSlot`, `CountryCode`, `E164Converter`. 10 CallDirectoryExtensions (`NinjaBlock00`–`NinjaBlock09`) share `NinjaBlockBase/CallDirectoryHandler.swift`.
- **Color trend brief:** `uploads/2026_color_trend.md` (Pantone / NCS / Coloro 2026). The accent **Paradise Pink `#E4455E`** (Pantone 17-1755 TCX, Tropic Tonalities) was chosen to avoid the generic "spam-block blue" and stand out on the iOS home screen. Supporting hero green is ninja-shuriken green, used only for the pattern-preview moment.
- **Project rules:** `callninja/CLAUDE.md` — K=1M blocks per extension, N=10 extensions, 6-digit wildcard, Korean primary, SwiftUI system components only.

## Product surfaces

Only **one** product: the iOS app. Two flows only:
1. **Onboarding** — country picker → CallKit extension activation (10 toggles in Settings).
2. **Main** — 10 slot list. Tap empty slot → number input sheet with live pattern preview. Tap filled slot → detail.

## Design ethos

- **System-first SwiftUI.** No heavy custom chrome. `List` with inset-grouped style, `Form`, `.borderedProminent` buttons, system Toggles.
- **Monospaced phone numbers.** `.font(.body.monospaced())` for every digit pattern. The system font handles everything else (Korean + Latin).
- **One satisfying moment.** When the pattern `070-85XX-XXXX` resolves, it appears large, monospaced, green, in a softly tinted card. Everything else is restrained so this hero moment lands.
- **Dark mode first-class.** Every token has a dark counterpart. Accent pink is desaturated slightly in dark for less vibration.

---

## Content fundamentals

### Voice
Calm, precise, operational. Short imperative sentences. No exclamation, no marketing gloss, no emoji (flags excepted — they're data, not decoration). Korean primary; English exists only where it's semantically necessary (country English names in search).

### Tone
Reads like a utility, not a consumer app. "스팸 전화에서 본 번호를 그대로 입력하세요" — just tell the user what to do. Explanations come in secondary text in `.caption` + `.secondary` foreground.

### Addressing the user
Polite `-요`/`-세요` forms, not `-해라` or `-합니다`. The app speaks **to** you, not about itself. Examples from the product:
- "차단할 번호를 입력하세요" (Enter the number to block)
- "설정에서 10개 항목을 켜주세요" (Please turn on 10 items in Settings)
- "연락처에 저장된 번호는 차단되지 않습니다." (Numbers saved in Contacts are not blocked.)
- "나라를 변경하면 모든 차단 설정이 초기화됩니다." (Changing country resets all blocks.)

### Numbers & units
- Always format with thousands: "1,000,000개", "100만개". Never "1M" in Korean UI.
- Phone patterns always monospaced, always with X for wildcard digits: `070-85XX-XXXX`.
- Slot index is 1-based in copy ("슬롯 1"), 0-based in data (slot.id).

### Error messages
Plain-language, action-oriented. Every error tells the user what to do next:
- "설정에서 켜주세요" (Please turn it on in Settings)
- "앱을 재설치해 주세요" (Please reinstall the app)
- "기기를 재시작해 보세요" (Try restarting the device)

### Emoji / symbols
- Country flag emoji used as data (next to country name). Nothing else.
- Status uses SF Symbols, not emoji: `checkmark.shield.fill`, `shield.slash`, `exclamationmark.triangle.fill`, `xmark.circle.fill`, `plus.circle`, `gearshape`.

---

## Visual foundations

### Color
- **Background:** iOS system grouped background. Light `#F2F2F7`, dark `#000000`. List rows are `systemBackground` in light, `secondarySystemGroupedBackground` in dark.
- **Accent (primary):** `#E4455E` Paradise Pink. Used for `.tint` — bordered-prominent buttons, toggles when on, navigation links. In dark mode: `#EB6478` (slightly lifted).
- **Hero green:** `#34C759` (system green). Used exclusively for the pattern preview and "차단 중" confirmations. The 10% opacity tint `#34C75919` is the pattern card background.
- **Warnings:** `#FF9F0A` (system orange) for partial-activation states. **Errors:** `#FF3B30` (system red) for reload failures.
- **Neutrals:** iOS system grays. Secondary text is `.secondary` (automatic light/dark).

### Type
- **System SF Pro / SF Pro Rounded** — automatic. We never override the font family.
- **SF Mono** for all phone digits and patterns. `.font(.body.monospaced())`, `.font(.title.monospaced().bold())` for the hero preview, `.caption.monospaced()` for ranges.
- **Sizes & roles:**
  - `largeTitle` — navigation title on onboarding ("콜닌자 설정").
  - `title2.bold` — modal headlines.
  - `title.monospaced().bold()` — hero pattern preview (the one moment).
  - `headline` — section headlines in forms.
  - `body` / `body.monospaced()` — list rows, slot patterns.
  - `subheadline` / `.secondary` — explanatory text.
  - `caption` — status badges under each slot.

### Spacing
- 8pt base grid. Stack spacings: 8, 12, 16, 24. Padding inside cards is 16; navigation content inset follows system defaults.
- Slot row height ~56pt. Hero preview card has 16pt internal padding and ~24pt bottom gap to the next element.

### Corner radii
- **12** — cards, text field background, prominent buttons (system default). Used everywhere.
- **10** — list cell internal badges.
- **Full / capsule** — Toggle, ProgressView (system).
- No custom squircles; all system-shaped.

### Shadows & elevation
- No custom shadows. Elevation comes from grouped-list backgrounds and `.ultraThinMaterial`.
- The country-selected button in onboarding uses `.ultraThinMaterial` + RoundedRectangle(12) — glassy, light. That's the only translucency layer in the app.

### Borders
- None custom. Separators come from `List` insets. `.borderedProminent` button supplies its own fill.

### Backgrounds
- Flat. No gradients, no photography, no pattern textures. Content sits on the iOS grouped background.
- Dark mode is pure black `#000000` (OLED-friendly), not iOS-13 charcoal.

### Animation
- System defaults only. Sheet presentation (spring). `withAnimation` implicit on state changes. No custom curves, no bounces we author.
- One deliberate moment: the pattern preview fades/scales in when the input resolves. Keep it a single `.transition(.scale.combined(with: .opacity))` — don't over-engineer.

### Hover / press states
- Pure iOS: `Button(.plain)` with row `.contentShape(Rectangle())` gives the subtle row highlight on press. `.borderedProminent` dims on press.
- No custom hover (this is iOS).

### Transparency & blur
- `.ultraThinMaterial` on exactly one surface: onboarding country-selected card. Everywhere else is opaque.

### Imagery
- No photography or illustration in the product UI.
- The app icon and marketing material use the **ninja/shuriken** motif combined with the phone/shield silhouette. Bold black + Paradise Pink, recognizable at 29pt.

### Layout rules
- Fixed navigation bar at top. Primary CTA always at the **bottom** of the sheet, full-width, `.controlSize(.large)`.
- Inside `List` sections, labels are left-aligned; values and chevrons are right-aligned via `Spacer()`.
- Sheets are always titled and always have a `취소`/`닫기` `cancellationAction`.

---

## Iconography

- **SF Symbols only.** This is an Apple-first app and there are no raster or SVG icons in the repo. We never hand-draw icon SVGs.
- The specific set actually used in the codebase:
  - `checkmark.shield.fill` — slot active & protecting (green).
  - `shield.slash` — slot disabled (secondary).
  - `plus.circle` — empty slot prompt.
  - `exclamationmark.triangle.fill` — extension disabled warning (yellow).
  - `xmark.circle.fill` — reload / app-group failure (red).
  - `checkmark.circle.fill` — 10/10 activation complete (green).
  - `checkmark` — country picker selection (blue, system).
  - `chevron.right` — navigation affordance.
  - `gearshape` — toolbar menu.
- **In HTML / web previews of this design system** we substitute with **Lucide** (CDN, `lucide-static`), which matches SF Symbols' stroke weight and duotone-free style. The mapping is documented in `assets/sf-to-lucide.md`.
- **Flag emoji** are the only other iconographic element. They come from the OS; we pass them through as strings from `country_codes.json`.
- **No emoji** anywhere else. No Unicode decorative glyphs.

---

## Index (files in this design system)

- `README.md` — this file. Start here.
- `colors_and_type.css` — CSS custom properties for light + dark. Base tokens (fg, bg, accent) + semantic roles (h1, body, caption, mono).
- `SKILL.md` — Claude Skill entry point.
- `assets/` — logos, app icons, marketing imagery, SF-to-Lucide icon map.
- `preview/` — design-system cards (rendered in the Design System tab).
- `ui_kits/ios_app/` — SwiftUI-accurate React recreation of the iOS app. `index.html` is the click-through prototype.

## Known substitutions & flags for the user

- **Fonts:** We use system SF Pro / SF Mono in the real app. In web previews we fall back to **Inter** + **JetBrains Mono** from Google Fonts (best free match to SF metrics). If you want exact SF rendering in exports, provide the SF font files and we'll swap them in.
- **Icons on web:** Lucide CDN substitutes SF Symbols. See `assets/sf-to-lucide.md`.
- **Ninja / shuriken mark:** the repo has no brand mark yet. We're shipping a placeholder mark (SVG shuriken-phone lockup) in `assets/logo.svg`. Confirm direction or provide the final mark.
