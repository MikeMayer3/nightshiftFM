#!/usr/bin/env python3
"""Drive real Android touch input against the isolated, frozen touch QA APK."""
import argparse
import json
import re
from pathlib import Path
import subprocess
import time
import xml.etree.ElementTree as ET

parser = argparse.ArgumentParser()
parser.add_argument('--adb', required=True)
parser.add_argument('--serial', required=True)
parser.add_argument('--output', type=Path, required=True)
parser.add_argument('--expect-broken', action='store_true')
parser.add_argument('--from-button', action='store_true')
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
prefix = [args.adb, '-s', args.serial]

def adb(*command):
    return subprocess.check_output(prefix + list(command))

def sample(name):
    time.sleep(.3)
    row = json.loads(adb('shell', 'run-as', 'org.nightshiftfm.touchqa', 'cat', 'files/qa_telemetry.json'))
    (args.output / f'{name}.json').write_text(json.dumps(row, indent=2))
    return row

def motion(kind, point):
    adb('shell', 'input', 'touchscreen', 'motionevent', kind, str(round(point[0])), str(round(point[1])))

adb('shell', 'uiautomator', 'dump', '/sdcard/nightshift-touch-window.xml')
hierarchy = ET.fromstring(adb('shell', 'cat', '/sdcard/nightshift-touch-window.xml'))
surface = next(node for node in hierarchy.iter('node') if node.get('class') == 'android.view.SurfaceView' and node.get('package') == 'org.nightshiftfm.touchqa')
surface_bounds = [int(value) for value in re.findall(r'\d+', surface.get('bounds'))]
# Godot's screen transform is surface-relative on this Android backend.
# Obtain its origin from Android instead of mistaking the status bar for game UI.
def physical(point):
    return [point[0] + surface_bounds[0], point[1] + surface_bounds[1]]

before = sample('initial')
assert before['uses'] == 0 and not before['paused'] and before['actors'], before
start = physical(before['button'] if args.from_button else before['center'])
target = physical(before['actors'][2]['pixel'])
motion('DOWN', start)
down = sample('down')
motion('MOVE', target)
move = sample('move')
(args.output / 'aim.png').write_bytes(adb('exec-out', 'screencap', '-p'))
motion('UP', target)
up = sample('up')
(args.output / 'released.png').write_bytes(adb('exec-out', 'screencap', '-p'))
aim = before['actors'][2]['position']
checks = {
    'down_state_correct': not down['focus'] if args.from_button else down['focus'],
    'drag_tracks_target': move['focus'] and max(abs(a-b) for a, b in zip(move['point'], aim)) < 2,
    'release_fires_once': up['uses'] == 1 and up['kills'] == 5,
    'release_clears_aim': not up['focus'],
}
result = {'serial': args.serial, 'surface_bounds': surface_bounds, 'gesture': [start, target], 'checks': checks, 'from_button': args.from_button, 'expected_broken': args.expect_broken}
(args.output / 'result.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))
if args.expect_broken:
    assert not checks['drag_tracks_target'] and not checks['release_fires_once']
else:
    assert all(checks.values()), checks
