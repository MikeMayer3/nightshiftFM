#!/usr/bin/env python3
"""M4 active-play revision: longer waves of clustered threats; preserve prior content."""
from pathlib import Path
import csv,re
root=Path(__file__).resolve().parents[1]
folder=root/'content/active/waves';folder.mkdir(parents=True,exist_ok=True)
for number in range(1,11):
 text=(root/'content/signal/waves'/f'wave_{number}.tres').read_text()
 ids=re.search(r'enemy_ids = Array\[StringName\]\(\[(.*)\]\)',text).group(1)
 text=text.replace('signal.wave_', 'active.wave_').replace('['+ids+']','['+ids+', '+ids+']')
 text=re.sub(r'spawn_interval = .*','spawn_interval = 6.0',text)
 if number==10:
  seen=[0]
  def finale(match):
   seen[0]+=1
   return match.group(0) if seen[0]%2 else '&"m4.plated"'
  text=re.sub(r'&"m4.elite"',finale,text)
 (folder/f'wave_{number}.tres').write_text(text)
 # Versioned first elite encounter: two Overseers before the four-elite finale.
 if number==8:
  seen=[0]
  def first_elites(match):
   seen[0]+=1
   return match.group(0) if seen[0]%2 else '&"m4.plated"'
  tuned=re.sub(r'&"m4.elite"',first_elites,text).replace('active.wave_8"','active.wave_8_turrets"')
  (folder/'wave_8_turrets.tres').write_text(tuned)
with (root/'assets/ui_strings.csv').open(newline='') as f: strings={r['keys']:r['en'] for r in csv.DictReader(f)}
strings.update({'ACTIVE_WAVE':'Wave %d / %d','ACTIVE_BURST':'Burst · Aim and release','ACTIVE_WAIT':'Burst · %ds','ACTIVE_PAUSE':'Aim and release on a group to fire a burst. It also interrupts shooters and clears nearby shots.\n\nDrag to direct automatic fire. The Burst button fires at your current target.\n\nKills fill Signal. Upgrades pause the fight. Continue restores the latest wave or upgrade checkpoint.','ACTIVE_REPORT':'Aimed bursts: %d · Damage: %.0f','ACTIVE_REPORT_HINT':'Burst damage is included in Pulse damage above.','BOOT_EYEBROW':'OFFLINE • ACTIVE COMBAT PLAYTEST'})
with (root/'assets/ui_strings.csv').open('w',newline='') as f:
 writer=csv.writer(f,lineterminator='\n');writer.writerow(['keys','en']);writer.writerows(strings.items())
