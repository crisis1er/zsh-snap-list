# Changelog

All notable changes to this plugin are documented here.

---

## [3.1] — 2026-04-12

### Changed
- Auto-detect sudo requirement — uses `snapper` directly if user has access via ALLOW_USERS/ALLOW_GROUPS, falls back to `sudo snapper` otherwise

## [3.0] — 2026-04-12

### Changed
- Replaced `│`-based parsing with `snapper --csvout --separator '|' --no-headers list --columns` — locale-independent, immune to Snapper rendering changes
- Filters now apply on clean CSV fields (`awk -F'|'`) instead of fragile regex on Unicode borders
- Colorization uses `active` and `default` columns — green (+) = currently mounted, cyan (-) = default next boot, yellow = important=yes
- Config validation — explicit error message if snapper is not configured or config does not exist
- Summary line counts computed from CSV data
- Added `snap-list -h for options and color legend` hint after each output
- Color legend added to `-h / --help` output

## [2.0] — 2026-04-06

### Added
- Interactive menu — 3-step guided flow: config, filter, quantity
- Flag mode — direct execution with combinable flags
- `-a / --all` — display root + home in a single command with config separators
- `-i / --important` — filter important=yes snapshots only
- `-t / --type single|pre|post|pre_post` — filter by snapshot type
- `-n / --last N` — show last N snapshots
- `-h / --help` — inline help with examples
- Equivalent command shown after menu selection — teaches flags naturally
- Empty result guard — clear message when no snapshots match criteria
- Summary line adapts to filtered result

## [1.0] — 2026-04-06

### Added
- Initial release — colorized snapper snapshot listing for openSUSE Tumbleweed
- `snap-list` — colorized output: green (active), yellow (important=yes), bold (headers)
- Summary line: total, singles, pre, post, importants count
