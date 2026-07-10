#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
#  LUMEXA GAME DASHBOARD v6.1 — NON-ROOT GAMING TOOLKIT
#  Truthful Android performance & gaming toolkit for Termux (no root needed)
#
#  WHAT CHANGED FROM v6.0:
#   - Menu system: input validation on every prompt (no crash on bad input),
#     a consistent "Back to Main Menu" affordance on every screen, and a
#     shared screen_header()/press_any_key() helper to cut duplicated code.
#   - CPU usage is now sampled WITHOUT blocking sleep: it diffs /proc/stat
#     against the previous refresh cycle's snapshot instead of sleeping
#     0.25s inside every single collection call. Faster, still 100% real
#     (the very first frame of a session shows N/A until a second sample
#     exists to diff against — that's the one honest tradeoff).
#   - Live Monitor now shows every metric this device exposes: CPU governor,
#     RAM cached/buffers, battery health/voltage/current (if readable), and
#     a best-effort CPU temperature read from /sys/class/thermal (falls back
#     to N/A on devices that don't expose a cpu-labeled thermal zone).
#   - Game Mode gained real, non-root actions: clearing Termux's own tmp
#     directory and running `sync` to flush the filesystem cache — both
#     genuinely non-root-safe and neither claims an FPS or GPU boost.
#   - Device Health now prints a short, rule-based recommendations list
#     (e.g. "free up storage", "let the device cool down") derived only
#     from the ratings already shown, not a separate invented metric.
#   - Performance History now stores actual past SESSIONS (not just
#     lifetime maxes): duration, highest temp, lowest ping, highest RAM,
#     and average performance score per session, in a small CSV.
#   - Export Report can now save TXT, CSV, or both, and includes every
#     collected metric plus a timestamp, not just a subset.
#   - Performance Score now weighs RAM%, Storage%, Temperature, Ping, and
#     CPU frequency headroom (current vs. max, from cpufreq) instead of
#     CPU usage — this also removes the score's dependency on the blocking
#     CPU-usage sample, keeping every refresh fast.
# ==============================================================================

# ---------------------------------------------------------------------------
# COLORS
# ---------------------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
LOG_DIR="$HOME/lumexa_logs"
LOG_FILE="$LOG_DIR/lumexa_$(date +%Y-%m-%d).csv"
STATS_FILE="$LOG_DIR/lifetime_stats.conf"
SESSIONS_FILE="$LOG_DIR/sessions_history.csv"
REPORTS_DIR="$LOG_DIR/reports"
REFRESH_INTERVAL=2
GAME_MODE_REFRESH_INTERVAL=6
BAR_WIDTH=24
HISTORY_LEN=30

# ---------------------------------------------------------------------------
# CPU USAGE SAMPLING STATE
# CPU usage is computed by diffing /proc/stat against the PREVIOUS refresh
# cycle instead of sleeping inside a single call — see get_cpu_usage_percent.
# ---------------------------------------------------------------------------
PREV_CPU_STAT_LINE=""

# ---------------------------------------------------------------------------
# SESSION TRACKER STATE (persists across loop iterations)
# ---------------------------------------------------------------------------
SESSION_START_EPOCH=$(date +%s)
HIGHEST_TEMP="0"
LOWEST_PING=""
HIGHEST_RAM_USED_MB=0
LOWEST_FREE_RAM_MB=""
GAME_MODE=0

# Running sums used to compute session averages (ping/CPU/score) honestly.
PING_SUM=0; PING_SAMPLES=0
CPU_SUM=0;  CPU_SAMPLES=0
PERF_SUM=0; PERF_SAMPLES=0

# ---------------------------------------------------------------------------
# LIFETIME STATS (persisted across runs in $STATS_FILE)
# ---------------------------------------------------------------------------
LIFETIME_MAX_RAM_MB=0
LIFETIME_MAX_TEMP="0"
LIFETIME_LONGEST_SESSION_SEC=0

# ---------------------------------------------------------------------------
# ROLLING GRAPH HISTORY (last $HISTORY_LEN samples each)
# ---------------------------------------------------------------------------
RAM_HISTORY=()
CPU_HISTORY=()
TEMP_HISTORY=()
PING_HISTORY=()

# ---------------------------------------------------------------------------
# KNOWN GAME PACKAGES (package name -> display name)
# Used only for the Game Detector; not exhaustive, easy to extend.
# ---------------------------------------------------------------------------
declare -A GAME_PACKAGES=(
    ["com.roblox.client"]="Roblox"
    ["com.mobile.legends"]="Mobile Legends: Bang Bang"
    ["com.activision.callofduty.shooter"]="Call of Duty: Mobile"
    ["com.tencent.ig"]="PUBG Mobile"
    ["com.pubg.imobile"]="PUBG Mobile (BGMI/alt build)"
    ["com.dts.freefireth"]="Free Fire"
    ["com.dts.freefiremax"]="Free Fire MAX"
)

# ---------------------------------------------------------------------------
# FUTURE-READY MODULE REGISTRY (v7.0+)
# Not implemented in v6.1 — documented here so new screens plug into the
# existing menu/collection pattern instead of needing another refactor:
#   - Benchmark Mode:      would reuse collect_all_metrics() + a fixed-
#                           duration sampling loop; add as screen_benchmark().
#   - Floating Sidebar:    a Termux:Widget/Float launcher wrapping a slim
#                           render function reusing render_live_monitor_frame.
#   - Android App version: collection functions (get_*_info) are already
#                           pure data producers with no UI coupling, so a
#                           future Kotlin/Compose front-end could call the
#                           same shell functions via `termux-exec` or port
#                           them 1:1 without touching this file's UI layer.
#   - Analytics Dashboard: SESSIONS_FILE/LOG_FILE are already CSV, so a
#                           future analytics screen just needs a new
#                           screen_analytics() that reads and aggregates
#                           them — no changes to logging needed.
# ---------------------------------------------------------------------------

# ==============================================================================
# UTILITY FUNCTIONS
# ==============================================================================

draw_line() {
    echo -e "${CYAN}══════════════════════════════════════════════════════════${RESET}"
}

# Clears the screen with a fallback for the rare shell that lacks `clear`
# (e.g. a stripped-down busybox). Never lets a missing command crash the UI.
screen_clear() {
    if command -v clear >/dev/null 2>&1; then
        clear
    else
        printf '\033[2J\033[H'
    fi
}

# Shared header used by every screen: clear + cyber-style double border +
# centered title. Cuts the clear/draw_line/echo/draw_line block that used to
# be repeated at the top of every screen_* function.
screen_header() {
    local title="$1"
    screen_clear
    local left_pad=$(( (60 - ${#title}) / 2 ))
    local right_pad=$(( 60 - ${#title} - left_pad ))
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${RESET}"
    printf "${CYAN}║${RESET}%*s" "$left_pad" ""
    printf "%b" "${YELLOW}${BOLD}${title}${RESET}"
    printf "%*s${CYAN}║${RESET}\n" "$right_pad" ""
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${RESET}"
}

# Shared footer/prompt used by every non-looping screen. Any key returns to
# the menu; this is the "Back" affordance requested for every submenu.
press_any_key() {
    draw_line
    echo -e "  ${DIM}[Any key] Back to Main Menu${RESET}"
    read -n 1 -s -r -p ""
}

# Lightweight loading animation for actions that take a moment (measuring
# network, clearing files, etc). Purely cosmetic — never used to mask a
# missing real measurement.
loading_anim() {
    local msg="$1" duration="${2:-1}"
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local end=$((SECONDS + duration))
    local i=0
    while [ "$SECONDS" -lt "$end" ]; do
        printf "\r  %s %s" "${frames[$((i % 10))]}" "$msg"
        i=$((i+1))
        sleep 0.08
    done
    printf "\r  ${GREEN}✔${RESET} %s\n" "$msg"
}

section_header() {
    echo -e "${CYAN}┌─${RESET} ${WHITE}${BOLD}$1${RESET}"
}

# Renders a colored unicode progress bar for a 0-100 percentage.
# Usage: draw_bar <percent>
draw_bar() {
    local percent="$1"
    [ -z "$percent" ] && percent=0
    case "$percent" in ''|*[!0-9]*) percent=0 ;; esac
    [ "$percent" -gt 100 ] && percent=100

    local filled=$(( percent * BAR_WIDTH / 100 ))
    local empty=$(( BAR_WIDTH - filled ))

    local color=$GREEN
    if [ "$percent" -ge 85 ]; then color=$RED
    elif [ "$percent" -ge 60 ]; then color=$YELLOW
    fi

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    printf "%b%s%b %3s%%\n" "$color" "$bar" "$RESET" "$percent"
}

# Prints an aligned "N/A" styled line when a metric is unreadable on this
# device. $1 = label, $2 = optional custom reason, $3 = optional column
# width to match the surrounding section (defaults to 12, the width used by
# most dashboard sections; the Network Analyzer screen passes 16).
na_line() {
    local label reason width
    width="${3:-12}"
    label=$(printf "%-${width}s" "$1")
    reason="${2:-not exposed on this device without root}"
    echo -e "  ${label}: ${DIM}N/A (${reason})${RESET}"
}

# Appends a value to a rolling-history array (by name, via nameref) and
# trims it to $HISTORY_LEN so graphs stay a fixed, bounded width.
# Usage: push_history HISTORY_ARRAY_NAME value
push_history() {
    local -n _hist="$1"
    local val="$2"
    [ -z "$val" ] && return
    _hist+=("$val")
    if [ "${#_hist[@]}" -gt "$HISTORY_LEN" ]; then
        _hist=("${_hist[@]:1}")
    fi
}

# Renders a rolling-history array as a Unicode block sparkline scaled
# between $2 (min) and $3 (max). Missing samples render as a space so gaps
# are visible instead of silently interpolated.
# Usage: sparkline HISTORY_ARRAY_NAME min max
sparkline() {
    local -n _hist="$1"
    local min="$2" max="$3"
    # Array of whole glyphs, not a single string sliced by index — slicing a
    # multibyte Unicode string with ${str:n:1} corrupts characters unless
    # the locale is UTF-8, which isn't guaranteed on every Termux setup.
    local -a blocks=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
    local out="" v level

    if [ "${#_hist[@]}" -eq 0 ]; then
        echo "(no samples yet)"
        return
    fi

    for v in "${_hist[@]}"; do
        level=$(awk -v v="$v" -v mn="$min" -v mx="$max" 'BEGIN{
            if (mx<=mn) { print 0; exit }
            p=(v-mn)/(mx-mn); if (p<0) p=0; if (p>1) p=1;
            printf "%d", (p*7)+0.5
        }')
        out+="${blocks[$level]}"
    done
    echo "$out"
}

human_uptime() {
    if command -v uptime >/dev/null 2>&1 && uptime -p >/dev/null 2>&1; then
        uptime -p | sed 's/^up //'
    elif [ -r /proc/uptime ]; then
        local secs
        secs=$(awk '{print int($1)}' /proc/uptime)
        printf '%dh %dm\n' $((secs/3600)) $(((secs%3600)/60))
    else
        echo "N/A"
    fi
}

# ==============================================================================
# DATA COLLECTION — SYSTEM INFO
# ==============================================================================

get_system_info() {
    MODEL=$(getprop ro.product.model 2>/dev/null); MODEL=${MODEL:-N/A}
    MANUFACTURER=$(getprop ro.product.manufacturer 2>/dev/null); MANUFACTURER=${MANUFACTURER:-N/A}
    ANDROID_VER=$(getprop ro.build.version.release 2>/dev/null); ANDROID_VER=${ANDROID_VER:-N/A}
    SDK_VER=$(getprop ro.build.version.sdk 2>/dev/null); SDK_VER=${SDK_VER:-N/A}
    KERNEL_VER=$(uname -r 2>/dev/null); KERNEL_VER=${KERNEL_VER:-N/A}
    ARCH=$(uname -m 2>/dev/null); ARCH=${ARCH:-N/A}
    UPTIME_STR=$(human_uptime)
}

# ==============================================================================
# DATA COLLECTION — CPU
# ==============================================================================

# Computes CPU usage % by diffing the current /proc/stat snapshot against
# the one from the PREVIOUS call, instead of sleeping inside this function.
# This makes every refresh cycle faster with zero fake data: the tradeoff is
# that the very first call of a session has no prior snapshot to diff
# against, so it honestly returns "" (N/A) for that one frame only.
get_cpu_usage_percent() {
    if [ ! -r /proc/stat ]; then echo ""; return; fi

    local line2
    line2=$(head -n1 /proc/stat)

    if [ -z "$PREV_CPU_STAT_LINE" ]; then
        PREV_CPU_STAT_LINE="$line2"
        echo ""
        return
    fi

    local line1="$PREV_CPU_STAT_LINE"
    PREV_CPU_STAT_LINE="$line2"

    # Trailing "_rest" soaks up any extra kernel-version-specific fields
    # (e.g. guest, guest_nice) so they don't get glued onto st1/st2.
    local u1 n1 s1 i1 wa1 hi1 si1 st1 _rest
    local u2 n2 s2 i2 wa2 hi2 si2 st2
    read -r _ u1 n1 s1 i1 wa1 hi1 si1 st1 _rest <<< "$line1"
    read -r _ u2 n2 s2 i2 wa2 hi2 si2 st2 _rest <<< "$line2"

    local prev_idle=$(( i1 + wa1 ))
    local idle=$(( i2 + wa2 ))
    local prev_total=$(( u1+n1+s1+i1+wa1+hi1+si1+st1 ))
    local total=$(( u2+n2+s2+i2+wa2+hi2+si2+st2 ))
    local totald=$(( total - prev_total ))
    local idled=$(( idle - prev_idle ))

    if [ "$totald" -le 0 ]; then echo ""; return; fi
    echo $(( (1000 * (totald - idled) / totald + 5) / 10 ))
}

get_cpu_info() {
    CPU_CORES=$(nproc 2>/dev/null); CPU_CORES=${CPU_CORES:-N/A}
    CPU_USAGE=$(get_cpu_usage_percent)

    if [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq ]; then
        local freq_khz
        freq_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null)
        if [ -n "$freq_khz" ]; then
            CPU_FREQ_MHZ=$(( freq_khz / 1000 ))
        fi
    fi

    if [ -r /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq ]; then
        local max_khz
        max_khz=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)
        if [ -n "$max_khz" ]; then
            CPU_FREQ_MAX_MHZ=$(( max_khz / 1000 ))
        fi
    fi

    if [ -r /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
        CPU_GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    fi

    if [ -r /proc/loadavg ]; then
        LOAD_AVG=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
    fi
}

# Best-effort CPU temperature: scans /sys/class/thermal/thermal_zone*/type
# for a zone labeled something CPU-ish (naming varies wildly by vendor —
# "cpu", "cpu-0-0", "cpuss-0", etc). Many stock ROMs don't expose this to a
# non-root app at all, in which case CPU_TEMP_C is simply left unset.
get_cpu_temp() {
    CPU_TEMP_C=""
    local zone_dir type_file temp_file type_val raw
    for zone_dir in /sys/class/thermal/thermal_zone*; do
        [ -d "$zone_dir" ] || continue
        type_file="$zone_dir/type"
        temp_file="$zone_dir/temp"
        [ -r "$type_file" ] || continue
        [ -r "$temp_file" ] || continue
        type_val=$(cat "$type_file" 2>/dev/null)
        if echo "$type_val" | grep -qi "cpu"; then
            raw=$(cat "$temp_file" 2>/dev/null)
            [ -z "$raw" ] && continue
            # Most zones report millidegrees C; a few report decidegrees.
            if [ "$raw" -gt 1000 ] 2>/dev/null; then
                CPU_TEMP_C=$(awk -v t="$raw" 'BEGIN{printf "%.1f", t/1000}')
            else
                CPU_TEMP_C=$(awk -v t="$raw" 'BEGIN{printf "%.1f", t/10}')
            fi
            return
        fi
    done
}

# ==============================================================================
# DATA COLLECTION — RAM
# ==============================================================================

get_ram_info() {
    if [ ! -r /proc/meminfo ]; then return; fi

    local mem_total_kb mem_free_kb mem_avail_kb buffers_kb cached_kb
    mem_total_kb=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
    mem_free_kb=$(awk '/^MemFree:/ {print $2}' /proc/meminfo)
    mem_avail_kb=$(awk '/^MemAvailable:/ {print $2}' /proc/meminfo)
    buffers_kb=$(awk '/^Buffers:/ {print $2}' /proc/meminfo)
    cached_kb=$(awk '/^Cached:/ {print $2}' /proc/meminfo)

    RAM_TOTAL_MB=$(( mem_total_kb / 1024 ))
    RAM_FREE_MB=$(( mem_free_kb / 1024 ))
    RAM_AVAIL_MB=$(( mem_avail_kb / 1024 ))
    RAM_BUFFERS_MB=$(( buffers_kb / 1024 ))
    RAM_CACHED_MB=$(( cached_kb / 1024 ))
    RAM_USED_MB=$(( RAM_TOTAL_MB - RAM_AVAIL_MB ))
    [ "$RAM_USED_MB" -lt 0 ] && RAM_USED_MB=0

    if [ "$RAM_TOTAL_MB" -gt 0 ]; then
        RAM_PERCENT=$(( RAM_USED_MB * 100 / RAM_TOTAL_MB ))
    else
        RAM_PERCENT=0
    fi
}

# ==============================================================================
# DATA COLLECTION — BATTERY
# ==============================================================================

# Different vendors expose the battery power_supply node under different
# names. Try the common ones and use whichever is readable.
find_battery_path() {
    local candidates=(
        /sys/class/power_supply/battery
        /sys/class/power_supply/bms
        /sys/class/power_supply/BAT0
    )
    local c
    for c in "${candidates[@]}"; do
        if [ -d "$c" ]; then echo "$c"; return; fi
    done
    echo ""
}

get_battery_info() {
    local bp
    bp=$(find_battery_path)
    BATTERY_PATH="$bp"

    if [ -z "$bp" ]; then return; fi

    [ -r "$bp/capacity" ] && BATTERY_PERCENT=$(cat "$bp/capacity" 2>/dev/null)
    [ -r "$bp/status" ] && BATTERY_STATUS=$(cat "$bp/status" 2>/dev/null)
    [ -r "$bp/health" ] && BATTERY_HEALTH=$(cat "$bp/health" 2>/dev/null)

    if [ -r "$bp/temp" ]; then
        local raw_temp
        raw_temp=$(cat "$bp/temp" 2>/dev/null)
        if [ -n "$raw_temp" ]; then
            BATTERY_TEMP_C=$(awk -v t="$raw_temp" 'BEGIN{printf "%.1f", t/10}')
            BATTERY_TEMP_RAW="$raw_temp"
        fi
    fi

    if [ -r "$bp/voltage_now" ]; then
        local raw_volt
        raw_volt=$(cat "$bp/voltage_now" 2>/dev/null)
        if [ -n "$raw_volt" ] && [ "$raw_volt" -gt 1000000 ] 2>/dev/null; then
            BATTERY_VOLTAGE_V=$(awk -v v="$raw_volt" 'BEGIN{printf "%.2f", v/1000000}')
        elif [ -n "$raw_volt" ]; then
            BATTERY_VOLTAGE_V=$(awk -v v="$raw_volt" 'BEGIN{printf "%.2f", v/1000}')
        fi
    fi

    if [ -r "$bp/current_now" ]; then
        local raw_cur
        raw_cur=$(cat "$bp/current_now" 2>/dev/null)
        if [ -n "$raw_cur" ]; then
            # Reported in microamps on most kernels; a few report milliamps
            # directly. Values over 100000 are almost certainly microamps.
            if awk -v c="$raw_cur" 'BEGIN{exit !((c<0?-c:c) > 100000)}'; then
                BATTERY_CURRENT_MA=$(awk -v c="$raw_cur" 'BEGIN{printf "%.0f", c/1000}')
            else
                BATTERY_CURRENT_MA="$raw_cur"
            fi
        fi
    fi
}

# ==============================================================================
# DATA COLLECTION — STORAGE
# ==============================================================================

get_storage_info() {
    if ! command -v df >/dev/null 2>&1; then return; fi
    local line
    line=$(df -k "$HOME" 2>/dev/null | tail -n1)
    if [ -z "$line" ]; then return; fi

    local total_kb used_kb avail_kb
    total_kb=$(echo "$line" | awk '{print $2}')
    used_kb=$(echo "$line" | awk '{print $3}')
    avail_kb=$(echo "$line" | awk '{print $4}')

    STORAGE_TOTAL_GB=$(awk -v k="$total_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
    STORAGE_USED_GB=$(awk -v k="$used_kb" 'BEGIN{printf "%.1f", k/1024/1024}')
    STORAGE_FREE_GB=$(awk -v k="$avail_kb" 'BEGIN{printf "%.1f", k/1024/1024}')

    if [ -n "$total_kb" ] && [ "$total_kb" -gt 0 ] 2>/dev/null; then
        STORAGE_PERCENT=$(( used_kb * 100 / total_kb ))
    fi
}

# ==============================================================================
# DATA COLLECTION — NETWORK
# ==============================================================================

get_network_info() {
    # WiFi / mobile interface state (read-only, works without root)
    if command -v ip >/dev/null 2>&1; then
        if ip link show wlan0 2>/dev/null | grep -q "state UP"; then
            WIFI_STATUS="Connected"
        else
            WIFI_STATUS="Disconnected"
        fi

        local rmnet_up
        rmnet_up=$(ip link show 2>/dev/null | grep -E "rmnet|ccmni|rev_rmnet" | grep -c "state UP")
        if [ "${rmnet_up:-0}" -gt 0 ]; then
            MOBILE_DATA_STATUS="Connected"
        else
            MOBILE_DATA_STATUS="Disconnected/N-A"
        fi

        CURRENT_IP=$(ip route get 8.8.8.8 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i=="src") print $(i+1)}')
    fi

    # Ping: 3 packets to a stable public resolver, measure avg RTT + loss
    if command -v ping >/dev/null 2>&1; then
        local ping_out
        ping_out=$(ping -c 3 -W 1 8.8.8.8 2>/dev/null)
        if [ -n "$ping_out" ]; then
            PING_MS=$(echo "$ping_out" | awk -F'/' '/rtt|round-trip/ {print $5}' | cut -d. -f1)
            PACKET_LOSS=$(echo "$ping_out" | awk -F',' '/packet loss/ {print $3}' | grep -oE '[0-9]+%')
        fi
    fi

    if [ -n "$PING_MS" ]; then
        INTERNET_STATUS="Online"
    else
        INTERNET_STATUS="Offline"
    fi

    # DNS lookup timing (best-effort, uses whatever resolver tool exists)
    if command -v getent >/dev/null 2>&1; then
        local t1 t2
        t1=$(date +%s%3N 2>/dev/null)
        getent hosts google.com >/dev/null 2>&1
        t2=$(date +%s%3N 2>/dev/null)
        if [ -n "$t1" ] && [ -n "$t2" ]; then
            DNS_MS=$(( t2 - t1 ))
        fi
    fi
}

# ==============================================================================
# NETWORK ANALYZER — EXTENDED (type, signal strength, stability score)
# Signal strength and precise network type require Termux:API (a separate
# companion app). If it's not installed, those two fields honestly show N/A
# instead of guessing.
# ==============================================================================

get_network_extra() {
    NETWORK_TYPE="N/A"
    if [ "$WIFI_STATUS" = "Connected" ]; then
        NETWORK_TYPE="WiFi"
    elif [ "$MOBILE_DATA_STATUS" = "Connected" ]; then
        NETWORK_TYPE="Mobile Data"
    fi

    SIGNAL_STRENGTH=""
    SIGNAL_SOURCE=""
    if command -v termux-wifi-connectioninfo >/dev/null 2>&1 && [ "$NETWORK_TYPE" = "WiFi" ]; then
        local wifi_json rssi
        wifi_json=$(termux-wifi-connectioninfo 2>/dev/null)
        rssi=$(echo "$wifi_json" | grep -oE '"rssi":[[:space:]]*-?[0-9]+' | grep -oE '\-?[0-9]+')
        if [ -n "$rssi" ]; then
            SIGNAL_STRENGTH="${rssi} dBm"
            SIGNAL_SOURCE="Termux:API WiFi"
        fi
    elif command -v termux-telephony-signalstrength >/dev/null 2>&1 && [ "$NETWORK_TYPE" = "Mobile Data" ]; then
        local tel_json dbm
        tel_json=$(termux-telephony-signalstrength 2>/dev/null)
        dbm=$(echo "$tel_json" | grep -oE '"dbm":[[:space:]]*-?[0-9]+' | grep -oE '\-?[0-9]+')
        if [ -n "$dbm" ]; then
            SIGNAL_STRENGTH="${dbm} dBm"
            SIGNAL_SOURCE="Termux:API Telephony"
        fi
    fi

    # Connection Stability Score (0-100): measured from real ping samples
    # over 5 packets — combines packet loss (heavily weighted) and jitter.
    # If ping is unreachable, there is nothing to score, so it stays N/A.
    STABILITY_SCORE=""
    if command -v ping >/dev/null 2>&1; then
        local stab_out loss times avg mdev
        stab_out=$(ping -c 5 -W 1 8.8.8.8 2>/dev/null)
        if [ -n "$stab_out" ]; then
            loss=$(echo "$stab_out" | awk -F',' '/packet loss/ {print $3}' | grep -oE '[0-9]+' | head -n1)
            mdev=$(echo "$stab_out" | awk -F'/' '/rtt|round-trip/ {print $7}' | cut -d. -f1)
            [ -z "$loss" ] && loss=0
            [ -z "$mdev" ] && mdev=0
            # Score = 100, minus 4 points per % packet loss, minus 1 point
            # per ms of jitter (mdev), floored at 0.
            STABILITY_SCORE=$(( 100 - (loss * 4) - mdev ))
            [ "$STABILITY_SCORE" -lt 0 ] && STABILITY_SCORE=0
            [ "$STABILITY_SCORE" -gt 100 ] && STABILITY_SCORE=100
        fi
    fi
}

# ==============================================================================
# FPS MODULE
# There is no non-root, general-purpose Android API that exposes real-time
# FPS to a third-party shell process. `dumpsys gfxinfo` / SurfaceFlinger
# frame stats normally require the "shell" UID (i.e. ADB), which a regular
# Termux app is not granted. This function tries anyway (in case a specific
# device/ROM allows it) and reports "Unavailable" rather than ever guessing.
# ==============================================================================

get_fps_info() {
    FPS_VALUE=""
    FPS_SOURCE=""
    if command -v dumpsys >/dev/null 2>&1; then
        local latency
        latency=$(dumpsys SurfaceFlinger --latency 2>/dev/null | head -n1)
        # A successful call returns a single number (refresh period in ns).
        if [[ "$latency" =~ ^[0-9]+$ ]] && [ "$latency" -gt 0 ]; then
            FPS_VALUE=$(awk -v p="$latency" 'BEGIN{printf "%d", 1000000000/p}')
            FPS_SOURCE="dumpsys SurfaceFlinger"
        fi
    fi
}

# ==============================================================================
# GAME DETECTOR
# Greps the visible process list against known game package names. On most
# Android 8+ devices, the kernel's hidepid restriction limits `ps` to only
# the calling app's own processes, so this will typically be unable to see
# other apps — that limitation is reported honestly, not hidden.
# ==============================================================================

detect_running_game() {
    RUNNING_GAME=""
    GAME_DETECT_LIMITED=0

    if ! command -v ps >/dev/null 2>&1; then
        GAME_DETECT_LIMITED=1
        return
    fi

    local ps_out pkg name
    ps_out=$(ps -A -o args= 2>/dev/null)
    if [ -z "$ps_out" ]; then
        GAME_DETECT_LIMITED=1
        return
    fi

    # If ps only ever shows Termux's own processes, process isolation is
    # active and detection of other apps is not possible without root/ADB.
    local other_procs
    other_procs=$(echo "$ps_out" | grep -vc "com.termux")
    if [ "$other_procs" -le 1 ]; then
        GAME_DETECT_LIMITED=1
    fi

    for pkg in "${!GAME_PACKAGES[@]}"; do
        if echo "$ps_out" | grep -q "$pkg"; then
            RUNNING_GAME="${GAME_PACKAGES[$pkg]}"
            return
        fi
    done
}

# ==============================================================================
# PROCESS VIEWER
# Same hidepid caveat as the Game Detector applies here: without root this
# will usually only be able to fully account for Termux's own process tree
# on modern Android. Shown anyway since some devices/ROMs are less strict.
# ==============================================================================

get_top_processes() {
    local sort_field="$1"   # "cpu" or "mem"
    local col

    if [ "$sort_field" = "mem" ]; then col=4; else col=3; fi

    if ! command -v ps >/dev/null 2>&1; then
        echo ""
        return
    fi

    ps -A -o pid,comm,%cpu,%mem 2>/dev/null | tail -n +2 | sort -k"${col}" -rn | head -n 10
}

# ==============================================================================
# PERFORMANCE ANALYZER
# Computes a 0-100 score using ONLY metrics that were actually measured.
# Categories with unreadable data are excluded from the score, not faked.
#
# v6.1 factors: RAM%, Storage%, Temperature, Ping, and CPU frequency
# headroom (current freq vs. this chip's own max freq). CPU frequency
# replaces CPU usage here specifically because reading it is instant (a
# single sysfs read) where usage needs two samples across time — keeping
# the score independent of that timing keeps every refresh cycle fast.
# ==============================================================================

calculate_performance_score() {
    local score_sum=0
    local weight_sum=0

    # RAM (weight 20) — lower usage % is better
    if [ -n "$RAM_PERCENT" ]; then
        local ram_score=$(( 100 - RAM_PERCENT ))
        [ "$ram_score" -lt 0 ] && ram_score=0
        score_sum=$(( score_sum + ram_score * 20 ))
        weight_sum=$(( weight_sum + 20 ))
    fi

    # Storage (weight 20) — lower usage % is better
    if [ -n "$STORAGE_PERCENT" ]; then
        local storage_score=$(( 100 - STORAGE_PERCENT ))
        [ "$storage_score" -lt 0 ] && storage_score=0
        score_sum=$(( score_sum + storage_score * 20 ))
        weight_sum=$(( weight_sum + 20 ))
    fi

    # Temperature (weight 20) — cooler is better, scaled 30C-45C
    if [ -n "$BATTERY_TEMP_C" ]; then
        local temp_int
        temp_int=$(awk -v t="$BATTERY_TEMP_C" 'BEGIN{printf "%d", t}')
        local temp_score=$(( 100 - ((temp_int - 30) * 100 / 15) ))
        [ "$temp_score" -lt 0 ] && temp_score=0
        [ "$temp_score" -gt 100 ] && temp_score=100
        score_sum=$(( score_sum + temp_score * 20 ))
        weight_sum=$(( weight_sum + 20 ))
    fi

    # Network (weight 20) — scaled 0-150ms ping
    if [ -n "$PING_MS" ]; then
        local net_score=$(( 100 - (PING_MS * 100 / 150) ))
        [ "$net_score" -lt 0 ] && net_score=0
        [ "$net_score" -gt 100 ] && net_score=100
        score_sum=$(( score_sum + net_score * 20 ))
        weight_sum=$(( weight_sum + 20 ))
    fi

    # CPU Frequency headroom (weight 20) — how close current freq is to
    # this chip's own max, from cpufreq. Less headroom used = cooler/safer
    # margin left, same "lower load is healthier" logic as the other
    # factors. Only scored if BOTH current and max frequency are readable.
    if [ -n "$CPU_FREQ_MHZ" ] && [ -n "$CPU_FREQ_MAX_MHZ" ] && [ "$CPU_FREQ_MAX_MHZ" -gt 0 ] 2>/dev/null; then
        local freq_pct freq_score
        freq_pct=$(( CPU_FREQ_MHZ * 100 / CPU_FREQ_MAX_MHZ ))
        freq_score=$(( 100 - freq_pct ))
        [ "$freq_score" -lt 0 ] && freq_score=0
        [ "$freq_score" -gt 100 ] && freq_score=100
        score_sum=$(( score_sum + freq_score * 20 ))
        weight_sum=$(( weight_sum + 20 ))
    fi

    if [ "$weight_sum" -eq 0 ]; then
        PERF_SCORE=""
        PERF_RATING="N/A"
        return
    fi

    PERF_SCORE=$(( score_sum / weight_sum ))

    if [ "$PERF_SCORE" -ge 85 ]; then PERF_RATING="Excellent"
    elif [ "$PERF_SCORE" -ge 65 ]; then PERF_RATING="Good"
    elif [ "$PERF_SCORE" -ge 40 ]; then PERF_RATING="Average"
    else PERF_RATING="Poor"
    fi
}

# ==============================================================================
# SESSION TRACKER
# ==============================================================================

update_session_stats() {
    if [ -n "$BATTERY_TEMP_C" ]; then
        if awk -v a="$BATTERY_TEMP_C" -v b="$HIGHEST_TEMP" 'BEGIN{exit !(a>b)}'; then
            HIGHEST_TEMP="$BATTERY_TEMP_C"
        fi
    fi

    if [ -n "$PING_MS" ]; then
        if [ -z "$LOWEST_PING" ] || [ "$PING_MS" -lt "$LOWEST_PING" ]; then
            LOWEST_PING="$PING_MS"
        fi
    fi

    if [ -n "$RAM_USED_MB" ] && [ "$RAM_USED_MB" -gt "$HIGHEST_RAM_USED_MB" ]; then
        HIGHEST_RAM_USED_MB="$RAM_USED_MB"
    fi

    if [ -n "$RAM_FREE_MB" ]; then
        if [ -z "$LOWEST_FREE_RAM_MB" ] || [ "$RAM_FREE_MB" -lt "$LOWEST_FREE_RAM_MB" ]; then
            LOWEST_FREE_RAM_MB="$RAM_FREE_MB"
        fi
    fi

    if [ -n "$PING_MS" ]; then
        PING_SUM=$(( PING_SUM + PING_MS ))
        PING_SAMPLES=$(( PING_SAMPLES + 1 ))
    fi

    if [ -n "$CPU_USAGE" ]; then
        CPU_SUM=$(( CPU_SUM + CPU_USAGE ))
        CPU_SAMPLES=$(( CPU_SAMPLES + 1 ))
    fi

    if [ -n "$PERF_SCORE" ]; then
        PERF_SUM=$(( PERF_SUM + PERF_SCORE ))
        PERF_SAMPLES=$(( PERF_SAMPLES + 1 ))
    fi

    push_history RAM_HISTORY "$RAM_PERCENT"
    push_history CPU_HISTORY "$CPU_USAGE"
    push_history TEMP_HISTORY "$BATTERY_TEMP_C"
    push_history PING_HISTORY "$PING_MS"
}

session_avg_ping() {
    [ "$PING_SAMPLES" -eq 0 ] && { echo "N/A"; return; }
    echo $(( PING_SUM / PING_SAMPLES ))
}

session_avg_cpu() {
    [ "$CPU_SAMPLES" -eq 0 ] && { echo "N/A"; return; }
    echo $(( CPU_SUM / CPU_SAMPLES ))
}

session_avg_perf() {
    [ "$PERF_SAMPLES" -eq 0 ] && { echo "N/A"; return; }
    echo $(( PERF_SUM / PERF_SAMPLES ))
}

session_duration_str() {
    local now elapsed
    now=$(date +%s)
    elapsed=$(( now - SESSION_START_EPOCH ))
    printf '%dh %dm %ds\n' $((elapsed/3600)) $(((elapsed%3600)/60)) $((elapsed%60))
}

# ==============================================================================
# ALERT SYSTEM
# Fires only on real, measured thresholds. Populates the global ALERTS array.
# ==============================================================================

check_alerts() {
    ALERTS=()

    if [ -n "$BATTERY_TEMP_C" ]; then
        local t
        t=$(awk -v t="$BATTERY_TEMP_C" 'BEGIN{printf "%d", t}')
        [ "$t" -gt 42 ] && ALERTS+=("Temperature ${BATTERY_TEMP_C}°C exceeds 42°C safe threshold")
    fi

    [ -n "$RAM_PERCENT" ] && [ "$RAM_PERCENT" -gt 90 ] && \
        ALERTS+=("RAM usage ${RAM_PERCENT}% exceeds 90%")

    [ -n "$STORAGE_PERCENT" ] && [ "$STORAGE_PERCENT" -gt 95 ] && \
        ALERTS+=("Storage usage ${STORAGE_PERCENT}% exceeds 95%")

    [ -n "$PING_MS" ] && [ "$PING_MS" -gt 120 ] && \
        ALERTS+=("Ping ${PING_MS}ms exceeds 120ms")

    [ -n "$BATTERY_PERCENT" ] && [ "$BATTERY_PERCENT" -lt 15 ] && \
        ALERTS+=("Battery ${BATTERY_PERCENT}% is below 15%")
}

render_alerts() {
    if [ "${#ALERTS[@]}" -eq 0 ]; then
        return
    fi
    section_header "⚠  ALERTS"
    local a
    for a in "${ALERTS[@]}"; do
        echo -e "  ${RED}⚠ ${a}${RESET}"
    done
    draw_line
}

# ==============================================================================
# GAME RECOMMENDATIONS
# Suggests a graphics tier per game based on real, currently-measured load.
# This NEVER promises an FPS number — only a relative graphics setting.
# ==============================================================================

device_load_level() {
    # Returns "light", "moderate", or "heavy" based on RAM%, CPU%, and temp.
    local penalty=0
    [ -n "$RAM_PERCENT" ] && [ "$RAM_PERCENT" -ge 80 ] && penalty=$((penalty+1))
    [ -n "$CPU_USAGE" ] && [ "$CPU_USAGE" -ge 70 ] && penalty=$((penalty+1))
    if [ -n "$BATTERY_TEMP_C" ]; then
        local t
        t=$(awk -v t="$BATTERY_TEMP_C" 'BEGIN{printf "%d", t}')
        [ "$t" -ge 40 ] && penalty=$((penalty+1))
    fi
    [ -n "$STORAGE_FREE_GB" ] && awk -v f="$STORAGE_FREE_GB" 'BEGIN{exit !(f<2)}' && penalty=$((penalty+1))

    if [ "$penalty" -ge 2 ]; then echo "heavy"
    elif [ "$penalty" -eq 1 ]; then echo "moderate"
    else echo "light"
    fi
}

print_recommendations() {
    local load
    load=$(device_load_level)

    echo -e "  Current device load: ${WHITE}${load}${RESET}"
    echo -e "  ${DIM}(Suggests a graphics tier only — never a promised FPS number.)${RESET}"
    echo ""

    case "$load" in
        light)
            echo -e "  ${WHITE}Roblox${RESET}      : Graphics 8-10 (max quality)"
            echo -e "  ${WHITE}MLBB${RESET}        : Ultra + High Frame Rate"
            echo -e "  ${WHITE}CODM${RESET}        : Very High + Max Frame Rate"
            echo -e "  ${WHITE}PUBG Mobile${RESET} : HDR / Ultra + Extreme frame rate"
            echo -e "  ${WHITE}Free Fire${RESET}   : Ultra HD + Ultra frame rate"
            ;;
        moderate)
            echo -e "  ${WHITE}Roblox${RESET}      : Graphics 6-8"
            echo -e "  ${WHITE}MLBB${RESET}        : High + High Frame Rate"
            echo -e "  ${WHITE}CODM${RESET}        : High + High Frame Rate"
            echo -e "  ${WHITE}PUBG Mobile${RESET} : Balanced + High frame rate"
            echo -e "  ${WHITE}Free Fire${RESET}   : HD + High frame rate"
            ;;
        heavy)
            echo -e "  ${WHITE}Roblox${RESET}      : Graphics 3-5 (lower load)"
            echo -e "  ${WHITE}MLBB${RESET}        : Medium + Standard Frame Rate"
            echo -e "  ${WHITE}CODM${RESET}        : Medium + Standard Frame Rate"
            echo -e "  ${WHITE}PUBG Mobile${RESET} : Smooth + Medium frame rate"
            echo -e "  ${WHITE}Free Fire${RESET}   : Smooth + Standard frame rate"
            echo ""
            echo -e "  ${YELLOW}Device is under heavier load right now — settings above are${RESET}"
            echo -e "  ${YELLOW}lowered to reduce heat/RAM pressure, not to hit a target FPS.${RESET}"
            ;;
    esac
}

# ==============================================================================
# LIFETIME STATS (persisted across runs)
# ==============================================================================

load_lifetime_stats() {
    [ -f "$STATS_FILE" ] || return
    # shellcheck disable=SC1090
    source "$STATS_FILE" 2>/dev/null
}

save_lifetime_stats() {
    mkdir -p "$LOG_DIR" 2>/dev/null

    local session_now
    session_now=$(( $(date +%s) - SESSION_START_EPOCH ))

    if [ "$HIGHEST_RAM_USED_MB" -gt "$LIFETIME_MAX_RAM_MB" ] 2>/dev/null; then
        LIFETIME_MAX_RAM_MB="$HIGHEST_RAM_USED_MB"
    fi
    if awk -v a="$HIGHEST_TEMP" -v b="$LIFETIME_MAX_TEMP" 'BEGIN{exit !(a>b)}' 2>/dev/null; then
        LIFETIME_MAX_TEMP="$HIGHEST_TEMP"
    fi
    if [ "$session_now" -gt "$LIFETIME_LONGEST_SESSION_SEC" ] 2>/dev/null; then
        LIFETIME_LONGEST_SESSION_SEC="$session_now"
    fi

    cat > "$STATS_FILE" 2>/dev/null << EOF
LIFETIME_MAX_RAM_MB=$LIFETIME_MAX_RAM_MB
LIFETIME_MAX_TEMP=$LIFETIME_MAX_TEMP
LIFETIME_LONGEST_SESSION_SEC=$LIFETIME_LONGEST_SESSION_SEC
EOF
}

seconds_to_hms() {
    local secs="${1:-0}"
    printf '%dh %dm %ds\n' $((secs/3600)) $(((secs%3600)/60)) $((secs%60))
}

# ==============================================================================
# SESSION HISTORY (each completed session, not just lifetime maxes)
# ==============================================================================

init_sessions_file() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    if [ ! -f "$SESSIONS_FILE" ]; then
        echo "Timestamp,Duration_sec,Highest_Temp_C,Lowest_Ping_ms,Highest_RAM_MB,Avg_Perf_Score" > "$SESSIONS_FILE" 2>/dev/null
    fi
}

# Appends one row for the session that's ending. Only records a session
# that actually collected at least one sample — an empty visit to the menu
# that never opened Live Monitor doesn't count as a "session".
record_session_history() {
    [ "$PING_SAMPLES" -eq 0 ] && [ "$CPU_SAMPLES" -eq 0 ] && [ "$HIGHEST_RAM_USED_MB" -eq 0 ] && return

    init_sessions_file
    local duration
    duration=$(( $(date +%s) - SESSION_START_EPOCH ))

    echo "$(date '+%Y-%m-%d %H:%M:%S'),${duration},${HIGHEST_TEMP},${LOWEST_PING:-NA},${HIGHEST_RAM_USED_MB},$(session_avg_perf)" >> "$SESSIONS_FILE" 2>/dev/null
}

# ==============================================================================
# EXPORT REPORT (TXT and/or CSV, every collected metric + timestamp)
# ==============================================================================

generate_report() {
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    local report_file="$REPORTS_DIR/report_$(date +%Y-%m-%d_%H-%M-%S).txt"

    {
        echo "==================================================="
        echo "  LUMEXA SESSION REPORT"
        echo "==================================================="
        echo "Generated         : $(date '+%Y-%m-%d %H:%M:%S')"
        echo "Device            : ${MANUFACTURER:-N/A} ${MODEL:-N/A}"
        echo "Android           : ${ANDROID_VER:-N/A} (SDK ${SDK_VER:-N/A})"
        echo "Kernel            : ${KERNEL_VER:-N/A}"
        echo "Architecture      : ${ARCH:-N/A}"
        echo "Uptime            : ${UPTIME_STR:-N/A}"
        echo ""
        echo "--- CPU ---"
        echo "Cores             : ${CPU_CORES:-N/A}"
        echo "Usage             : ${CPU_USAGE:-N/A}%"
        echo "Frequency         : ${CPU_FREQ_MHZ:-N/A} MHz (max ${CPU_FREQ_MAX_MHZ:-N/A} MHz)"
        echo "Governor          : ${CPU_GOVERNOR:-N/A}"
        echo "Load Average      : ${LOAD_AVG:-N/A}"
        echo "CPU Temperature   : ${CPU_TEMP_C:-N/A}°C"
        echo ""
        echo "--- RAM ---"
        echo "Total             : ${RAM_TOTAL_MB:-N/A} MB"
        echo "Used              : ${RAM_USED_MB:-N/A} MB"
        echo "Free              : ${RAM_FREE_MB:-N/A} MB"
        echo "Cached            : ${RAM_CACHED_MB:-N/A} MB"
        echo "Buffers           : ${RAM_BUFFERS_MB:-N/A} MB"
        echo "Usage             : ${RAM_PERCENT:-N/A}%"
        echo ""
        echo "--- BATTERY ---"
        echo "Level             : ${BATTERY_PERCENT:-N/A}%"
        echo "Status            : ${BATTERY_STATUS:-N/A}"
        echo "Health            : ${BATTERY_HEALTH:-N/A}"
        echo "Voltage           : ${BATTERY_VOLTAGE_V:-N/A} V"
        echo "Current           : ${BATTERY_CURRENT_MA:-N/A} mA"
        echo "Temperature       : ${BATTERY_TEMP_C:-N/A}°C"
        echo ""
        echo "--- STORAGE ---"
        echo "Used              : ${STORAGE_USED_GB:-N/A} GB"
        echo "Free              : ${STORAGE_FREE_GB:-N/A} GB"
        echo "Usage             : ${STORAGE_PERCENT:-N/A}%"
        echo ""
        echo "--- NETWORK ---"
        echo "Type              : ${NETWORK_TYPE:-N/A}"
        echo "IP Address        : ${CURRENT_IP:-N/A}"
        echo "Ping              : ${PING_MS:-N/A} ms"
        echo "Packet Loss       : ${PACKET_LOSS:-N/A}"
        echo "DNS Lookup        : ${DNS_MS:-N/A} ms"
        echo "Signal Strength   : ${SIGNAL_STRENGTH:-N/A}"
        echo "Stability Score   : ${STABILITY_SCORE:-N/A}/100"
        echo ""
        echo "--- GAMING ---"
        echo "Currently Playing : ${RUNNING_GAME:-N/A}"
        echo "FPS               : ${FPS_VALUE:-N/A}"
        echo ""
        echo "--- PERFORMANCE ---"
        echo "Score             : ${PERF_SCORE:-N/A}/100 (${PERF_RATING:-N/A})"
        echo ""
        echo "--- SESSION SUMMARY ---"
        echo "Session Time      : $(session_duration_str)"
        echo "Average Ping      : $(session_avg_ping) ms"
        echo "Average CPU       : $(session_avg_cpu)%"
        echo "Average Score     : $(session_avg_perf)/100"
        echo "Peak RAM Used     : ${HIGHEST_RAM_USED_MB:-N/A} MB"
        echo "Highest Temp      : ${HIGHEST_TEMP:-N/A}°C"
        echo ""
        echo "--- LIFETIME (all sessions) ---"
        echo "Longest Session   : $(seconds_to_hms "$LIFETIME_LONGEST_SESSION_SEC")"
        echo "Max RAM Ever Used : ${LIFETIME_MAX_RAM_MB:-N/A} MB"
        echo "Max Temp Ever     : ${LIFETIME_MAX_TEMP:-N/A}°C"
        echo "==================================================="
    } > "$report_file" 2>/dev/null

    echo "$report_file"
}

# CSV export: one header row + one data row per export, covering the same
# fields as the TXT report so either format can be parsed/graphed later.
generate_csv_report() {
    mkdir -p "$REPORTS_DIR" 2>/dev/null
    local csv_file="$REPORTS_DIR/report_$(date +%Y-%m-%d_%H-%M-%S).csv"

    {
        echo "Timestamp,Device,Android,CPU_Cores,CPU_Usage_pct,CPU_Freq_MHz,CPU_Governor,CPU_Temp_C,RAM_Total_MB,RAM_Used_MB,RAM_Percent,Battery_Level_pct,Battery_Status,Battery_Health,Battery_Temp_C,Storage_Used_GB,Storage_Percent,Network_Type,Ping_ms,Packet_Loss,Perf_Score,Session_Duration_sec"
        echo "\"$(date '+%Y-%m-%d %H:%M:%S')\",\"${MANUFACTURER:-N/A} ${MODEL:-N/A}\",\"${ANDROID_VER:-N/A}\",${CPU_CORES:-NA},${CPU_USAGE:-NA},${CPU_FREQ_MHZ:-NA},\"${CPU_GOVERNOR:-N/A}\",${CPU_TEMP_C:-NA},${RAM_TOTAL_MB:-NA},${RAM_USED_MB:-NA},${RAM_PERCENT:-NA},${BATTERY_PERCENT:-NA},\"${BATTERY_STATUS:-N/A}\",\"${BATTERY_HEALTH:-N/A}\",${BATTERY_TEMP_C:-NA},${STORAGE_USED_GB:-NA},${STORAGE_PERCENT:-NA},\"${NETWORK_TYPE:-N/A}\",${PING_MS:-NA},\"${PACKET_LOSS:-N/A}\",${PERF_SCORE:-NA},$(( $(date +%s) - SESSION_START_EPOCH ))"
    } > "$csv_file" 2>/dev/null

    echo "$csv_file"
}

# ==============================================================================
# LOGGING
# ==============================================================================

init_logging() {
    mkdir -p "$LOG_DIR" 2>/dev/null
    if [ ! -f "$LOG_FILE" ]; then
        echo "Date,Time,RAM_Used_MB,RAM_Total_MB,Temp_C,Ping_ms,PerfScore" > "$LOG_FILE" 2>/dev/null
    fi
}

log_entry() {
    [ ! -d "$LOG_DIR" ] && return
    echo "$(date +%Y-%m-%d),$(date +%H:%M:%S),${RAM_USED_MB:-NA},${RAM_TOTAL_MB:-NA},${BATTERY_TEMP_C:-NA},${PING_MS:-NA},${PERF_SCORE:-NA}" >> "$LOG_FILE" 2>/dev/null
}

# ==============================================================================
# CENTRAL METRIC COLLECTION
# One place that gathers every data point a screen might need, so each
# screen just calls this instead of repeating unset/collect logic.
# ==============================================================================

collect_all_metrics() {
    unset CPU_USAGE CPU_FREQ_MHZ CPU_FREQ_MAX_MHZ CPU_GOVERNOR LOAD_AVG CPU_TEMP_C
    unset RAM_TOTAL_MB RAM_USED_MB RAM_FREE_MB RAM_AVAIL_MB RAM_BUFFERS_MB RAM_CACHED_MB RAM_PERCENT
    unset BATTERY_PERCENT BATTERY_STATUS BATTERY_HEALTH BATTERY_TEMP_C BATTERY_VOLTAGE_V BATTERY_CURRENT_MA
    unset STORAGE_TOTAL_GB STORAGE_USED_GB STORAGE_FREE_GB STORAGE_PERCENT
    unset WIFI_STATUS MOBILE_DATA_STATUS CURRENT_IP PING_MS PACKET_LOSS INTERNET_STATUS DNS_MS
    unset PERF_SCORE PERF_RATING
    unset NETWORK_TYPE SIGNAL_STRENGTH SIGNAL_SOURCE STABILITY_SCORE
    unset FPS_VALUE FPS_SOURCE RUNNING_GAME GAME_DETECT_LIMITED

    get_system_info
    get_cpu_info
    get_cpu_temp
    get_ram_info
    get_battery_info
    get_storage_info
    get_network_info
    get_network_extra
    get_fps_info
    detect_running_game
    calculate_performance_score
    check_alerts
}

# ==============================================================================
# SCREEN — LIVE MONITOR
# ==============================================================================

render_live_monitor_frame() {
    screen_clear
    draw_line
    local mode_tag=""
    [ "$GAME_MODE" -eq 1 ] && mode_tag=" [GAME MODE]"
    echo -e "${YELLOW}${BOLD}       LUMEXA LIVE MONITOR CENTER${mode_tag}${RESET}"
    draw_line

    render_alerts

    # ---------------- GAMING STATUS ----------------
    section_header "GAMING STATUS"
    if [ -n "$RUNNING_GAME" ]; then
        echo -e "  Currently Playing: ${GREEN}${RUNNING_GAME}${RESET}"
    elif [ "$GAME_DETECT_LIMITED" -eq 1 ]; then
        echo -e "  Currently Playing: ${DIM}N/A — Android process isolation (hidepid)${RESET}"
        echo -e "  ${DIM}blocks Termux from seeing other apps' processes without root/ADB.${RESET}"
    else
        echo -e "  Currently Playing: ${DIM}None of the known games detected${RESET}"
    fi
    if [ -n "$FPS_VALUE" ]; then
        echo -e "  FPS               : ${WHITE}${FPS_VALUE} (via ${FPS_SOURCE})${RESET}"
    else
        echo -e "  FPS               : ${DIM}Unavailable on this device without special APIs${RESET}"
    fi
    draw_line

    # ---------------- SYSTEM INFO ----------------
    section_header "SYSTEM"
    echo -e "  Device      : ${WHITE}${MANUFACTURER} ${MODEL}${RESET}"
    echo -e "  Android     : ${WHITE}${ANDROID_VER} (SDK ${SDK_VER})${RESET}"
    echo -e "  Kernel      : ${WHITE}${KERNEL_VER}${RESET}"
    echo -e "  Arch        : ${WHITE}${ARCH}${RESET}"
    echo -e "  Uptime      : ${WHITE}${UPTIME_STR}${RESET}"
    draw_line

    # ---------------- CPU ----------------
    section_header "CPU"
    echo -e "  Cores       : ${WHITE}${CPU_CORES}${RESET}"
    if [ -n "$CPU_USAGE" ]; then
        printf "  Usage       : "; draw_bar "$CPU_USAGE"
    else
        na_line "Usage" "no prior sample yet this session — next refresh will show it"
    fi
    [ -n "$CPU_FREQ_MHZ" ] && echo -e "  Frequency   : ${WHITE}${CPU_FREQ_MHZ} MHz${RESET} ${DIM}(max ${CPU_FREQ_MAX_MHZ:-N/A} MHz)${RESET}" || na_line "Frequency"
    [ -n "$CPU_GOVERNOR" ] && echo -e "  Governor    : ${WHITE}${CPU_GOVERNOR}${RESET}" || na_line "Governor"
    [ -n "$LOAD_AVG" ] && echo -e "  Load Avg    : ${WHITE}${LOAD_AVG}${RESET}" || na_line "Load Average"
    draw_line

    # ---------------- RAM ----------------
    section_header "RAM"
    if [ -n "$RAM_TOTAL_MB" ]; then
        echo -e "  Total       : ${WHITE}${RAM_TOTAL_MB} MB${RESET}"
        echo -e "  Used        : ${WHITE}${RAM_USED_MB} MB${RESET}"
        echo -e "  Free        : ${WHITE}${RAM_FREE_MB} MB${RESET}"
        echo -e "  Cached      : ${WHITE}${RAM_CACHED_MB} MB${RESET}"
        echo -e "  Buffers     : ${WHITE}${RAM_BUFFERS_MB} MB${RESET}"
        printf "  Usage       : "; draw_bar "$RAM_PERCENT"
    else
        na_line "RAM stats"
    fi
    draw_line

    # ---------------- BATTERY / THERMAL ----------------
    section_header "BATTERY & THERMAL"
    if [ -n "$BATTERY_PERCENT" ]; then
        printf "  Charge      : "; draw_bar "$BATTERY_PERCENT"
    else
        na_line "Charge"
    fi
    [ -n "$BATTERY_STATUS" ] && echo -e "  Status      : ${WHITE}${BATTERY_STATUS}${RESET}" || na_line "Status"
    [ -n "$BATTERY_HEALTH" ] && echo -e "  Health      : ${WHITE}${BATTERY_HEALTH}${RESET}" || na_line "Health"
    [ -n "$BATTERY_VOLTAGE_V" ] && echo -e "  Voltage     : ${WHITE}${BATTERY_VOLTAGE_V} V${RESET}" || na_line "Voltage"
    [ -n "$BATTERY_CURRENT_MA" ] && echo -e "  Current     : ${WHITE}${BATTERY_CURRENT_MA} mA${RESET}" || na_line "Current"
    if [ -n "$BATTERY_TEMP_C" ]; then
        local temp_int
        temp_int=$(awk -v t="$BATTERY_TEMP_C" 'BEGIN{printf "%d", t}')
        if [ "$temp_int" -ge 45 ]; then
            echo -e "  Batt. Temp  : ${RED}${BATTERY_TEMP_C}°C — OVERHEATING${RESET}"
        elif [ "$temp_int" -ge 40 ]; then
            echo -e "  Batt. Temp  : ${ORANGE}${BATTERY_TEMP_C}°C — Hot${RESET}"
        elif [ "$temp_int" -ge 35 ]; then
            echo -e "  Batt. Temp  : ${YELLOW}${BATTERY_TEMP_C}°C — Warm${RESET}"
        else
            echo -e "  Batt. Temp  : ${GREEN}${BATTERY_TEMP_C}°C — Cool${RESET}"
        fi
    else
        na_line "Batt. Temp"
    fi
    [ -n "$CPU_TEMP_C" ] && echo -e "  CPU Temp    : ${WHITE}${CPU_TEMP_C}°C${RESET}" || na_line "CPU Temp" "no cpu-labeled thermal zone exposed on this device"
    draw_line

    # ---------------- STORAGE ----------------
    section_header "STORAGE"
    if [ -n "$STORAGE_TOTAL_GB" ]; then
        echo -e "  Used / Free : ${WHITE}${STORAGE_USED_GB} GB / ${STORAGE_FREE_GB} GB${RESET}"
        printf "  Usage       : "; draw_bar "$STORAGE_PERCENT"
    else
        na_line "Storage stats"
    fi
    draw_line

    # ---------------- NETWORK ----------------
    section_header "NETWORK"
    echo -e "  Type        : ${WHITE}${NETWORK_TYPE}${RESET}"
    echo -e "  IP Address  : ${WHITE}${CURRENT_IP:-N/A}${RESET}"
    if [ -n "$PING_MS" ]; then
        if [ "$PING_MS" -le 40 ]; then
            echo -e "  Ping        : ${GREEN}${PING_MS} ms — Excellent${RESET}"
        elif [ "$PING_MS" -le 90 ]; then
            echo -e "  Ping        : ${YELLOW}${PING_MS} ms — Moderate${RESET}"
        else
            echo -e "  Ping        : ${RED}${PING_MS} ms — High, expect lag${RESET}"
        fi
    else
        echo -e "  Ping        : ${RED}DISCONNECTED / NO SIGNAL${RESET}"
    fi
    [ -n "$PACKET_LOSS" ] && echo -e "  Packet Loss : ${WHITE}${PACKET_LOSS}${RESET}" || na_line "Packet Loss"
    [ -n "$DNS_MS" ] && echo -e "  DNS Lookup  : ${WHITE}${DNS_MS} ms${RESET}" || na_line "DNS Lookup"
    draw_line

    # ---------------- PERFORMANCE ANALYZER ----------------
    section_header "PERFORMANCE ANALYZER"
    if [ -n "$PERF_SCORE" ]; then
        local pcolor=$GREEN
        [ "$PERF_RATING" = "Average" ] && pcolor=$YELLOW
        [ "$PERF_RATING" = "Poor" ] && pcolor=$RED
        echo -e "  Score       : ${WHITE}${PERF_SCORE}/100${RESET}   Rating: ${pcolor}${PERF_RATING}${RESET}"
    else
        na_line "Score" "not enough readable metrics on this device"
    fi
    draw_line

    # ---------------- GRAPHS ----------------
    section_header "GRAPHS (last ${HISTORY_LEN} samples)"
    printf "  RAM  %%: "; sparkline RAM_HISTORY 0 100
    printf "  CPU  %%: "; sparkline CPU_HISTORY 0 100
    printf "  Temp °C: "; sparkline TEMP_HISTORY 25 45
    printf "  Ping ms: "; sparkline PING_HISTORY 0 200
    draw_line

    # ---------------- SESSION TRACKER ----------------
    section_header "LIVE SESSION"
    echo -e "  Duration       : ${WHITE}$(session_duration_str)${RESET}"
    echo -e "  Highest Temp   : ${WHITE}${HIGHEST_TEMP}°C${RESET}   Peak RAM: ${WHITE}${HIGHEST_RAM_USED_MB} MB${RESET}"
    echo -e "  Lowest Ping    : ${WHITE}${LOWEST_PING:-N/A} ms${RESET}   Avg Ping: ${WHITE}$(session_avg_ping) ms${RESET}"
    draw_line

    echo -e "  [${WHITE}m${RESET}] Menu   [${WHITE}CTRL+C${RESET}] Exit & Save   Refresh: ${DIM}${1}s${RESET}"
}

screen_live_monitor() {
    local interval
    while true; do
        interval=$REFRESH_INTERVAL
        [ "$GAME_MODE" -eq 1 ] && interval=$GAME_MODE_REFRESH_INTERVAL

        collect_all_metrics
        update_session_stats
        log_entry
        render_live_monitor_frame "$interval"

        local key=""
        read -t "$interval" -n 1 -s key
        if [ "$key" = "m" ] || [ "$key" = "M" ]; then
            return
        fi
    done
}

# ==============================================================================
# SCREEN — GAME MODE
# ==============================================================================

screen_game_mode() {
    screen_header "GAME MODE"
    echo ""
    if [ "$GAME_MODE" -eq 0 ]; then
        echo -e "  ${WHITE}Enabling Game Mode...${RESET}"
        echo ""

        # 1. Lower Termux's own scheduling priority (real, non-root-safe:
        #    only affects this process, $$, not the whole system).
        renice -n 19 -p $$ >/dev/null 2>&1
        echo -e "  ${GREEN}✔${RESET} Termux's own scheduling priority lowered (renice)."

        # 2. Clear Termux's OWN temporary files. This only touches files
        #    Termux itself created ($TMPDIR / $PREFIX/tmp) — never system or
        #    other apps' data, and never needs root.
        local tmp_target="${TMPDIR:-$PREFIX/tmp}"
        if [ -d "$tmp_target" ]; then
            rm -rf "${tmp_target:?}"/* 2>/dev/null
            echo -e "  ${GREEN}✔${RESET} Cleared Termux's own temp files (${tmp_target})."
        else
            echo -e "  ${DIM}·${RESET} No Termux temp directory found — nothing to clear."
        fi

        # 3. Sync filesystem buffers to storage. `sync` is a normal, non-root
        #    command available to any user; it just flushes pending writes,
        #    it does not "optimize" storage or free extra RAM.
        sync 2>/dev/null
        echo -e "  ${GREEN}✔${RESET} Filesystem synced (pending writes flushed to storage)."

        echo -e "  ${GREEN}✔${RESET} Dashboard refresh reduced to every ${GAME_MODE_REFRESH_INTERVAL}s"
        echo -e "    ${DIM}(cuts the dashboard's own CPU/battery use while you play —${RESET}"
        echo -e "    ${DIM}Termux cannot detect 'minimized' state without root, so this${RESET}"
        echo -e "    ${DIM}is a manual low-power mode rather than automatic detection).${RESET}"

        GAME_MODE=1
        echo ""
        echo -e "  ${GREEN}${BOLD}Ready to Launch Game.${RESET}"
        echo -e "  ${DIM}This does not increase FPS — it only reduces Termux's own${RESET}"
        echo -e "  ${DIM}background footprint so more of the phone is free for your game.${RESET}"
        echo ""
        echo -e "  ${YELLOW}[TIP]${RESET} Manually clear background apps from Recent Apps too —"
        echo -e "  ${YELLOW}      Termux cannot close other apps without root.${RESET}"
        echo ""
        collect_all_metrics
        print_recommendations
    else
        GAME_MODE=0
        echo -e "  ${YELLOW}Game Mode disabled.${RESET} Dashboard refresh restored to ${REFRESH_INTERVAL}s."
    fi
    echo ""
    press_any_key
}

# ==============================================================================
# SCREEN — NETWORK ANALYZER
# ==============================================================================

screen_network_analyzer() {
    screen_header "NETWORK ANALYZER"
    loading_anim "Measuring network (ping, DNS, signal)..." 1

    get_network_info
    get_network_extra

    screen_header "NETWORK ANALYZER"

    echo -e "  Network Type    : ${WHITE}${NETWORK_TYPE}${RESET}"
    echo -e "  IP Address      : ${WHITE}${CURRENT_IP:-N/A}${RESET}"
    if [ -n "$SIGNAL_STRENGTH" ]; then
        echo -e "  Signal Strength : ${WHITE}${SIGNAL_STRENGTH}${RESET} ${DIM}(${SIGNAL_SOURCE})${RESET}"
    else
        na_line "Signal Strength" "requires the Termux:API companion app" 16
    fi

    if [ -n "$PING_MS" ]; then
        if [ "$PING_MS" -le 40 ]; then
            echo -e "  Ping            : ${GREEN}${PING_MS} ms — Excellent${RESET}"
        elif [ "$PING_MS" -le 90 ]; then
            echo -e "  Ping            : ${YELLOW}${PING_MS} ms — Moderate${RESET}"
        else
            echo -e "  Ping            : ${RED}${PING_MS} ms — High${RESET}"
        fi
    else
        echo -e "  Ping            : ${RED}DISCONNECTED / NO SIGNAL${RESET}"
    fi
    [ -n "$PACKET_LOSS" ] && echo -e "  Packet Loss     : ${WHITE}${PACKET_LOSS}${RESET}" || na_line "Packet Loss" "" 16
    [ -n "$DNS_MS" ] && echo -e "  DNS Lookup      : ${WHITE}${DNS_MS} ms${RESET}" || na_line "DNS Lookup" "" 16

    if [ -n "$STABILITY_SCORE" ]; then
        local scolor=$GREEN
        [ "$STABILITY_SCORE" -lt 80 ] && scolor=$YELLOW
        [ "$STABILITY_SCORE" -lt 50 ] && scolor=$RED
        echo -e "  Stability Score : ${scolor}${STABILITY_SCORE}/100${RESET} ${DIM}(from packet loss + jitter over 5 pings)${RESET}"
    else
        na_line "Stability Score" "no reachable ping samples" 16
    fi
    press_any_key
}

# ==============================================================================
# SCREEN — DEVICE HEALTH
# ==============================================================================

rating_from_percent_good_low() {
    # Lower is better (RAM%, storage%, CPU%). $1 = percent
    local p="$1"
    if [ -z "$p" ]; then echo "N/A"; return; fi
    if [ "$p" -lt 50 ]; then echo "Excellent"
    elif [ "$p" -lt 75 ]; then echo "Good"
    elif [ "$p" -lt 90 ]; then echo "Average"
    else echo "Poor"
    fi
}

print_rating() {
    local label="$1" rating="$2"
    local color=$GREEN
    case "$rating" in
        Good) color=$GREEN ;;
        Average) color=$YELLOW ;;
        Poor) color=$RED ;;
        N/A) color=$DIM ;;
    esac
    printf "  %-18s: " "$label"
    echo -e "${color}${rating}${RESET}"
}

screen_device_health() {
    screen_header "DEVICE HEALTH"

    collect_all_metrics

    local battery_rating="N/A"
    if [ -n "$BATTERY_PERCENT" ]; then
        if [ "$BATTERY_PERCENT" -ge 60 ]; then battery_rating="Excellent"
        elif [ "$BATTERY_PERCENT" -ge 35 ]; then battery_rating="Good"
        elif [ "$BATTERY_PERCENT" -ge 15 ]; then battery_rating="Average"
        else battery_rating="Poor"
        fi
    fi

    local temp_rating="N/A"
    local temp_int=""
    if [ -n "$BATTERY_TEMP_C" ]; then
        temp_int=$(awk -v t="$BATTERY_TEMP_C" 'BEGIN{printf "%d", t}')
        if [ "$temp_int" -lt 35 ]; then temp_rating="Excellent"
        elif [ "$temp_int" -lt 40 ]; then temp_rating="Good"
        elif [ "$temp_int" -lt 45 ]; then temp_rating="Average"
        else temp_rating="Poor"
        fi
    fi

    local storage_rating ram_rating
    storage_rating=$(rating_from_percent_good_low "$STORAGE_PERCENT")
    ram_rating=$(rating_from_percent_good_low "$RAM_PERCENT")

    print_rating "RAM Pressure" "$ram_rating"
    print_rating "Storage Health" "$storage_rating"
    print_rating "Battery Condition" "$battery_rating"
    print_rating "Thermal Status" "$temp_rating"
    draw_line

    echo -e "  Overall: ${WHITE}${PERF_RATING:-N/A}${RESET} ${DIM}(from Performance Analyzer, ${PERF_SCORE:-N/A}/100)${RESET}"
    draw_line

    # ---------------- PERFORMANCE RECOMMENDATIONS ----------------
    # Rule-based tips derived only from the ratings just shown — never a
    # separate invented metric.
    section_header "RECOMMENDATIONS"
    local tips_given=0
    if [ "$ram_rating" = "Poor" ] || [ "$ram_rating" = "Average" ]; then
        echo -e "  ${YELLOW}•${RESET} RAM usage is high — close background apps before gaming."
        tips_given=1
    fi
    if [ "$storage_rating" = "Poor" ]; then
        echo -e "  ${RED}•${RESET} Storage is nearly full — free up space to avoid stutter/crashes."
        tips_given=1
    elif [ "$storage_rating" = "Average" ]; then
        echo -e "  ${YELLOW}•${RESET} Storage is getting full — consider clearing unused files."
        tips_given=1
    fi
    if [ "$temp_rating" = "Poor" ]; then
        echo -e "  ${RED}•${RESET} Device is hot — let it cool down before a long gaming session."
        tips_given=1
    elif [ "$temp_rating" = "Average" ]; then
        echo -e "  ${YELLOW}•${RESET} Device is warm — avoid direct sunlight and cases while charging."
        tips_given=1
    fi
    if [ "$battery_rating" = "Poor" ]; then
        echo -e "  ${RED}•${RESET} Battery is low — plug in before starting a session."
        tips_given=1
    fi
    if [ "$tips_given" -eq 0 ]; then
        echo -e "  ${GREEN}•${RESET} No issues detected — device looks ready for gaming."
    fi
    press_any_key
}

# ==============================================================================
# SCREEN — GAME RECOMMENDATIONS
# ==============================================================================

screen_recommendations() {
    screen_header "GAME RECOMMENDATIONS"
    collect_all_metrics
    echo ""
    print_recommendations
    echo ""
    press_any_key
}

# ==============================================================================
# SCREEN — PERFORMANCE HISTORY
# ==============================================================================

screen_history() {
    screen_header "PERFORMANCE HISTORY"

    echo -e "  ${WHITE}${BOLD}Lifetime (all sessions):${RESET}"
    echo -e "    Longest Session   : ${WHITE}$(seconds_to_hms "$LIFETIME_LONGEST_SESSION_SEC")${RESET}"
    echo -e "    Max RAM Ever Used : ${WHITE}${LIFETIME_MAX_RAM_MB} MB${RESET}"
    echo -e "    Max Temp Ever     : ${WHITE}${LIFETIME_MAX_TEMP}°C${RESET}"
    draw_line

    echo -e "  ${WHITE}${BOLD}This Session (so far):${RESET}"
    echo -e "    Duration          : ${WHITE}$(session_duration_str)${RESET}"
    echo -e "    Average Ping      : ${WHITE}$(session_avg_ping) ms${RESET}"
    echo -e "    Average Score     : ${WHITE}$(session_avg_perf)/100${RESET}"
    echo -e "    Peak RAM Used     : ${WHITE}${HIGHEST_RAM_USED_MB} MB${RESET}"
    echo -e "    Highest Temp      : ${WHITE}${HIGHEST_TEMP}°C${RESET}"
    draw_line

    section_header "PAST SESSIONS"
    if [ -f "$SESSIONS_FILE" ] && [ "$(wc -l < "$SESSIONS_FILE" 2>/dev/null)" -gt 1 ]; then
        printf "  %-19s %8s %8s %8s %8s %6s\n" "Ended" "Dur(s)" "MaxT°C" "MinPing" "MaxRAM" "Score"
        tail -n +2 "$SESSIONS_FILE" | tail -n 8 | while IFS=',' read -r ts dur temp ping ram score; do
            printf "  %-19s %8s %8s %8s %8s %6s\n" "$ts" "$dur" "$temp" "$ping" "$ram" "$score"
        done
    else
        echo -e "  ${DIM}No completed sessions yet — sessions are recorded when you exit${RESET}"
        echo -e "  ${DIM}after visiting Live Monitor at least once.${RESET}"
    fi
    draw_line

    if [ -f "$LOG_FILE" ]; then
        echo -e "  ${WHITE}${BOLD}Recent log entries (${LOG_FILE##*/}):${RESET}"
        echo -e "  ${DIM}$(head -n1 "$LOG_FILE")${RESET}"
        tail -n 5 "$LOG_FILE" | while IFS= read -r row; do
            echo "  $row"
        done
    else
        echo -e "  ${DIM}No log entries yet — visit Live Monitor to start recording.${RESET}"
    fi
    press_any_key
}

# ==============================================================================
# SCREEN — PROCESS VIEWER
# ==============================================================================

screen_process_viewer() {
    screen_header "PROCESS VIEWER"

    local cpu_top mem_top
    cpu_top=$(get_top_processes cpu)
    mem_top=$(get_top_processes mem)

    section_header "TOP 10 — CPU"
    if [ -n "$cpu_top" ]; then
        printf "  %-8s %-20s %6s %6s\n" "PID" "NAME" "%CPU" "%MEM"
        echo "$cpu_top" | awk '{printf "  %-8s %-20s %6s %6s\n", $1, $2, $3, $4}'
    else
        echo -e "  ${DIM}Unavailable — Android's per-app process isolation (hidepid)${RESET}"
        echo -e "  ${DIM}usually blocks a non-root app from listing other apps' processes.${RESET}"
    fi
    draw_line

    section_header "TOP 10 — RAM"
    if [ -n "$mem_top" ]; then
        printf "  %-8s %-20s %6s %6s\n" "PID" "NAME" "%CPU" "%MEM"
        echo "$mem_top" | awk '{printf "  %-8s %-20s %6s %6s\n", $1, $2, $3, $4}'
    else
        echo -e "  ${DIM}Unavailable for the same reason as above.${RESET}"
    fi
    press_any_key
}

# ==============================================================================
# SCREEN — EXPORT REPORT
# ==============================================================================

screen_export_report() {
    screen_header "EXPORT REPORT"
    collect_all_metrics
    update_session_stats

    echo -e "  Choose export format:"
    echo -e "  ${WHITE}1${RESET}) TXT"
    echo -e "  ${WHITE}2${RESET}) CSV"
    echo -e "  ${WHITE}3${RESET}) Both"
    echo ""
    local fmt_choice
    read -r -p "  Select an option [1-3]: " fmt_choice

    case "$fmt_choice" in
        1)
            local txt_path
            txt_path=$(generate_report)
            echo ""
            echo -e "  ${GREEN}✔ TXT report saved:${RESET}"
            echo -e "  ${WHITE}${txt_path}${RESET}"
            ;;
        2)
            local csv_path
            csv_path=$(generate_csv_report)
            echo ""
            echo -e "  ${GREEN}✔ CSV report saved:${RESET}"
            echo -e "  ${WHITE}${csv_path}${RESET}"
            ;;
        3)
            local txt_path csv_path
            txt_path=$(generate_report)
            csv_path=$(generate_csv_report)
            echo ""
            echo -e "  ${GREEN}✔ Reports saved:${RESET}"
            echo -e "  ${WHITE}${txt_path}${RESET}"
            echo -e "  ${WHITE}${csv_path}${RESET}"
            ;;
        *)
            echo ""
            echo -e "  ${RED}Invalid option — export cancelled.${RESET}"
            ;;
    esac
    press_any_key
}

# ==============================================================================
# MAIN MENU
# ==============================================================================

main_menu() {
    local choice
    while true; do
        screen_header "LUMEXA GAME DASHBOARD v6.1"
        echo -e "${CYAN}          [ NON-ROOT · TRUTHFUL METRICS ]${RESET}"
        draw_line
        echo -e "  ${WHITE}1${RESET}) Live Monitor"
        echo -e "  ${WHITE}2${RESET}) Game Mode          $( [ "$GAME_MODE" -eq 1 ] && echo -e "${GREEN}[ON]${RESET}" || echo -e "${DIM}[off]${RESET}" )"
        echo -e "  ${WHITE}3${RESET}) Network Analyzer"
        echo -e "  ${WHITE}4${RESET}) Device Health"
        echo -e "  ${WHITE}5${RESET}) Game Recommendations"
        echo -e "  ${WHITE}6${RESET}) Performance History"
        echo -e "  ${WHITE}7${RESET}) Process Viewer"
        echo -e "  ${WHITE}8${RESET}) Export Report"
        echo -e "  ${WHITE}0${RESET}) Exit"
        draw_line
        read -r -p "  Select an option: " choice

        # Trim whitespace so accidental spaces don't count as invalid input.
        choice="$(echo "$choice" | tr -d '[:space:]')"

        case "$choice" in
            1) screen_live_monitor ;;
            2) screen_game_mode ;;
            3) screen_network_analyzer ;;
            4) screen_device_health ;;
            5) screen_recommendations ;;
            6) screen_history ;;
            7) screen_process_viewer ;;
            8) screen_export_report ;;
            0|q|Q) return ;;
            m|M) : ;;   # already at main menu — no-op
            "") : ;;    # empty Enter — just redraw the menu
            *)
                echo -e "  ${RED}Invalid option: '${choice}'. Please choose 0-8.${RESET}"
                sleep 1
                ;;
        esac
    done
}

# ==============================================================================
# STARTUP
# ==============================================================================

screen_header "LUMEXA GAME DASHBOARD v6.1"
echo -e "${CYAN}          [ NON-ROOT · TRUTHFUL METRICS ]           ${RESET}"
sleep 0.4

echo -e "${WHITE}[INFO] Lowering Termux's own scheduling priority...${RESET}"
# This is real and non-root-safe: renice only affects THIS Termux process ($$),
# telling the Android scheduler this process can yield CPU time to others
# (like your foreground game). It does NOT touch any other app or the kernel.
renice -n 19 -p $$ >/dev/null 2>&1
echo -e "${GREEN}[OK] Termux background priority lowered.${RESET}"
sleep 0.3

# NOTE ON ROOT-ONLY OPERATIONS (intentionally NOT run):
#   sync && echo 3 > /proc/sys/vm/drop_caches
#   -> Requires root. On non-root Android this silently fails and clears
#      nothing. There is no safe non-root equivalent for dropping kernel
#      page cache, so this dashboard does not pretend to do it.
#   "GPU Boost" / "FPS Boost" / real-time FPS counters / writable CPU governor
#   -> These required either root or an ADB-shell-only permission level that
#      a regular Termux app is not granted. Removed or honestly labeled N/A
#      rather than faked.

echo -e "${WHITE}[INFO] Preparing gaming toolkit...${RESET}"
sleep 0.3
echo -e "${YELLOW}[TIP] Manually clear background apps from Recent Apps before playing.${RESET}"
sleep 0.5

mkdir -p "$LOG_DIR" 2>/dev/null
init_logging
init_sessions_file
load_lifetime_stats

# On exit — normal (menu option 0) or Ctrl+C — save lifetime stats AND
# record this session in the session history, in that order so lifetime
# maxes reflect this session before it's written to history.
cleanup_and_exit() {
    save_lifetime_stats
    record_session_history
}
trap 'cleanup_and_exit' EXIT
trap 'echo -e "\n${CYAN}Interrupted — saving stats...${RESET}"; exit 0' INT

main_menu

echo -e "${CYAN}Session ended. Logs saved to $LOG_FILE${RESET}"
exit 0
