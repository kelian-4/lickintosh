#!/usr/bin/env bash
set -uo pipefail

EXCLUDE_REGEX='^(ps|awk|bash|sh|sleep|grep|cut|nproc|readlink|basename|cat|sort|head|find|dirname|mktemp|sample-processes\.sh|find-app-icon\.sh)$'

resolve_app_key() {
    local pid="$1"
    local comm="$2"
    local exe_path=""
    exe_path=$(readlink "/proc/$pid/exe" 2>/dev/null)
    local name=""
    if [ -n "$exe_path" ]; then
        name="${exe_path##*/}"
    fi
    if [ -z "$name" ]; then
        name="$comm"
    fi
    name="${name#.}"
    name="${name%-wrapped}"
    name="${name%.wrapped}"
    [ -z "$name" ] && name="unknown"
    echo "$name"
}

declare -A CPU_TICKS
declare -A MEM_KB
declare -A SWAP_KB

for stat_file in /proc/[0-9]*/stat; do
    [ -r "$stat_file" ] || continue
    pid="${stat_file#/proc/}"
    pid="${pid%/stat}"

    comm=""
    IFS= read -r comm < "/proc/$pid/comm" 2>/dev/null
    [[ "$comm" =~ $EXCLUDE_REGEX ]] && continue

    content=""
    IFS= read -r content < "$stat_file" 2>/dev/null
    [ -z "$content" ] && continue
    rest="${content##*) }"
    read -ra f <<< "$rest"
    utime="${f[11]:-0}"
    stime="${f[12]:-0}"

    appkey=$(resolve_app_key "$pid" "$comm")
    [[ "$appkey" =~ $EXCLUDE_REGEX ]] && continue

    CPU_TICKS[$appkey]=$(( ${CPU_TICKS[$appkey]:-0} + utime + stime ))

    rss_kb=0
    swap_kb=0
    if [ -r "/proc/$pid/smaps_rollup" ]; then
        while IFS= read -r line; do
            case "$line" in
                Pss:*)
                    read -r _ rss_kb _ <<< "$line"
                    ;;
                SwapPss:*)
                    read -r _ swap_kb _ <<< "$line"
                    ;;
            esac
        done < "/proc/$pid/smaps_rollup" 2>/dev/null
    elif [ -r "/proc/$pid/status" ]; then
        while IFS= read -r line; do
            case "$line" in
                VmRSS:*)
                    read -r _ rss_kb _ <<< "$line"
                    ;;
                VmSwap:*)
                    read -r _ swap_kb _ <<< "$line"
                    ;;
            esac
        done < "/proc/$pid/status" 2>/dev/null
    fi
    [ -z "$rss_kb" ] && rss_kb=0
    [ -z "$swap_kb" ] && swap_kb=0


    MEM_KB[$appkey]=$(( ${MEM_KB[$appkey]:-0} + rss_kb ))
    SWAP_KB[$appkey]=$(( ${SWAP_KB[$appkey]:-0} + swap_kb ))
done

for appkey in "${!CPU_TICKS[@]}"; do
    echo "$appkey;${CPU_TICKS[$appkey]};${MEM_KB[$appkey]:-0};${SWAP_KB[$appkey]:-0}"
done
