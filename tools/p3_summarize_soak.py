#!/usr/bin/env python3
"""Summarize measured P3 evidence without treating charging as a drain test."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1];out=root/'docs/evidence/P3-onboarding'
runtime=json.loads((out/'pixel-soak-runtime.json').read_text())
host=json.loads((out/'pixel-soak-host.json').read_text())
assert runtime['finished'],'Physical soak has not finished'
rows=runtime['rows'];live=[r for r in rows if r['kind']=='live']
warm=next(r['static_bytes'] for r in rows if r['kind']=='warm_cleanup')
end=next(r['static_bytes'] for r in rows if r['kind']=='end_cleanup')
temps=[];states=[]
for sample in host['samples']:
 if not sample.get('latest'):continue
 temps += [int(x)/10 for x in re.findall(r'^\s*temperature: (\d+)',sample['battery'],re.M)]
 states += [int(x) for x in re.findall(r'Thermal Status: (\d+)',sample['thermal'])]
summary={'device':host['device'],'android':host['android'],'qa_apk_sha256':host['apk_sha256'],'completed':True,'minimum_post_warmup_seconds':1200,'warmup_seconds':30,'render_stress':[r for r in rows if r['kind']=='render_stress'],'live_engine_delta_p95_ms_max':max(r['p95_ms'] for r in live),'sampled_fps_min':min(r['fps'] for r in live),'sampled_fps_max':max(r['fps'] for r in live),'warm_cleanup_static_bytes':warm,'end_cleanup_static_bytes':end,'static_growth_percent':100*(end-warm)/warm,'battery_temperature_c_min':min(temps),'battery_temperature_c_max':max(temps),'android_thermal_status_max':max(states),'save_errors':sum(bool(r['save_failed']) for r in live),'completed_runs':[r for r in rows if r['kind']=='result'],'battery_drain':'NOT RUN: USB powered throughout','memory_scope':'Equivalent fresh-run cleanup states; static allocator includes growing QA sample buffers, not only game allocations'}
summary['normal_frame_target_pass']=summary['live_engine_delta_p95_ms_max']<=20 and summary['render_stress'][0]['p95_ms']<=20
summary['low_effects_stress_target_pass']=summary['render_stress'][1]['p95_ms']<=36
summary['cleanup_memory_target_pass']=summary['static_growth_percent']<=10
(out/'pixel-soak-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps(summary,indent=2))
