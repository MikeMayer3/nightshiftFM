#!/usr/bin/env python3
"""OS input against isolated release-audit package. Never writes player data."""
import argparse, json, subprocess, time, re, xml.etree.ElementTree as ET
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--adb',required=True);p.add_argument('--serial',required=True);p.add_argument('--output',type=Path,required=True);p.add_argument('--result-save',type=Path,required=True);a=p.parse_args()
pkg='org.nightshiftfm.releaseaudit';base=[a.adb,'-s',a.serial];a.output.mkdir(parents=True,exist_ok=True)
checks=[];performance={};completed=False;origin=[0,0]
def run(*args,data=None):return subprocess.check_output(base+list(args),input=data,timeout=30)
def state():return json.loads(run('exec-out','run-as',pkg,'cat','files/qa_ui.json'))
def check(ok,label):
 checks.append({'passed':bool(ok),'check':label});print(('PASS: ' if ok else 'FAIL: ')+label,flush=True)
 assert ok,label
def wait_for(predicate,seconds=15):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  s=state()
  if predicate(s):return s
  time.sleep(.3)
 raise RuntimeError('Timed out waiting for state')
def tap(text=None,path=None):
 for attempt in range(25):
  buttons=state()['buttons'];b=next((b for b in reversed(buttons) if not b['disabled'] and (' '.join(b['text'].split())==' '.join(text.split()) if path is None else b['path'].endswith(path))),None)
  if b is None:time.sleep(.25);continue
  if 'scroll' in b:
   coords=[str(round(x+origin[i%2])) for i,x in enumerate(b['scroll']+b['end'])];run('shell','input','swipe',*coords,'400');time.sleep(.6);continue
  run('shell','input','tap',*[str(round(x+origin[i])) for i,x in enumerate(b['point'])]);time.sleep(.4);return
 raise RuntimeError('Button unreachable: '+str(text or path))
def back():run('shell','input','keyevent','4');time.sleep(.5)
def capture(name):
 focus=run('shell','dumpsys','activity','activities').decode()
 assert any(pkg in line for line in focus.splitlines() if 'topResumedActivity=' in line or 'mResumedActivity:' in line),'QA is not foreground; do not capture unrelated screen'
 (a.output/(name+'.png')).write_bytes(run('exec-out','screencap','-p'))
def launch():
 run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher');time.sleep(2)
 run('shell','uiautomator','dump','/sdcard/release-audit-ui.xml')
 xml=ET.fromstring(run('shell','cat','/sdcard/release-audit-ui.xml'))
 node=next(n for n in xml.iter('node') if n.get('class')=='android.view.SurfaceView' and n.get('package')==pkg)
 origin[:]=[int(v) for v in re.findall(r'\d+',node.get('bounds'))][:2]
try:
 run('shell','am','force-stop',pkg)
 launch()
 wait_for(lambda s:s['page']==0)
 tap('New broadcast');tap('Choose equipment →');tap('Go live →')
 s=wait_for(lambda s:s['page']==4 and not s['save_failed']);check(s['wave']==1,'native fresh menu to campaign to equipment to combat')
 tap(path='/Header/Pause');wait_for(lambda s:s['paused'])
 tap('Mixer');wait_for(lambda s:s['mixer_open']);capture('paused-mixer')
 back();s=wait_for(lambda s:not s['mixer_open']);check(s['manual_pause'] and s['paused'],'OS Back closes paused mixer and retains pause')
 before=s['seconds'];time.sleep(1);check(state()['seconds']==before,'paused combat clock does not advance')
 tap('Radio & accessibility');back();check(state()['paused'],'OS Back exits settings without resuming')
 tap('Resume');wait_for(lambda s:not s['paused']);tap('Mixer');back();check(not state()['mixer_open'] and not state()['manual_pause'],'OS Back closes live mixer')
 print('Waiting for earned Tuned decision...',flush=True)
 s=wait_for(lambda s:len(s.get('cards',[]))>0,90);performance=s.get('frame_ms',{});capture('earned-upgrades')
 offers=s['offers'];choices=s['choices'];tap('i');check(not state()['cards'],'native info opens without buying upgrade')
 # Force-stop and Continue replays the persisted real decision, including offers.
 run('shell','am','force-stop',pkg);launch();tap('Continue saved mission')
 s=wait_for(lambda s:len(s.get('cards',[]))>0);check(s['offers']==offers and s['choices']==choices and not s['save_failed'],'force-stop Continue restores actual decision offers')
 point=s['cards'][-1];run('shell','input','tap',*[str(round(x+origin[i])) for i,x in enumerate(point)]);s=wait_for(lambda s:s['choices']==choices+1);check(not s['save_failed'],'third compact card selects once through OS tap')
 capture('post-upgrade')
 # Load the completed save earned by the desktop simulation, solely into this QA package.
 run('shell','am','force-stop',pkg)
 run('exec-in','run-as',pkg,'tee','files/release_audit.json',data=a.result_save.read_bytes())
 launch();tap('Continue saved mission');s=wait_for(lambda s:s.get('phase') in [2,3]);check(not s['save_failed'],'earned completed save restores on physical Android')
 tap('Contribution report');check(state()['report_open'],'native contribution report opens');capture('contribution-report')
 back();check(not state()['report_open'],'OS Back returns contribution report to results');capture('results')
 tap('Retry broadcast');s=wait_for(lambda s:s.get('phase')==1);check(s['choices']==0 and s['hull']==100 and not s['save_failed'],'native Retry starts a fresh mission')
 pid=run('shell','pidof',pkg).decode().strip();log=run('logcat','-d','--pid='+pid).decode()
 errors=[line for line in log.splitlines() if any(m in line for m in ['SCRIPT ERROR:','ERROR:','FATAL EXCEPTION'])]
 check(not errors,'current QA process has no engine or Android crash errors')
 completed=True
finally:
 (a.output/'checks.json').write_text(json.dumps({'checks':checks,'passed':completed and bool(checks) and all(x['passed'] for x in checks),'frame_ms':performance,'device_kind':'emulator' if a.serial.startswith('emulator-') else 'physical','scope':'Android OS taps and Back keys; isolated QA package. Completed-result save earned by desktop simulation. Short early-wave timing only, not thermal or full device playthrough acceptance.'},indent=2)+'\n')
