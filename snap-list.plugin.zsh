# ============================================================
# zsh-snap-list — Oh My Zsh plugin for openSUSE Tumbleweed
# Colorized snapper snapshot listing with summary line
# ============================================================

# Disable any residual alias that would shadow the function
unalias snap-list 2>/dev/null

# Colorized snapshot list with summary line
# Green  = active snapshot (*)
# Yellow = important=yes (protected from automatic cleanup)
# Bold   = header lines
# Summary line: total, singles, pre, post, importants
# Passes all arguments through to snapper list (e.g. snap-list -c home)
# Usage: snap-list  or  snap-list -c home
function snap-list {
    local output
    output=$(sudo snapper list "$@")

    echo "$output" | awk '
    BEGIN {
        GREEN  = "\033[32m"
        YELLOW = "\033[33m"
        BOLD   = "\033[1m"
        RESET  = "\033[0m"
    }
    NR <= 2 { print BOLD $0 RESET; next }
    /\*/             { print GREEN  $0 RESET; next }
    /important=yes/  { print YELLOW $0 RESET; next }
    { print }
    '

    local total pre post single important
    total=$(echo "$output"     | tail -n +3 | grep -c "│" || true)
    pre=$(echo "$output"       | grep -c "│ pre    │" || true)
    post=$(echo "$output"      | grep -c "│ post   │" || true)
    single=$(echo "$output"    | grep -c "│ single │" || true)
    important=$(echo "$output" | grep -c "important=yes" || true)
    echo ""
    echo "Total : ${total} snapshots — ${single} singles, ${pre} pre, ${post} post, ${important} importants"
}
