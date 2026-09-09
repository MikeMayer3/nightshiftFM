#!/usr/bin/env python3
"""Isolated Pixel_10_Pro 1280x2856 QA input driver; see M8_M10_DELIVERY.md.
Does not target the player package. Screen coordinates are device-specific.
"""
from pathlib import Path
import subprocess,json,time,hashlib
r=Path(__file__).resolve().parents[1];e=r/'docs/evidence/M8-M10';base=[str(Path.home()/'Library/Android/sdk/platform-tools/adb'),'-s','emulator-5554']
def run(*a):return subprocess.check_output(base+list(a),timeout=40)
def save():return json.loads(run('exec-out','run-as','org.nightshiftfm.broadcastqa','cat','files/broadcast_qa.json'))
def tap(x,y):run('shell','input','tap',str(x),str(y))
def capture(n):(e/(n+'.png')).write_bytes(run('exec-out','screencap','-p'))
tap(640,2490);time.sleep(1.15);capture('emulator-polished-live');before=save()
run('shell','am','force-stop','org.nightshiftfm.broadcastqa');run('shell','am','start','-W','-n','org.nightshiftfm.broadcastqa/com.godot.game.GodotAppLauncher');time.sleep(.7)
tap(640,1430);time.sleep(.4);capture('emulator-combat-recovery');after=save()
rows=[{'case':'combat process death','checkpoint_before':before['run']['values'],'checkpoint_after':after['run']['values'],'run_id_same':before['run']['run_id']==after['run']['run_id'],'accepted_same':before['run']['draft']['accepted']==after['run']['draft']['accepted']}]
# Wait for a real draft, then accept a real on-screen card and terminate immediately.
for _ in range(30):
 s=save()
 if s['run']['values']['phase']==4:break
 time.sleep(.5)
capture('emulator-polished-upgrade');tap(500,1030);time.sleep(.15);before=save()
run('shell','am','force-stop','org.nightshiftfm.broadcastqa');run('shell','am','start','-W','-n','org.nightshiftfm.broadcastqa/com.godot.game.GodotAppLauncher');time.sleep(.7);tap(640,1430);time.sleep(.3);after=save();capture('emulator-accepted-choice-recovery')
rows.append({'case':'accepted choice process death','accepted_count':before['run']['draft']['normal_count'],'accepted_same':before['run']['draft']['accepted']==after['run']['draft']['accepted'],'run_id_same':before['run']['run_id']==after['run']['run_id']})
(e/'native-recovery.json').write_text(json.dumps(rows,indent=2));print(json.dumps(rows,indent=2))
