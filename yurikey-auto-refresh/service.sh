#!/system/bin/sh
# Runs YuriKey action every 7 days automatically, then restarts GMS so the
# new fingerprint/keybox take effect without a manual reboot.

TIMESTAMP_FILE=/data/adb/yurikey_auto_last_run
YURIKEY_ACTION=/data/adb/modules/Yurikey/action.sh
LOG=/data/adb/yurikey_auto_refresh.log
INTERVAL=604800   # 7 days in seconds
CHECK_EVERY=21600 # re-check every 6 hours

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"
}

run_refresh() {
    log "Starting YuriKey refresh"

    if [ ! -f "$YURIKEY_ACTION" ]; then
        log "ERROR: $YURIKEY_ACTION not found — is YuriKey module installed?"
        return 1
    fi

    sh "$YURIKEY_ACTION" >> "$LOG" 2>&1
    local rc=$?

    if [ $rc -ne 0 ]; then
        log "WARNING: action.sh exited with code $rc"
    else
        log "YuriKey action completed successfully"
    fi

    # Restart GMS so the new fingerprint/keybox apply without a full reboot.
    # Kill the unstable process — Android will restart it automatically.
    local gms_pid
    gms_pid=$(pidof com.google.android.gms.unstable 2>/dev/null)
    if [ -n "$gms_pid" ]; then
        kill "$gms_pid" 2>/dev/null && log "Killed GMS unstable (pid $gms_pid) — will auto-restart"
    fi

    # Record the time this ran
    date +%s > "$TIMESTAMP_FILE"
    log "Timestamp saved"
}

# Wait for boot to settle and for YuriKey module to be fully loaded
sleep 120

log "Auto-refresh daemon started (interval=${INTERVAL}s, check every ${CHECK_EVERY}s)"

while true; do
    NOW=$(date +%s)

    if [ ! -f "$TIMESTAMP_FILE" ]; then
        log "No timestamp found — running first refresh"
        run_refresh
    else
        LAST=$(cat "$TIMESTAMP_FILE" 2>/dev/null)
        if [ -z "$LAST" ]; then
            log "Corrupt timestamp — resetting"
            run_refresh
        else
            DIFF=$((NOW - LAST))
            DAYS=$((DIFF / 86400))
            log "Last run ${DAYS} day(s) ago (${DIFF}s)"
            if [ "$DIFF" -ge "$INTERVAL" ]; then
                log "7+ days since last run — refreshing"
                run_refresh
            fi
        fi
    fi

    sleep "$CHECK_EVERY"
done
