#!/usr/bin/env python3
"""M1 physical-device lifecycle check. Requires an unlocked device and open probe.

Reads only this debug app's logs/checkpoint; never clears system logs or app data.
The user must first open Mobile checks and tap 'Tap and save' at least once.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import time

PACKAGE = "org.nightshiftfm.spike"
ACTIVITY = PACKAGE + "/com.godot.game.GodotAppLauncher"


def latest_event_after(records, kind, count):
    matches = [e for e in records if e["event"] == kind]
    if not matches:
        return None
    record = matches[-1]
    counter = "pauses" if kind == "os_pause" else "resumes"
    return record if kind == "ready" or record[counter] > count else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--serial", required=True)
    parser.add_argument("--cycles", type=int, default=20)
    parser.add_argument("--output", type=Path, default=Path("builds/android/lifecycle.json"))
    args = parser.parse_args()
    adb = os.environ.get("ADB_BIN", "adb")

    def call(*command):
        return subprocess.check_output([adb, "-s", args.serial, *command], text=True, timeout=20).strip()

    def events(pid):
        result = []
        for line in call("logcat", "-d", "--pid=" + pid, "-s", "godot:I").splitlines():
            if "M1_PROBE " in line:
                result.append(json.loads(line.split("M1_PROBE ", 1)[1]))
        return result

    def wait_event(pid, kind, count):
        until = time.monotonic() + 8
        while time.monotonic() < until:
            record = latest_event_after(events(pid), kind, count)
            if record is not None:
                return record
            time.sleep(0.1)
        raise RuntimeError("No new " + kind + "; ensure phone is unlocked and app is visible")

    if args.cycles < 1 or args.cycles > 100:
        raise RuntimeError("cycles must be 1..100")
    pid = call("shell", "pidof", PACKAGE)
    initial = json.loads(call("shell", "run-as", PACKAGE, "cat", "files/m1_probe.json"))
    if initial["taps"] < 1:
        raise RuntimeError("Open Mobile checks and tap 'Tap and save' before running")
    report = {"model": call("shell", "getprop", "ro.product.model"),
              "android": call("shell", "getprop", "ro.build.version.release"),
              "emulator": call("shell", "getprop", "ro.kernel.qemu") == "1", "cycles": [], "status": "RUNNING"}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    for index in range(args.cycles):
        before = events(pid)
        # Logcat may rotate old records; use app counters, never historical line counts.
        pauses = max(e["pauses"] for e in before)
        resumes = max(e["resumes"] for e in before)
        call("shell", "input", "keyevent", "KEYCODE_HOME")
        paused = wait_event(pid, "os_pause", pauses)
        time.sleep(0.4)
        call("shell", "am", "start", "-a", "android.intent.action.MAIN", "-c",
             "android.intent.category.LAUNCHER", "-n", ACTIVITY)
        resumed = wait_event(pid, "os_resume", resumes)
        if call("shell", "pidof", PACKAGE) != pid:
            raise RuntimeError("Process unexpectedly restarted during background cycle")
        if paused["active_seconds"] != resumed["active_seconds"] or resumed["paused_drift"] != 0:
            raise RuntimeError("Counter advanced while paused")
        if resumed["instances"] != 1 or resumed["pauses"] != paused["pauses"]:
            raise RuntimeError("Duplicate scene or lifecycle transition")
        report["cycles"].append({"cycle": index + 1, "pause": paused, "resume": resumed})
        args.output.write_text(json.dumps(report, indent=2) + "\n")
        print("PASS: physical lifecycle cycle", index + 1, flush=True)
        time.sleep(0.15)
    saved = json.loads(call("shell", "run-as", PACKAGE, "cat", "files/m1_probe.json"))
    call("shell", "am", "force-stop", PACKAGE)
    call("shell", "am", "start", "-n", ACTIVITY)
    time.sleep(1)
    new_pid = call("shell", "pidof", PACKAGE)
    restored = wait_event(new_pid, "ready", 0)
    if restored["taps"] != saved["taps"] or restored["active_seconds"] != saved["active_seconds"]:
        raise RuntimeError("Force-stop/relaunch did not restore the committed checkpoint")
    report["recovery"] = {"saved": saved, "restored": restored, "process_changed": new_pid != pid}
    if not report["recovery"]["process_changed"]:
        raise RuntimeError("Force-stop test did not create a new process")
    report["status"] = "PASS"
    args.output.write_text(json.dumps(report, indent=2) + "\n")
    print("PASS: force-stop/relaunch restores checkpoint; report:", args.output)


if __name__ == "__main__":
    main()
