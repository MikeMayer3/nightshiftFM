#!/usr/bin/env python3
"""Physical OS taps on compact draft fixtures; never reads the owner's package."""
import argparse, json, re, subprocess, time, xml.etree.ElementTree as ET
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',required=True);p.add_argument('--output',required=True,type=Path);a=p.parse_args();a.output.mkdir(parents=True,exist_ok=True)
device_kind='Android emulator' if a.serial.startswith('emulator-') else 'physical Pixel'
pkg='org.nightshiftfm.scrollqa';prefix=[a.adb,'-s',a.serial]
def adb(*cmd):return subprocess.check_output(prefix+list(cmd),stderr=subprocess.PIPE)
def state():
 for attempt in range(60):
  try:return json.loads(adb('shell','run-as',pkg,'cat','files/scroll_telemetry.json'))
  except (subprocess.CalledProcessError,json.JSONDecodeError):time.sleep(.5)
 raise RuntimeError('QA telemetry was not ready within 30 seconds')
adb('shell','am','force-stop',pkg);adb('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');time.sleep(1)
adb('shell','uiautomator','dump','/sdcard/nightshift-compact-window.xml')
hierarchy=ET.fromstring(adb('shell','cat','/sdcard/nightshift-compact-window.xml'))
surface=next(n for n in hierarchy.iter('node') if n.get('class')=='android.view.SurfaceView' and n.get('package')==pkg)
bounds=list(map(int,re.findall(r'\d+',surface.get('bounds'))))
def tap(point):
 adb('shell','input','tap',str(round(point[0]+bounds[0])),str(round(point[1]+bounds[1])));time.sleep(.4)
rows=[]
for case in [10,19]:
 for text in ['normal','large']:
  command=f'{case}:{text}:{time.monotonic_ns()}'
  subprocess.run(prefix+['shell',f"run-as {pkg} sh -c 'cat > files/scroll_command.txt'"],input=command.encode(),check=True)
  for attempt in range(60):
   time.sleep(.1);before=state()
   if before['command']==command:break
  time.sleep(.5);before=state()
  assert before['command']==command
  checks={'three_choices':len(before['card_heights'])==3,'all_choices_visible':before['all_cards_visible'],'no_scroll_needed':before['max']<=0}
  (a.output/f'{case}-{text}.png').write_bytes(adb('exec-out','screencap','-p'))
  tap(before['tap']);detail=state();checks['details_open_without_purchase']=detail['detail_open'] and not detail['picked']
  tap(detail['back']);returned=state();checks['back_restores_three_choices']=len(returned['card_heights'])==3
  if case==19:
   tap(returned['card_taps'][2]);selected=state();checks['third_card_resolves_real_tuned_choice']=bool(selected['picked']) and selected['resolved']
  rows.append({'case':'actual Tuned threshold' if case==19 else 'branch/new instrument fixture','text':text,'card_heights':before['card_heights'],'checks':checks})
  print(json.dumps(rows[-1]),flush=True)
checks=sum(len(r['checks']) for r in rows);failures=sum(not v for r in rows for v in r['checks'].values())
(a.output/'android.json').write_text(json.dumps({'scope':device_kind+' OS taps in isolated QA package; real Tuned threshold and synthetic branch fixture.','checks':checks,'failures':failures,'cases':rows},indent=2))
print(f'RESULT: {checks} {device_kind} compact-upgrade checks; {failures} failures',flush=True)
raise SystemExit(1 if failures else 0)
