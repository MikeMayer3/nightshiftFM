#!/usr/bin/env python3
"""Physical Pixel M2 smoke. Requires unlocked phone, app on menu, known canvas mapping.
ADB input is synthetic touch on physical hardware, not a human usability approval.
Does not clear app data, logcat, or change phone settings.
"""
import argparse
import json
from pathlib import Path
import subprocess
import time

p = argparse.ArgumentParser()
p.add_argument('--serial', required=True)
p.add_argument('--adb', required=True)
p.add_argument('--canvas-top', type=float, required=True)
p.add_argument('--canvas-scale', type=float, required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
a.output.mkdir(parents=True, exist_ok=True)
base = [a.adb, '-s', a.serial]

def adb(*args):
    return subprocess.check_output(base + list(args), text=True).strip()

pid = adb('shell', 'pidof', 'org.nightshiftfm.spike')
report = {'status': 'RUNNING', 'input': 'ADB synthetic touch on physical device', 'checks': []}

def events():
    log = adb('logcat', '-d', '--pid=' + pid, '-v', 'brief')
    result = []
    for line in log.splitlines():
        if 'M2_COMBAT ' in line:
            result.append(json.loads(line.split('M2_COMBAT ', 1)[1]))
    return result

def wait_event(name, predicate=lambda e: True, timeout=10):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        for e in reversed(events()):
            if e['event'] == name and predicate(e):
                return e
        time.sleep(0.2)
    raise AssertionError('Timed out: ' + name)

def check(condition, label):
    assert condition, label
    report['checks'].append({'result': 'PASS', 'check': label})
    print('PASS:', label, flush=True)

def tap(x, y):
    adb('shell', 'input', 'tap', str(round(x*a.canvas_scale)), str(round(a.canvas_top+y*a.canvas_scale)))

def capture(name):
    with (a.output / name).open('wb') as f:
        subprocess.run(base + ['exec-out', 'screencap', '-p'], stdout=f, check=True)

try:
    tap(360, 615)
    start = wait_event('start')
    check(start['instances'] == 1, 'Start opens one combat screen')
    tap(630, 60)
    paused = wait_event('manual_pause')
    time.sleep(1.0)
    capture('pixel-paused.png')
    check(paused['paused'], 'Touch Pause freezes combat')
    for cycle in range(20):
        adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
        time.sleep(0.15)
        adb('shell', 'am', 'start', '-n', 'org.nightshiftfm.spike/com.godot.game.GodotAppLauncher')
        time.sleep(0.2)
        current = events()[-1]
        check(current['seconds'] == paused['seconds'] and current['paused'] and current['instances'] == 1,
              f'Manual pause survives physical Home/resume {cycle+1} without time drift or duplicates')
    # Resume occupies y=806 in the fixed portrait overlay.
    tap(360, 806)
    resumed = wait_event('manual_resume')
    check(not resumed['paused'] and resumed['seconds'] == paused['seconds'], 'Touch Resume retains exact paused mission time')
    # Natural OS pause while combat is active.
    time.sleep(1)
    adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    bg = wait_event('lifecycle', lambda e: e['paused'] and e['seconds'] > resumed['seconds'])
    time.sleep(1)
    adb('shell', 'am', 'start', '-n', 'org.nightshiftfm.spike/com.godot.game.GodotAppLauncher')
    fg = wait_event('lifecycle', lambda e: not e['paused'] and e['seconds'] >= bg['seconds'])
    check(fg['seconds'] == bg['seconds'], 'Active mission freezes across OS background/resume')
    # Hold and drag over the arena long enough to observe focus in five-second telemetry.
    adb('shell', 'input', 'swipe', str(round(150*a.canvas_scale)), str(round(a.canvas_top+350*a.canvas_scale)),
        str(round(550*a.canvas_scale)), str(round(a.canvas_top+550*a.canvas_scale)), '6000')
    check(any(e['focus'] for e in events()), 'Physical touch hold/drag enters focus targeting')
    wait_event('tick', lambda e: not e['focus'] and e['seconds'] > 10, timeout=15)
    check(True, 'Touch release returns to auto-aim')
    tap(360, 1170)
    wait_event('shield')
    check(True, 'Touch shield button activates ability')
    capture('pixel-combat.png')
    first = wait_event('results', timeout=90)
    check(first['phase'] in [2, 3] and first['actors'] == 0, 'Physical mission reaches results and clears actors')
    capture('pixel-results.png')
    tap(360, 906)
    restart = wait_event('restart')
    check(restart['seconds'] == 0 and restart['hull'] == 100 and restart['shield'] == 50 and restart['actors'] == 0,
          'Touch Restart restores fresh mission baseline')
    time.sleep(2)
    # Same-process second result distinguished by number of result events.
    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        results = [e for e in events() if e['event'] == 'results']
        if len(results) >= 2:
            break
        time.sleep(1)
    check(len(results) == 2 and results[-1]['phase'] == 2 and results[-1]['instances'] == 1,
          'Second physical run wins using auto-aim with one results event per run')
    capture('pixel-auto-results.png')
    report['results'] = results
    report['status'] = 'PASS'
except Exception as error:
    report['status'] = 'FAIL'
    report['error'] = str(error)
    raise
finally:
    (a.output / 'pixel-combat-check.json').write_text(json.dumps(report, indent=2) + '\n')
    (a.output / 'pixel-combat-events.json').write_text(json.dumps(events(), indent=2) + '\n')
