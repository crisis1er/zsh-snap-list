# ============================================================
# zsh-snap-list — Oh My Zsh plugin for openSUSE Tumbleweed
# Colorized snapper snapshot listing with filtering and menu
# Version: 3.0 — 2026-04-12
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

    # Fetch available configs once
    local -a cfgs
    if [[ "$all_configs" == "true" ]]; then
        cfgs=($(sudo snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}'))
    else
        cfgs=("$config")
    fi

    # Guard: no snapper config found
    if [[ ${#cfgs[@]} -eq 0 ]]; then
        echo -e "${RED}No snapper configuration found.${RESET}"
        echo -e "See: https://en.opensuse.org/openSUSE:Snapper_Tutorial"
        return 1
    fi

    local multi=false
    [[ ${#cfgs[@]} -gt 1 ]] && multi=true

    for cfg in "${cfgs[@]}"; do
        # Fetch CSV — locale-independent, stable columns
        # Fields: $1=number $2=active $3=default $4=type $5=pre-number $6=date $7=description $8=userdata
        local raw_csv
        raw_csv=$(sudo snapper -c "$cfg" --csvout --separator '|' --no-headers list \
            --columns number,active,default,type,pre-number,date,description,userdata 2>/dev/null)

        if [[ -z "$raw_csv" ]]; then
            echo -e "${RED}Error: config '${cfg}' not found or no snapshots available.${RESET}"
            continue
        fi

        # Apply filters on clean CSV fields
        local data="$raw_csv"

        if [[ "$filter_important" == "true" ]]; then
            data=$(echo "$data" | awk -F'|' '$8 ~ /important=yes/')
        fi

        if [[ -n "$filter_type" ]]; then
            case "$filter_type" in
                single)   data=$(echo "$data" | awk -F'|' '$4=="single"') ;;
                pre)      data=$(echo "$data" | awk -F'|' '$4=="pre"') ;;
                post)     data=$(echo "$data" | awk -F'|' '$4=="post"') ;;
                pre_post) data=$(echo "$data" | awk -F'|' '$4=="pre" || $4=="post"') ;;
            esac
        fi

        if [[ "$filter_last" -gt 0 ]]; then
            data=$(echo "$data" | tail -n "$filter_last")
        fi

        # Config separator when displaying multiple configs
        $multi && echo -e "\n${CYAN}${BOLD}── config: ${cfg} ─────────────────────────────────────────${RESET}"

        # Header
        printf "${BOLD}%-7s %-8s %-6s %-20s %-35s %s${RESET}\n" \
            "Number" "Type" "Pre #" "Date" "Description" "Userdata"
        printf '%.0s─' {1..100}; echo

        # Empty result guard
        if [[ -z "$(echo "$data" | grep -v '^$')" ]]; then
            echo -e "${YELLOW}  No snapshots matching the selected criteria.${RESET}"
            echo ""
            continue
        fi

        # Colorize and print rows
        echo "$data" | awk -F'|' \
            -v GREEN="$GREEN" \
            -v YELLOW="$YELLOW" \
            -v CYAN="$CYAN" \
            -v RESET="$RESET" '
        {
            num=$1; act=$2; def=$3; typ=$4; pre=$5; dat=$6; dsc=$7; udat=$8

            # Build number display with marker
            marker=""
            if (def=="yes") marker="+"
            else if (act=="yes") marker="-"
            num_display = num marker

            # Determine color
            color=RESET
            if (def=="yes")                color=GREEN
            else if (act=="yes")           color=CYAN
            else if (udat~/important=yes/) color=YELLOW

            printf color "%-7s %-8s %-6s %-20s %-35s %s" RESET "\n",
                num_display, typ, pre, dat, dsc, udat
        }'

        echo ""

        # Summary from CSV data
        local total single_c pre_c post_c imp_c
        total=$(echo    "$data" | grep -c '|' 2>/dev/null || echo 0)
        single_c=$(echo "$data" | awk -F'|' '$4=="single"' | grep -c '|' || echo 0)
        pre_c=$(echo    "$data" | awk -F'|' '$4=="pre"'    | grep -c '|' || echo 0)
        post_c=$(echo   "$data" | awk -F'|' '$4=="post"'   | grep -c '|' || echo 0)
        imp_c=$(echo    "$data" | awk -F'|' '$8~/important=yes/' | grep -c '|' || echo 0)

        echo "Total: ${total} snapshots — ${single_c} singles, ${pre_c} pre, ${post_c} post, ${imp_c} important"
        echo -e "  ${CYAN}snap-list -h${RESET} for options and color legend"
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
                    echo -e "\n  ${BOLD}Color legend:${RESET}"
                    echo -e "  ${GREEN}Green (+)${RESET}   currently mounted snapshot"
                    echo -e "  ${CYAN}Cyan (-)${RESET}    default for next boot"
                    echo -e "  ${YELLOW}Yellow${RESET}      important=yes"
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

    if [[ -z "$available_configs" ]]; then
        echo -e "${RED}No snapper configuration found.${RESET}"
        echo -e "See: https://en.opensuse.org/openSUSE:Snapper_Tutorial"
        return 1
    fi

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

    # Build equivalent native snapper command for pedagogy
    local -a target_eq
    if [[ "$all_configs" == "true" ]]; then
        target_eq=($(sudo snapper list-configs 2>/dev/null | awk 'NR>2 {print $1}'))
    else
        target_eq=("$config")
    fi

    local -a snapper_cmds
    for cfg_eq in "${target_eq[@]}"; do
        local raw_cmd="sudo snapper -c ${cfg_eq} list"
        local pipes=""
        if [[ "$filter_important" == "true" ]]; then
            pipes+=' | grep "important=yes"'
        fi
        if [[ -n "$filter_type" ]]; then
            case "$filter_type" in
                single)   pipes+=' | grep "single"' ;;
                pre)      pipes+=' | grep "| pre"' ;;
                post)     pipes+=' | grep "| post"' ;;
                pre_post) pipes+=' | grep -E "pre|post"' ;;
            esac
        fi
        [[ "$filter_last" -gt 0 ]] && pipes+=" | tail -n ${filter_last}"
        snapper_cmds+=("${raw_cmd}${pipes}")
    done

    echo -e "\n${YELLOW}Without snap-list you would type :${RESET}"
    for c in "${snapper_cmds[@]}"; do
        echo -e "  ${BOLD}${c}${RESET}"
    done
    echo ""

    _snap_list_run "$config" "$all_configs" "$filter_important" "$filter_type" "$filter_last"
}
