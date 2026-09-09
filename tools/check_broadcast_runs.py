#!/usr/bin/env python3
"""Legal simulated runs; distinct from native input and human acceptance."""
from pathlib import Path
import subprocess,os,json,concurrent.futures
r=Path(__file__).resolve().parents[1];e=r/'docs/evidence/M8-M10';engine=os.environ['GODOT_BIN']
cases=[['campaign',str(m), '20',style,'',main,'0'] for m in range(1,13) for style,main in [('arc_aerial','pulse'),('bass_driver','burst'),('static_net','sweep')]]
cases += [['contract','1','20','arc_aerial',c,'pulse','0'] for c in ['two_channel','bare_antenna','fragile_broadcast','no_repeats','overcrowded_frequency','long_distance']]
cases += [['campaign',str(m),'20','static_net','','sweep',str(d)] for m in [4,8,12] for d in [1,2]]
def run(args):
 result=subprocess.run([engine,'--headless','--path',str(r),'--script','res://tests/broadcast_playthrough.gd','--',*args],capture_output=True,text=True,timeout=120)
 rows=[json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
 return {'args':args,'exit':result.returncode,'result':rows[-1] if rows else None,'errors':result.stderr}
with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
 rows=list(pool.map(run,cases))
(e/'run-matrix.json').write_text(json.dumps(rows,indent=2))
print(json.dumps({'runs':len(rows),'valid_completed':sum(x['exit']==0 for x in rows),'victories':sum(bool(x['result'] and x['result']['victory']) for x in rows),'failures':[x for x in rows if x['exit']]}))
raise SystemExit(any(x['exit'] for x in rows))
