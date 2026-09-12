#!/usr/bin/env python3
"""Bounded release-audit simulations; completed-profile fixtures, legal choices."""
from pathlib import Path
import os,subprocess,concurrent.futures,json
root=Path(__file__).resolve().parents[1]
godot=os.environ['GODOT_BIN']
(root/'docs/evidence/release-audit/simulation').mkdir(parents=True,exist_ok=True)
cases=[['campaign',str(m), '20', ['arc_aerial','bass_driver','static_net'][(m-1)%3], '', ['pulse','burst','sweep'][(m-1)%3], '0'] for m in range(1,13)]
cases += [['campaign','12','20',s,'',main,'2'] for s,main in [('arc_aerial','pulse'),('bass_driver','burst'),('static_net','sweep')]]
cases += [['endless','1','20','static_net','','sweep','0'],['contract','1','20','arc_aerial','fragile_broadcast','pulse','0']]
def run(args):
 out=subprocess.run([godot,'--headless','--path',str(root),'--script','res://tests/release_simulation.gd','--',*args],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,timeout=180)
 name='-'.join(args).replace('--','-')
 (root/'docs/evidence/release-audit/simulation'/('log-'+name+'.txt')).write_text(out.stdout)
 passed=out.returncode==0 and not any(x in out.stdout for x in ['ERROR:','SCRIPT ERROR:','FAIL:'])
 return {'args':args,'passed':passed,'returncode':out.returncode}
with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
 rows=list(pool.map(run,cases))
(root/'docs/evidence/release-audit/simulation/matrix.json').write_text(json.dumps(rows,indent=2)+'\n')
print(json.dumps(rows,indent=2))
assert all(r['passed'] for r in rows)
