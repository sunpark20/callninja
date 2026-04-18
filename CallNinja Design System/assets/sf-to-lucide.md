# SF Symbols → Lucide mapping

CallNinja is an iOS app and uses SF Symbols natively. In web-based design-system previews and UI kits we substitute with [Lucide](https://lucide.dev) (matches the stroke weight and avoids proprietary licensing).

| SF Symbol | Lucide equivalent | Usage in CallNinja |
|---|---|---|
| `checkmark.shield.fill` | `shield-check` (filled variant) | Slot active — 100만개 차단 중 |
| `shield.slash` | `shield-off` | Slot paused (toggle off) |
| `plus.circle` | `plus-circle` | Empty slot affordance |
| `exclamationmark.triangle.fill` | `alert-triangle` (filled) | Extension disabled warning |
| `xmark.circle.fill` | `x-circle` (filled) | Reload / App-group failure |
| `checkmark.circle.fill` | `check-circle-2` (filled) | 10/10 extensions enabled |
| `checkmark` | `check` | Country picker selection |
| `chevron.right` | `chevron-right` | Nav affordance |
| `gearshape` | `settings` | Toolbar menu |
| `magnifyingglass` | `search` | Searchable field |

Flag emoji are passed through as UTF-8 strings from `country_codes.json`; no asset needed.
