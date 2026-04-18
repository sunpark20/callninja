---
name: callninja-design
description: Use this skill to generate well-branded interfaces and assets for CallNinja (콜닌자), either for production or throwaway prototypes/mocks/etc. Contains essential design guidelines, colors, type, fonts, assets, and UI kit components for prototyping.
user-invocable: true
---

Read the README.md file within this skill, and explore the other available files.

If creating visual artifacts (slides, mocks, throwaway prototypes, etc), copy assets out and create static HTML files for the user to view. If working on production code, you can copy assets and read the rules here to become an expert in designing with this brand.

If the user invokes this skill without any other guidance, ask them what they want to build or design, ask some questions, and act as an expert designer who outputs HTML artifacts _or_ production code, depending on the need.

Key files:
- `README.md` — full brand + content + visual foundations
- `colors_and_type.css` — drop-in CSS tokens (light + dark)
- `assets/logo.svg`, `assets/logo-lockup.svg` — brand marks (placeholder, confirm with user)
- `assets/sf-to-lucide.md` — icon substitution map for web
- `ui_kits/ios_app/` — faithful React recreation of the real SwiftUI app; use components as reference
- `preview/*.html` — design-system specimen cards
