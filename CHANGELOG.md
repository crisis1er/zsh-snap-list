# Changelog

All notable changes to this plugin are documented here.

---

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
