# Qin F21 Pro — Root + Play Integrity Setup

Complete guide and files for rooting the **DuoQin F21 Pro** (MT6761, Android 11) with full Play Integrity (Basic + Device + Strong) on Verizon.

---

## Module stack

| Module | Version | Purpose |
|---|---|---|
| Magisk | 27.0 | Root |
| Zygisk Next (zygisksu) | 1.3.4 | Zygisk implementation |
| PlayIntegrityFork | v16 | Fingerprint spoofing |
| YuriKey | 3.0.5 | Keybox provisioning |
| TrickyStoreOSS | 2.1.0 | Keystore injection (HIDL Android 11) |
| **YuriKey Auto-Refresh** | 1.0 | Weekly automatic keybox/fingerprint renewal |

---

## YuriKey Auto-Refresh module

Play Integrity expires every few weeks as Google rotates keyboxes and fingerprints. The `yurikey-auto-refresh` module eliminates the need to manually tap the YuriKey Action button — it runs the refresh automatically every 7 days in the background.

### Install

Flash `yurikey-auto-refresh-v1.0.zip` in Magisk → Modules → Install from storage, then reboot.

Or via ADB:
```sh
adb push yurikey-auto-refresh-v1.0.zip /sdcard/
adb shell su -c "magisk --install-module /sdcard/yurikey-auto-refresh-v1.0.zip"
adb reboot
```

### How it works

- `service.sh` starts a background daemon at boot (after a 2-minute settle delay)
- Checks every 6 hours whether 7+ days have passed since the last refresh
- If so, runs YuriKey's `action.sh` — fetches a fresh Pixel Canary fingerprint and new keybox from the YuriKey server
- Kills the GMS unstable process so the new values take effect without a reboot
- Writes a timestamp to `/data/adb/yurikey_auto_last_run`

### Monitor it

```sh
adb shell su -c "cat /data/adb/yurikey_auto_refresh.log"
```

Successful run looks like:
```
2026-05-08 09:57:53 Meets Strong Integrity with Yurikey Manager✨✨
2026-05-08 09:57:53 YuriKey action completed successfully
2026-05-08 09:57:53 Timestamp saved
```

---

## SELinux fix (required for TrickyStoreOSS on Android 11)

TrickyStoreOSS injects into the `keystore` process via ptrace. On Android 11 HIDL Keymaster, SELinux blocks this unless the following rules are applied in `post-fs-data.sh`:

```sh
magiskpolicy --live \
  "allow system_file keystore unix_dgram_socket *" \
  "allow keystore system_file unix_dgram_socket *" \
  "allow keystore system_file file *" \
  "allow crash_dump keystore process *" \
  "allow magisk keystore process *" \
  "allow magisk keystore unix_dgram_socket *" \
  "allow adb_data_file keystore unix_dgram_socket *" \
  "allow adb_data_file keystore process *" \
  "allow system_file keystore process *" 2>/dev/null
```

Push via ADB:
```sh
adb push post-fs-data.sh /data/local/tmp/post-fs-data.sh
adb shell su -c "cp /data/local/tmp/post-fs-data.sh /data/adb/modules/tricky_store/post-fs-data.sh"
adb shell su -c "chmod 755 /data/adb/modules/tricky_store/post-fs-data.sh"
```

---

## Full setup guide

Step-by-step guide (including SP Flash Tool OS install, Verizon LTE band unlock, and root): [Notion guide](https://www.notion.so/gearsupply/F21-Guide-2a229a1508df80e7af46fd3ecc4ff8e1)

> **Never touch** nvdata / nvram / nvcfg / md1img_a partitions — these hold the Verizon LTE band unlock and IMEI.
