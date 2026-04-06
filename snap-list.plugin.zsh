# ============================================================
# zsh-snap-list — Oh My Zsh plugin for openSUSE Tumbleweed
# Colorized snapper snapshot listing with filtering and menu
# ============================================================

# Disable any residual alias or function that would shadow snap-list
unalias snap-list 2>/dev/null

# ── Internal: execute snapper list with filters and colorize ─
function _snap_list_run {
    local config="$1"
    local all_configs="$2"       # true/false
    local filter_important="$3"  # true/false
    local filter_type="$4"       # single|pre|post|pre_post|""
    local filter_last="$5"       # integer or 0

    local GREEN="\033[32m" YELLOW="\033[33m" CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m"
    local RED="\033[31m"

    local -a cfgs
    if [[ "$all_configs" == "true" ]]; then
        cfgs=($(sudo snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}'))
    else
        cfgs=("$config")
    fi

    local multi=false
    [[ ${#cfgs[@]} -gt 1 ]] && multi=true

    for cfg in "${cfgs[@]}"; do
        local raw headers data

        raw=$(sudo snapper -c "$cfg" list 2>/dev/null)
        headers=$(echo "$raw" | head -2)
        data=$(echo "$raw" | tail -n +3 | grep "│")

        # Apply filters
        if [[ "$filter_important" == "true" ]]; then
            data=$(echo "$data" | grep "important=yes" || true)
        fi

        if [[ -n "$filter_type" ]]; then
            case "$filter_type" in
                single)   data=$(echo "$data" | grep -E "│ single +│"         || true) ;;
                pre)      data=$(echo "$data" | grep -E "│ pre +│"             || true) ;;
                post)     data=$(echo "$data" | grep -E "│ post +│"            || true) ;;
                pre_post) data=$(echo "$data" | grep -E "│ (pre|post) +│"      || true) ;;
            esac
        fi

        if [[ "$filter_last" -gt 0 ]]; then
            data=$(echo "$data" | tail -n "$filter_last")
        fi

        # Config separator when displaying multiple configs
        $multi && echo -e "\n${CYAN}${BOLD}── config: ${cfg} ─────────────────────────────────────────${RESET}"

        # Empty result guard
        if [[ -z "$(echo "$data" | grep -v '^$')" ]]; then
            echo "$headers" | awk 'BEGIN{BOLD="\033[1m";RESET="\033[0m"} {print BOLD $0 RESET}'
            echo -e "${YELLOW}  No snapshots matching the selected criteria.${RESET}"
            echo ""
            continue
        fi

        # Colorize output
        { echo "$headers"; echo "$data"; } | awk '
        BEGIN { GREEN="\033[32m"; YELLOW="\033[33m"; BOLD="\033[1m"; RESET="\033[0m" }
        NR <= 2          { print BOLD $0 RESET; next }
        /\*/             { print GREEN $0 RESET; next }
        /important=yes/  { print YELLOW $0 RESET; next }
        NF               { print }
        '

        # Summary line
        local total single_c pre_c post_c imp_c
        total=$(echo    "$data" | grep -c "│"             2>/dev/null || echo 0)
        single_c=$(echo "$data" | grep -cE "│ single +│"  2>/dev/null || echo 0)
        pre_c=$(echo    "$data" | grep -cE "│ pre +│"     2>/dev/null || echo 0)
        post_c=$(echo   "$data" | grep -cE "│ post +│"    2>/dev/null || echo 0)
        imp_c=$(echo    "$data" | grep -c "important=yes" 2>/dev/null || echo 0)

        echo ""
        echo "Total : ${total} snapshots — ${single_c} singles, ${pre_c} pre, ${post_c} post, ${imp_c} importants"
    done
}

# ── Main function ─────────────────────────────────────────────
function snap-list {
    local RED="\033[31m" GREEN="\033[32m" YELLOW="\033[33m"
    local CYAN="\033[36m" BOLD="\033[1m" RESET="\033[0m"

    local config="root"
    local all_configs=false
    local filter_important=false
    local filter_type=""
    local filter_last=0

    # ── Flag mode ─────────────────────────────────────────────
    if [[ $# -gt 0 ]]; then
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -a|--all)
                    all_configs=true; shift ;;
                -c|--config)
                    config="$2"; shift 2 ;;
                -i|--important)
                    filter_important=true; shift ;;
                -t|--type)
                    filter_type="$2"; shift 2 ;;
                -n|--last)
                    filter_last="$2"; shift 2 ;;
                -h|--help)
                    echo -e "${BOLD}snap-list${RESET} — colorized snapper snapshot viewer\n"
                    echo -e "  ${CYAN}snap-list${RESET}                    interactive menu"
                    echo -e "  ${CYAN}-a, --all${RESET}                    all configs (root + home)"
                    echo -e "  ${CYAN}-c, --config NAME${RESET}            specific config (default: root)"
                    echo -e "  ${CYAN}-i, --important${RESET}              important snapshots only"
                    echo -e "  ${CYAN}-t, --type single|pre|post|pre_post${RESET}  filter by type"
                    echo -e "  ${CYAN}-n, --last N${RESET}                 last N snapshots"
                    echo -e "  ${CYAN}-h, --help${RESET}                   show this help\n"
                    echo -e "  ${BOLD}Examples:${RESET}"
                    echo -e "  ${CYAN}snap-list -a -i${RESET}              all configs, important only"
                    echo -e "  ${CYAN}snap-list -n 5 -t single${RESET}     last 5 singles"
                    echo -e "  ${CYAN}snap-list -c home -i -n 5${RESET}    last 5 importants on home"
                    return 0 ;;
                *)
                    echo -e "${RED}Unknown option: $1${RESET} — use ${BOLD}snap-list -h${RESET} for help"
                    return 1 ;;
            esac
        done
        _snap_list_run "$config" "$all_configs" "$filter_important" "$filter_type" "$filter_last"
        return
    fi

    # ── Interactive menu ──────────────────────────────────────
    local available_configs has_home=false
    available_configs=$(sudo snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}' | tr '\n' ' ')
    echo "$available_configs" | grep -q "home" && has_home=true

    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${CYAN}║${RESET}${BOLD}              Snap-List — SafeITExperts                       ${RESET}${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}              Snapshot Viewer                                 ${CYAN}║${RESET}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${CYAN}║${RESET}  Replaces ${BOLD}snapper list${RESET} — no options to memorize.             ${CYAN}║${RESET}"
    echo -e "${CYAN}║${RESET}  Filter by config, type or importance in one guided step.    ${CYAN}║${RESET}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${RESET}"

    # Step 1 — Config
    echo -e "\n${BOLD}Step 1 — Config:${RESET}"
    echo -e "  ${CYAN}(r)${RESET} root         [default]"
    if $has_home; then
        echo -e "  ${CYAN}(h)${RESET} home"
        echo -e "  ${CYAN}(a)${RESET} all — root + home"
        printf "Choice [r/h/a] (default: r) : "
    else
        printf "Choice [r] (default: r) : "
    fi
    read -r cfg_choice

    case "$cfg_choice" in
        h|H) $has_home && config="home" || config="root" ;;
        a|A) $has_home && all_configs=true || config="root" ;;
        *)   config="root" ;;
    esac

    # Step 2 — Filter
    echo -e "\n${BOLD}Step 2 — Filter:${RESET}"
    echo -e "  ${CYAN}(a)${RESET}     all         — show everything [default]"
    echo -e "  ${CYAN}(i)${RESET}     important   — protected snapshots only"
    echo -e "  ${CYAN}(s)${RESET}     single      — single type only"
    echo -e "  ${CYAN}(p)${RESET}     pre/post    — paired snapshots only"
    printf "Choice [a/i/s/p] (default: a) : "
    read -r filter_choice

    case "$filter_choice" in
        i|I) filter_important=true     ;;
        s|S) filter_type="single"      ;;
        p|P) filter_type="pre_post"    ;;
        *)   ;;
    esac

    # Step 3 — Quantity
    echo -e "\n${BOLD}Step 3 — Quantity:${RESET}"
    echo -e "  ${CYAN}(enter)${RESET} all snapshots"
    echo -e "  ${CYAN}(n)${RESET}     last N snapshots"
    printf "Choice : "
    read -r qty_choice

    if [[ "$qty_choice" =~ ^[nN]$ ]]; then
        printf "How many : "
        read -r filter_last
        [[ ! "$filter_last" =~ ^[0-9]+$ ]] && filter_last=0
    fi

    # Show equivalent command
    local cmd="snap-list"
    [[ "$all_configs" == "true" ]] && cmd+=" -a" || [[ "$config" != "root" ]] && cmd+=" -c $config"
    [[ "$filter_important" == "true" ]] && cmd+=" -i"
    [[ -n "$filter_type" ]] && cmd+=" -t $filter_type"
    [[ "$filter_last" -gt 0 ]] && cmd+=" -n $filter_last"

    echo -e "\n${CYAN}→ Equivalent command : ${BOLD}${cmd}${RESET}\n"

    _snap_list_run "$config" "$all_configs" "$filter_important" "$filter_type" "$filter_last"
}
