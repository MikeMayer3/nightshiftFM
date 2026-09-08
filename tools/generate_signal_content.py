#!/usr/bin/env python3
"""The owner's kill-meter flow revision. Old M3/M4 resources remain save-compatible."""
import csv,re
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
with (ROOT/'assets/ui_strings.csv').open(newline='') as f: strings={r['keys']:r['en'] for r in csv.DictReader(f)}
# Reuse authored offensive branches, with new IDs for changed behavior.
rename={'arc_aerial.tap':'arc_aerial.spear','arc_aerial.quick':'arc_aerial.needle','arc_aerial.reserve':'arc_aerial.strike','arc_aerial.tap_cap':'arc_aerial.spear_cap','static_net.screen':'static_net.current','static_net.dense':'static_net.rapid','static_net.wide':'static_net.surge','static_net.firewall':'static_net.live_cap','static_net.slow':'static_net.gain','static_net.duration':'static_net.rate'}
copy={
'arc_aerial.spear':('Lightning Spear','Heavy strike · Pierce 35 armor','Strike one target for twice Arc damage, ignoring 35 armor. Replaces chain coverage with focused damage.',3),
'arc_aerial.needle':('Needle Arc','Pierce +30 armor · −15% damage','Ignore 65 armor in total at 85% strike damage. The capstone uses a narrower 12-unit piercing lane.',1),
'arc_aerial.strike':('Capacitor Strike','70% more damage · 50% slower','Multiply strike damage by 1.7 and attack interval by 1.5.',2),
'arc_aerial.spear_cap':('Thunder Needle','Pierce up to 3 aligned enemies','A strike can hit three distinct enemies in a lane extending 220 units beyond the first target. Lane width is 24, or 12 with Needle Arc. Each target is hit once.',1),
'static_net.current':('Live Current','50% more field damage · Smaller area','Field damage ×1.5, radius ×0.75 and slow strength ×0.5. The field retains two interception charges.',3),
'static_net.rapid':('Rapid Current','Faster damage ticks · Lighter hits','Damage ticks every 0.5s instead of 0.75s, at 75% damage per tick.',1),
'static_net.surge':('Surge Current','Double tick damage · Slower ticks','Damage per tick ×2, with 1.25 seconds between ticks.',2),
'static_net.live_cap':('Live Broadcast','50% more damage · +1s field duration','Field damage ×1.5 and duration +1s. Every tick affects at most eight enemies. Fields never extend themselves.',1),
'static_net.gain':('Static gain','+1 damage per field tick','Add 1 damage to each field tick. Up to eight enemies can be damaged per tick.',1),
'static_net.rate':('Fast refresh','Fields deploy 0.25s sooner','Reduce field activation interval by 0.25s; the active field is replaced when the next one deploys.',-0.25),
}
for family in ['arc_aerial','bass_driver','static_net']:
 track=(ROOT/'content/m4/tracks'/f'{family}.tres').read_text()
 track=track.replace('res://content/m4/upgrades/','res://content/signal/upgrades/').replace('M4_','SIGNAL_')
 for old,new in rename.items():track=track.replace(old+'.tres',new+'.tres')
 if family=='static_net':track=track.replace('&"damage": 0.0','&"damage": 3.0')
 (ROOT/'content/signal/tracks'/f'{family}.tres').write_text(track)
 for oldpath in (ROOT/'content/m4/upgrades').glob(f'{family}.*.tres'):
  old=oldpath.stem;new=rename.get(old,old);body=oldpath.read_text()
  for a,b in sorted(rename.items(),key=lambda x:-len(x[0])):body=body.replace('&"'+a+'"','&"'+b+'"')
  oldkey='M4_'+old.upper().replace('.','_');newkey='SIGNAL_'+new.upper().replace('.','_')
  body=body.replace(oldkey,newkey)
  for suffix in ['NAME','SHORT','DESC']:strings[newkey+'_'+suffix]=strings[oldkey+'_'+suffix]
  if new in copy:
   title,short,desc,amount=copy[new]
   strings.update({newkey+'_NAME':title,newkey+'_SHORT':short,newkey+'_DESC':desc})
   body=re.sub(r'^amount = .*$',f'amount = {float(amount)}',body,flags=re.M)
   if new=='static_net.gain':body=body.replace('stat = &"slow"','stat = &"damage"')
   if new=='static_net.rate':body=body.replace('stat = &"duration"','stat = &"interval"')
  (ROOT/'content/signal/upgrades'/f'{new}.tres').write_text(body)
 strings['SIGNAL_'+family.upper()+'_NAME']=strings['M4_'+family.upper()+'_NAME']
 strings['SIGNAL_'+family.upper()+'_PREVIEW']={'arc_aerial':'Storm Network or Lightning Spear. Choose a modifier at rank 6 and a capstone at rank 8.','bass_driver':strings['M4_BASS_DRIVER_PREVIEW'],'static_net':'Dead Air or Live Current. Every field deals damage; choose control or stronger damage.'}[family]
# Longer encounters come from more active waves of enemies, not an idle minimum timer.
for i in range(1,11):
 source=(ROOT/'content/m4/waves'/f'wave_{i}.tres').read_text()
 ids=re.search(r'enemy_ids = Array\[StringName\]\(\[(.*)\]\)',source).group(1)
 source=source.replace('m4.wave_', 'signal.wave_').replace('M4_WAVE','SIGNAL_WAVE')
 source=re.sub(r'spawn_interval = .*',f'spawn_interval = {2.0 if i<4 else 1.85}',source)
 source=source.replace('['+ids+']','['+ids+', '+ids+']')
 (ROOT/'content/signal/waves'/f'wave_{i}.tres').write_text(source)
strings.update({'SIGNAL_WAVE_NAME':'Standard encounter','SIGNAL_WAVE_DESC':'Defeat enemies to fill the signal meter and choose more firepower.','SIGNAL_METER':'Signal · %d / %d','SIGNAL_READY':'Signal boosted','SIGNAL_HINT':'Choose an upgrade or a new weapon','SIGNAL_NEW':'New · Rank 1','SIGNAL_BASS_DRIVER_NEW_NAME':'Bass Driver','SIGNAL_BASS_DRIVER_NEW_SHORT':'Area damage · Push and strip armor','SIGNAL_BASS_DRIVER_NEW_DESC':'Add a rank-1 Bass Driver. Its pulses deal area damage, expose armor and push enemies back. Uses one support slot.','SIGNAL_STATIC_NET_NEW_NAME':'Static Net','SIGNAL_STATIC_NET_NEW_SHORT':'Damage field · Slow enemies','SIGNAL_STATIC_NET_NEW_DESC':'Add a rank-1 Static Net. Fields deal 3 damage every 0.75s to up to eight enemies, slow movement and intercept two shots. Uses one support slot.','SIGNAL_OVERDRIVE_NAME':'Overdrive','SIGNAL_OVERDRIVE_SHORT':'+25% weapon damage for 20 seconds','SIGNAL_OVERDRIVE_DESC':'Your weapons are fully ranked. Increase their damage by 25% for 20 seconds. Repeated choices refresh the duration without stacking.','SIGNAL_PAUSE':'Combat is paused.\n\nKills fill the signal meter. Each full meter grants an upgrade or a new weapon.\n\nContinue restores the latest upgrade decision or wave checkpoint, including enemies and meter progress.','SIGNAL_HELP':'Reroll spends one token to redraw offers. Banish removes a tuning card for this run. New weapons and branch choices cannot be banished.','SIGNAL_FULL':'Signal full','BOOT_EYEBROW':'OFFLINE • KILL-METER PLAYTEST'})
with (ROOT/'assets/ui_strings.csv').open('w',newline='') as f:
 w=csv.writer(f,lineterminator='\n');w.writerow(['keys','en']);w.writerows(strings.items())
