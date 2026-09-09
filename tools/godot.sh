#!/bin/sh
# POSIX wrapper; works from any working directory, including paths with spaces.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -z "${GODOT_BIN:-}" ]; then
    echo 'NOT RUN: set GODOT_BIN to the Godot 4.7.2 standard editor executable.' >&2
    exit 127
fi
if ! command -v "$GODOT_BIN" >/dev/null 2>&1; then
    echo "NOT RUN: GODOT_BIN is not executable: $GODOT_BIN" >&2
    exit 127
fi
expected=$(cat "$project_dir/tools/engine-version.txt")
actual=$("$GODOT_BIN" --version)
case "$actual" in
    "$expected"|"$expected".*) ;;
    *) echo "FAIL: engine mismatch; expected $expected (standard), got $actual" >&2; exit 2 ;;
esac
case "${1:-help}" in
    version) printf '%s\n' "$actual" ;;
    import) exec "$GODOT_BIN" --headless --path "$project_dir" --import ;;
    test) shift; exec "$GODOT_BIN" --headless --path "$project_dir" --script res://tests/test_runner.gd -- "$@" ;;
    smoke) exec "$GODOT_BIN" --headless --path "$project_dir" --quit-after 10 ;;
    run) exec "$GODOT_BIN" --path "$project_dir" ;;
    editor) exec "$GODOT_BIN" --path "$project_dir" --editor ;;
    android-debug)
        mkdir -p "$project_dir/builds/android"
        exec "$GODOT_BIN" --headless --path "$project_dir" --export-debug 'Android Debug' "$project_dir/builds/android/nightshift-m7.apk" ;;
    ios-project)
        mkdir -p "$project_dir/builds/ios"
        exec "$GODOT_BIN" --headless --path "$project_dir" --export-debug 'iOS Xcode' "$project_dir/builds/ios/NightshiftM1.zip" ;;
    *) echo 'Usage: tools/godot.sh {version|import|test [--intentional-failure|--quit-smoke]|smoke|run|editor|android-debug|ios-project}' >&2; exit 2 ;;
esac
