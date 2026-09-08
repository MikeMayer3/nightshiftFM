#!/usr/bin/env python3
"""Drive an isolated QA APK with real adb taps at normal game speed.

The observer exposes current rendered controls and a cluster-aim suggestion.
Upgrade indices use a separate seeded uniform RNG in the observer. No rerolls,
checkpoint restoration, time scaling, combat mutations, or direct purchases.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time
import re
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--adb', required=True)
parser.add_argument('--serial', required=True)
parser.add_argument('--seed', type=int, required=True)
parser.add_argument('--main', choices=['pulse','sweep','burst'], default='pulse')
parser.add_argument('--shield', choices=['capacitor','relay','feedback'], default='capacitor')
parser.add_argument('--support', choices=['arc_aerial','bass_driver','static_net','echo_deck','needle_swarm','reverb_well'], default='arc_aerial')
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
package = 'org.nightshiftfm.turretqa'
args.output.mkdir(parents=True, exist_ok=True)

def adb(*command, binary=False):
    return subprocess.check_output([args.adb, '-s', args.serial, *command], timeout=20, text=not binary)

def screenshot(name):
    (args.output / name).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))

adb('shell', 'am', 'force-stop', package)
# Only the dedicated QA package is written; player saves are never accessed.
adb('shell', 'run-as', package, 'sh', '-c', f"'mkdir -p files; echo {args.seed} > files/qa_seed.txt; rm -f files/qa_telemetry.json files/qa_mission.json files/qa_mission.json.bak files/qa_mission.json.tmp'")
loadout = json.dumps({'main': args.main, 'shield': args.shield, 'support': args.support}, separators=(',', ':'))
subprocess.run([args.adb, '-s', args.serial, 'shell', 'run-as', package, 'sh', '-c', "'cat > files/qa_loadout.json'"], input=loadout, text=True, check=True)
adb('shell', 'am', 'start', '-n', package + '/com.godot.game.GodotAppLauncher')
started = time.monotonic()
last_action = None
last_action_time = 0
last_wave = -1
last_report = -15
support_capture = False
surface_origin = None
random_choices = {}
with (args.output / 'telemetry.jsonl').open('w') as log:
    while time.monotonic() - started < 1200:
        time.sleep(0.45)
        try:
            row = json.loads(adb('shell', 'run-as', package, 'cat', 'files/qa_telemetry.json'))
        except (subprocess.CalledProcessError, json.JSONDecodeError):
            continue
        row['wall_seconds'] = round(time.monotonic() - started, 3)
        if surface_origin is None:
            # Godot reports its inset rendering surface as a window at (0,0).
            # Android input uses the full display. Read the actual SurfaceView
            # bounds instead of guessing status-bar height from model/density.
            adb('shell', 'uiautomator', 'dump', '/sdcard/nightshift-qa-window.xml')
            xml = adb('shell', 'cat', '/sdcard/nightshift-qa-window.xml')
            surfaces = [n for n in ET.fromstring(xml).iter('node') if n.get('class') == 'android.view.SurfaceView' and n.get('package') == package]
            if len(surfaces) != 1:
                raise RuntimeError('Cannot identify the game rendering surface')
            bounds = [int(v) for v in re.findall(r'\d+', surfaces[0].get('bounds'))]
            surface_origin = bounds[:2]
            (args.output / 'surface.xml').write_text(xml)
            print('ANDROID SURFACE ' + str(bounds), flush=True)
            continue  # Fetch fresh targets after the slow accessibility dump.
        log.write(json.dumps(row) + '\n')
        log.flush()
        if row.get('action') == 'upgrade':
            random_choices[row['choices']] = row['offers'][row['index']]
        if row['save_failed']:
            raise RuntimeError('Android checkpoint save failed')
        if row['seconds'] >= last_report + 15:
            print(json.dumps({k: row[k] for k in ('seed','wave','seconds','hull','kills','bursts','choices','fps','wall_seconds')}), flush=True)
            last_report = row['seconds']
        if row['wave'] != last_wave and row['wave'] > 0 and not row.get('action') == 'upgrade':
            screenshot(f"wave-{row['wave']:02d}.png")
            last_wave = row['wave']
        if len(row['equipped']) == 5 and not support_capture and row['phase'] == 1:
            screenshot('all-supports.png')
            support_capture = True
        if row['finished']:
            screenshot('result.png')
            mismatches = [{'index': i, 'accepted': decision['id'], 'random': random_choices.get(i)}
                          for i, decision in enumerate(row['decisions'])
                          if decision['id'] != random_choices.get(i)]
            row['random_choice_audit'] = {'pass': not mismatches, 'count': len(row['decisions']), 'mismatches': mismatches}
            (args.output / 'result.json').write_text(json.dumps(row, indent=2))
            if mismatches:
                raise RuntimeError('A stale tap selected an unaudited upgrade; this is not a valid uniform-random sample')
            print('FINISHED ' + json.dumps(row), flush=True)
            break
        action = row.get('action')
        if action:
            key = (action, row['choices'] if action == 'upgrade' else row['shield_wait'] if action == 'shield' else row['bursts'])
            if key != last_action or time.monotonic() - last_action_time > 1.0:
                x, y = (round(v) for v in row['point'])
                x += surface_origin[0]
                y += surface_origin[1]
                if action == 'upgrade':
                    print(f"RANDOM CHOICE {row['choices']}: {row['offers'][row['index']]}", flush=True)
                adb('shell', 'input', 'tap', str(x), str(y))
                last_action = key
                last_action_time = time.monotonic()
    else:
        screenshot('timeout.png')
        raise RuntimeError('Emulator run exceeded 20 minutes')
