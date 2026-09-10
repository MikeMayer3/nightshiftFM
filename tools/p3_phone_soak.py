#!/usr/bin/env python3
"""Read-only sampling around an isolated P3 QA app; never touches owner saves."""
from pathlib import Path
import subprocess,json,time,hashlib
root=Path(__file__).resolve().parents[1];out=root/'docs/evidence/P3-onboarding'
base=[str(Path.home()/'Library/Android/sdk/platform-tools/adb'),'-s','57261FDCQ00593'];pkg='org.nightshiftfm.p3qa'
def run(*a):return subprocess.check_output(base+list(a),stderr=subprocess.STDOUT,timeout=45)
assert run('shell','getprop','ro.product.model').decode().strip()=='Pixel 10 Pro XL'
metadata={'device':'Pixel 10 Pro XL','android':run('shell','getprop','ro.build.version.release').decode().strip(),'package':pkg,'apk_sha256':hashlib.sha256((root/'builds/android/nightshift-p3-qa.apk').read_bytes()).hexdigest(),'samples':[]}
run('shell','am','start','-W','-n',pkg+'/com.godot.game.GodotAppLauncher')
start=time.monotonic()
for index in range(25):
 row={'wall_seconds':round(time.monotonic()-start,2),'battery':run('shell','dumpsys','battery').decode(),'thermal':run('shell','dumpsys','thermalservice').decode(),'memory':run('shell','dumpsys','meminfo',pkg).decode()}
 try:
  data=run('exec-out','run-as',pkg,'cat','files/p3_probe.json');state=json.loads(data)
  (out/'pixel-soak-runtime.json').write_bytes(data)
  row['latest']=state['rows'][-1] if state['rows'] else None
  row['finished']=state['finished']
 except (subprocess.CalledProcessError,json.JSONDecodeError):row['finished']=False
 metadata['samples'].append(row)
 (out/'pixel-soak-host.json').write_text(json.dumps(metadata,indent=2)+'\n')
 print(json.dumps({'sample':index,'seconds':row['wall_seconds'],'latest':row.get('latest'),'finished':row['finished']}),flush=True)
 if index in [1,10,20] or row['finished']:(out/('pixel-soak-%02d.png'%index)).write_bytes(run('exec-out','screencap','-p'))
 if row['finished']:break
 time.sleep(60)
pid=run('shell','pidof',pkg).decode().strip()
(out/'pixel-soak-logcat.log').write_bytes(run('logcat','-d','--pid='+pid))
assert metadata['samples'][-1]['finished'],'Soak did not complete'
