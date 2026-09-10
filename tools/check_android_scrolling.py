#!/usr/bin/env python3
"""Send OS touchscreen swipes to isolated production-page fixtures on Android."""
import argparse, json, re, subprocess, time, xml.etree.ElementTree as ET
from pathlib import Path
p = argparse.ArgumentParser()
p.add_argument('--adb', required=True); p.add_argument('--serial', required=True)
p.add_argument('--controls-only', action='store_true')
p.add_argument('--output', type=Path, required=True); p.add_argument('--expect-broken', action='store_true')
a = p.parse_args(); a.output.mkdir(parents=True,exist_ok=True)
package = 'org.nightshiftfm.scrollqa'; prefix = [a.adb,'-s',a.serial]
def adb(*cmd): return subprocess.check_output(prefix+list(cmd))
def telemetry(): return json.loads(adb('shell','run-as',package,'cat','files/scroll_telemetry.json'))
adb('shell','am','force-stop',package)
adb('shell','am','start','-W','-n',package+'/com.godot.game.GodotAppLauncher')
time.sleep(1)
adb('shell','uiautomator','dump','/sdcard/nightshift-scroll-window.xml')
xml = ET.fromstring(adb('shell','cat','/sdcard/nightshift-scroll-window.xml'))
surface = next(n for n in xml.iter('node') if n.get('class')=='android.view.SurfaceView' and n.get('package')==package)
bounds = list(map(int,re.findall(r'\d+',surface.get('bounds'))))
rows = []
if a.controls_only:
    previous=json.loads((a.output/'android.json').read_text())
    rows=[row for row in previous['rows'] if 'action' not in row]
    assert all(row['pass'] for row in rows), 'Only reuse an entirely passing swipe sweep'
names = ['route','hardware','achievements','codex','records','modes','enemies','logs','equipment','settings','draft','details','report','recruit','recovery','patchboard','mixer','mixer-connections','results']
for index,name in enumerate([] if a.controls_only else names[:1] if a.expect_broken else names):
    for area in (['margin','text','card','outside'] if index >= 10 else ['margin','text','card']):
        command = f'{index}:{area}:{time.monotonic_ns()}'
        subprocess.run(prefix+['shell',f"run-as {package} sh -c 'cat > files/scroll_command.txt'"],input=command.encode(),check=True)
        for attempt in range(30):
            time.sleep(.1)
            before = telemetry()
            if before['command']==command: break
        else: raise RuntimeError('QA page did not open')
        time.sleep(.35); before = telemetry()
        start,end = before['points'][area]
        start=[round(start[0]+bounds[0]),round(start[1]+bounds[1])]
        end=[round(end[0]+bounds[0]),round(end[1]+bounds[1])]
        adb('shell','input','touchscreen','swipe',*map(str,start+end),'450')
        time.sleep(.15); after = telemetry()
        expected = min(100,max(0,before['max']))
        passed = after['command']==command and after['scroll']>=expected
        rows.append({'page':name,'area':area,'before':before['scroll'],'after':after['scroll'],'max_scroll':before['max'],'expected_min':expected,'start':start,'end':end,'pass':passed})
        print(f"{'PASS' if passed else 'FAIL'}: {name}/{area} {after['scroll']}/{expected}",flush=True)
        if name in ['route','draft','results'] and area=='card':
            (a.output/(name+'-scrolled.png')).write_bytes(adb('exec-out','screencap','-p'))
    (a.output/'android.json').write_text(json.dumps({'device_kind':'physical Android device' if not a.serial.startswith('emulator-') else 'Android emulator','surface_bounds':bounds,'expected_broken':a.expect_broken,'rows':rows},indent=2))
# Verify ordinary production controls after the swipe sweep.
if not a.expect_broken:
    for index,key in [(10,'detail_open'),(9,'toggled'),(8,'popup'),(16,'level')]:
        command = f'{index}:tap:{time.monotonic_ns()}'
        subprocess.run(prefix+['shell',f"run-as {package} sh -c 'cat > files/scroll_command.txt'"],input=command.encode(),check=True)
        time.sleep(.8); before=telemetry()
        assert before['command']==command
        if key=='level':
            start,end=before['fader']
            coords=[round(start[0]+bounds[0]),round(start[1]+bounds[1]),round(end[0]+bounds[0]),round(end[1]+bounds[1])]
            adb('shell','input','touchscreen','swipe',*map(str,coords),'450')
        else:
            point=before['tap']
            adb('shell','input','tap',str(round(point[0]+bounds[0])),str(round(point[1]+bounds[1])))
        time.sleep(.3); after=telemetry()
        passed=after.get(key)!=before.get(key)
        if key=='level': passed=passed and after['scroll']==before['scroll']
        rows.append({'page':names[index],'action':key,'before':before.get(key),'after':after.get(key),'pass':passed})
        print(f"{'PASS' if passed else 'FAIL'}: {names[index]} tap/drag control {key}",flush=True)
        if key=='popup': adb('shell','input','keyevent','4')
    (a.output/'android.json').write_text(json.dumps({'device_kind':'physical Android device' if not a.serial.startswith('emulator-') else 'Android emulator','surface_bounds':bounds,'expected_broken':False,'controls_rechecked_with_paused_fixture':a.controls_only,'rows':rows},indent=2))
failures = sum(not row['pass'] for row in rows)
print(f'RESULT: {len(rows)} Android OS swipe checks; {failures} failures',flush=True)
raise SystemExit(0 if (failures>0 if a.expect_broken else failures==0) else 1)
