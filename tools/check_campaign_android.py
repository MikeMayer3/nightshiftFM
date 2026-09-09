#!/usr/bin/env python3
"""Native taps against isolated M7 UI observer; progress files are labeled fixtures."""
import argparse, json, re, subprocess, time, xml.etree.ElementTree as ET
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument('--adb', required=True)
p.add_argument('--serial', required=True)
p.add_argument('--output', type=Path, required=True)
a = p.parse_args()
package = 'org.nightshiftfm.campaignqa'
a.output.mkdir(parents=True, exist_ok=True)
checks = []
completed = False
origin = [0, 0]
def adb(*args, binary=False):
    return subprocess.check_output([a.adb, '-s', a.serial, *args], text=not binary, timeout=25)
def snapshot(name):
    (a.output / (name + '.png')).write_bytes(adb('exec-out', 'screencap', '-p', binary=True))
def row():
    return json.loads(adb('shell', 'run-as', package, 'cat', 'files/qa_ui.json'))
def check(condition, label):
    checks.append({'passed': bool(condition), 'check': label})
    print(('PASS ' if condition else 'FAIL ') + label, flush=True)
    assert condition, label
def launch(profile=None):
    adb('shell', 'am', 'force-stop', package)
    if profile is not None:
        adb('shell', 'run-as', package, 'sh', '-c', "'mkdir -p files; rm -f files/m3_mission.json.bak files/m3_mission.json.tmp files/qa_ui.json'")
        data = Path(f'docs/evidence/M7/profile-{profile}.json').read_text()
        subprocess.run([a.adb, '-s', a.serial, 'shell', 'run-as', package, 'sh', '-c', "'cat > files/m3_mission.json'"], input=data, text=True, check=True)
    adb('shell', 'am', 'start', '-n', package + '/com.godot.game.GodotAppLauncher')
    time.sleep(3)
    adb('shell', 'uiautomator', 'dump', '/sdcard/m7-ui.xml')
    xml = ET.fromstring(adb('shell', 'cat', '/sdcard/m7-ui.xml'))
    node = next(n for n in xml.iter('node') if n.get('class') == 'android.view.SurfaceView' and n.get('package') == package)
    origin[:] = [int(v) for v in re.findall(r'\d+', node.get('bounds'))][:2]
def tap(text):
    for _ in range(40):
        state = row()
        matches = [b for b in state['buttons'] if b['text'] == text]
        if not matches:
            time.sleep(.3)
            continue
        b = matches[0]
        if b['disabled']: raise RuntimeError('Disabled button: ' + text)
        if 'scroll' in b:
            x, y = [round(v + origin[i]) for i, v in enumerate(b['scroll'])]
            ex, ey = [round(v + origin[i]) for i, v in enumerate(b['end'])]
            adb('shell', 'input', 'swipe', str(x), str(y), str(ex), str(ey), '500')
            time.sleep(1.2)
            continue
        time.sleep(.4)
        fresh = next((item for item in row()['buttons'] if item['text'] == text), None)
        if fresh is None or any(abs(fresh['point'][i] - b['point'][i]) > 3 for i in range(2)):
            continue
        x, y = [round(v + origin[i]) for i, v in enumerate(fresh['point'])]
        adb('shell', 'input', 'tap', str(x), str(y))
        time.sleep(.5)
        return
    raise RuntimeError('Button not reachable: ' + text)
try:
    launch(0)
    check(not any('Continue' in b['text'] for b in row()['buttons']), 'profile-only save hides Continue')
    tap('New mission · Standard')
    snapshot('fresh-campaign')
    tap('Choose equipment →')
    check(row()['modules'] == [] and not any(b['text'] == 'Hot Tubes' for b in row()['buttons']), 'new campaign hides locked modules')
    snapshot('fresh-equipment')
    launch(12)
    tap('New mission · Standard')
    tap('Choose equipment →')
    tap('Hot Tubes')
    tap('Heavy Battery')
    state = row()
    check(state['modules'] == ['hot_tubes','heavy_battery'] and next(b for b in state['buttons'] if b['text'] == 'Long Mast')['disabled'], 'native module toggles enforce two slots')
    snapshot('two-modules')
    tap('Save 1')
    snapshot('preset-saved-preview')
    tap('Hot Tubes')
    check(row()['modules'] == ['heavy_battery'], 'current selection can change after preset save')
    tap('Load 1')
    check(row()['modules'] == ['hot_tubes','heavy_battery'], 'preset retains independent module choices')
    tap('Go live')
    state = row()
    check(state['campaign']['modules'] == ['hot_tubes','heavy_battery'] and state['capacity'] == 81.25 and not state['save_failed'], 'native launch applies selected module baseline and saves')
    snapshot('campaign-intermission')
    before = json.loads(adb('shell','run-as',package,'cat','files/m3_mission.json'))
    launch()
    tap('Continue saved mission')
    state = row()
    after = json.loads(adb('shell','run-as',package,'cat','files/m3_mission.json'))
    check(state['campaign'] == before['run']['campaign'] and after == before and not state['save_failed'], 'force-stop Continue preserves the complete intermission save')
    snapshot('continued')
    completed = True
finally:
    (a.output/'result.json').write_text(json.dumps({'passed': completed and bool(checks) and all(c['passed'] for c in checks), 'checks':checks, 'limits':'Isolated QA package; zero/12-clear profile fixtures, not earned native campaign clears'}, indent=2))
