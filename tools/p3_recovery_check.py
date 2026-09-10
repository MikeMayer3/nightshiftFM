#!/usr/bin/env python3
"""Isolated emulator process-death checks; accelerated legal gameplay, no owner data."""
from pathlib import Path
import subprocess,time,json
root=Path(__file__).resolve().parents[1];out=root/'docs/evidence/P3-onboarding'
base=[str(Path.home()/'Library/Android/sdk/platform-tools/adb'),'-s','emulator-5554'];pkg='org.nightshiftfm.p3recovery';rows=[];nonce=0;evidence_name='emulator-recovery.json'
def run(*a,input=None):return subprocess.check_output(base+list(a),input=input,stderr=subprocess.STDOUT,timeout=45)
def read(name):return json.loads(run('exec-out','run-as',pkg,'cat','files/'+name))
def live():return read('p3_live.json')
def command(action):
 global nonce
 nonce+=1
 payload=json.dumps({'id':nonce,'action':action}).encode()
 run('exec-in','run-as',pkg,'tee','files/p3_command.tmp',input=payload)
 run('shell','run-as',pkg,'mv','files/p3_command.tmp','files/p3_command.json')
 return nonce
def wait(predicate,seconds=120):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  try:
   s=live()
   if predicate(s):return s
  except (subprocess.CalledProcessError,json.JSONDecodeError):pass
  time.sleep(.25)
 raise AssertionError('State timeout: '+str(live()))
def relaunch():run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher')
def checkpoint_case(label):
 n=command('hold');before=wait(lambda s:s['command_id']==n)
 saved=read('p3_recovery_mission.json');prefs=read('presentation_v1.json') if before['hint_seen'] else None
 run('shell','am','force-stop',pkg)
 run('shell','run-as',pkg,'rm','files/p3_live.json');relaunch()
 after=wait(lambda s:s['command_id']==n)
 assert not after['save_failed'] and not after['recovery_required'],after
 assert after['run_id']==saved['run']['run_id']
 assert after['accepted']==saved['run']['draft']['accepted']
 assert abs(after['elapsed']-saved['run']['values']['elapsed'])<.00001
 assert after['completed']==saved['profile']['completed'] and after['rewarded']==saved['profile']['rewarded_runs']
 assert after['hint_seen']==before['hint_seen']
 row={'case':label,'before':before,'after':after,'saved_phase':saved['run']['values']['phase'],'saved_elapsed':saved['run']['values']['elapsed'],'pass':True}
 rows.append(row);(out/evidence_name).write_text(json.dumps(rows,indent=2)+'\n');print(label,'PASS',flush=True)
 (out/('emulator-'+label.replace(' ','-')+'.png')).write_bytes(run('exec-out','screencap','-p'))

def run_standard():
 relaunch();wait(lambda s:True)
 command('combat');wait(lambda s:s['elapsed']>=3)
 checkpoint_case('combat')
 command('draft');wait(lambda s:s['phase']==4)
 checkpoint_case('draft')
 old=live()['choices'];command('accept');wait(lambda s:s['choices']==old+1)
 checkpoint_case('accepted choice')
 command('finish');wait(lambda s:s['phase'] in [2,3],seconds=180)
 checkpoint_case('results');checkpoint_case('results again')
 # OS background/foreground while on a saved result cannot grant another reward.
 before=live();run('shell','input','keyevent','KEYCODE_HOME');time.sleep(2);relaunch();time.sleep(1);after=live()
 assert before['completed']==after['completed'] and before['rewarded']==after['rewarded']
 rows.append({'case':'home foreground results','pass':True,'before_rewards':before['rewarded'],'after_rewards':after['rewarded']})
 (out/'emulator-recovery.json').write_text(json.dumps(rows,indent=2)+'\n')
 print('RESULT:',len(rows),'interruption cases PASS',flush=True)

def run_victory():
 global evidence_name
 evidence_name="emulator-victory-recovery.json"
 relaunch();wait(lambda s:True)
 previous=live()['completed']
 for attempt in range(3):
  n=command('restart');wait(lambda s:s['command_id']==n and s['phase']==0)
  command('finish');result=wait(lambda s:s['phase'] in [2,3],seconds=240)
  print('Legal run',attempt,'phase',result['phase'],'completed',result['completed'],flush=True)
  if result['phase']==2:break
 assert result['phase']==2,'No earned victory in three legal runs'
 assert result['completed']==previous+1
 checkpoint_case('earned victory');checkpoint_case('earned victory again')
 print('RESULT: earned victory reward preserved exactly once',flush=True)

def run_lifecycle():
 global nonce
 nonce=int(time.time())
 relaunch();wait(lambda s:True)
 n=command('restart');wait(lambda s:s['command_id']==n and s['phase']==0)
 command('finish');wait(lambda s:s['elapsed']>10 and s['phase']==1)
 run('shell','input','keyevent','KEYCODE_HOME');time.sleep(2)
 first=live();time.sleep(3);second=live()
 assert first['elapsed']==second['elapsed'],'background simulation drift'
 n=command('hold');relaunch();after=wait(lambda s:s['command_id']==n)
 assert not after['save_failed'] and not after['recovery_required']
 assert after['elapsed']-second['elapsed']<4,'unexpected resume advance'
 rows.append({'case':'active Home and foreground','pass':True,'background_elapsed_first':first['elapsed'],'background_elapsed_second':second['elapsed'],'resumed_elapsed':after['elapsed'],'scope':'accelerated emulator driver, holding command applied after resume'})
 original=run('shell','settings','get','global','low_power').decode().strip()
 try:
  run('shell','cmd','battery','unplug')
  run('shell','cmd','power','set-mode','1')
  enabled=run('shell','settings','get','global','low_power').decode().strip()
  assert enabled=='1','emulator battery saver unavailable'
  n=command('restart');wait(lambda s:s['command_id']==n and s['phase']==0)
  command('combat');state=wait(lambda s:s['elapsed']>=3)
  assert not state['save_failed'] and not state['recovery_required']
  rows.append({'case':'emulated battery saver','pass':True,'low_power':enabled,'elapsed':state['elapsed'],'scope':'emulator unplug simulation, not physical battery drain'})
 finally:
  run('shell','cmd','power','set-mode','1' if original=='1' else '0')
  run('shell','cmd','battery','reset')
 (out/'emulator-lifecycle-power.json').write_text(json.dumps(rows,indent=2)+'\n')
 print('RESULT: active background and emulated battery saver PASS',flush=True)

if __name__ == "__main__":
 import argparse
 parser=argparse.ArgumentParser()
 parser.add_argument("--mode",choices=["standard","victory","lifecycle"],default="standard")
 args=parser.parse_args()
 {"standard":run_standard,"victory":run_victory,"lifecycle":run_lifecycle}[args.mode]()
