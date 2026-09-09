#!/usr/bin/env python3
"""Isolated Pixel_10_Pro 1280x2856 QA input driver; see M8_M10_DELIVERY.md.
Does not target the player package. Screen coordinates are device-specific.
"""
from pathlib import Path
import subprocess,json,time
adb=str(Path.home()/'Library/Android/sdk/platform-tools/adb');base=[adb,'-s','emulator-5554'];e=Path(__file__).resolve().parents[1]/'docs/evidence/M8-M10'
last=None;events=[];start=time.monotonic()
while time.monotonic()-start<420:
 d=json.loads(subprocess.check_output(base+['exec-out','run-as','org.nightshiftfm.broadcastqa','cat','files/broadcast_qa.json']))
 s=d.get('run')
 if not s:break
 v=s['values'];key=(v['phase'],v['wave'],s['draft']['normal_count'])
 if key!=last:
  events.append({'wall_seconds':round(time.monotonic()-start,2),'phase':v['phase'],'wave':v['wave'],'picks':s['draft']['normal_count'],'hull':v['hull']});print(events[-1],flush=True)
  (e/('emulator-run-wave-%d-phase-%d.png'%(v['wave'],v['phase']))).write_bytes(subprocess.check_output(base+['exec-out','screencap','-p']))
  if v['phase'] in [4,5]: subprocess.run(base+['shell','input','tap','500','1030'],check=True)
  elif v['phase']==0:subprocess.run(base+['shell','input','tap','640','2490'],check=True)
  elif v['phase'] in [2,3]:break
  last=key
 time.sleep(1)
(e/'emulator-run-events.json').write_text(json.dumps(events,indent=2))
