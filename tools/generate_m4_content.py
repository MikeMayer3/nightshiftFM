#!/usr/bin/env python3
"""Generate only M4's three-family, two-branch slice; retain the M3 catalog for old saves."""
import csv
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
strings={}
tracks={
'arc_aerial':('Valve Microphone',{'damage':6.0,'interval':1.3,'range':180.0,'targets':2.0,'mode':0.0,'modifier':0.0,'capstone':0.0},[
('gain','Coil gain',0,'','damage',1.0,'','+1 damage per hit'),
('rate','Fast oscillator',0,'','interval',-0.1,'','Fire faster · −0.1s between arcs'),
('reach','Antenna reach',0,'','range',36.0,'','+36 chain range'),
('storm','Storm Network',3,'','mode',1,'tap','Chain to +2 targets · 20% less damage'),
('tap','Shield Tap',3,'','mode',2,'storm','Restore shield on hits · Fewer targets'),
('long_route','Long Route',6,'storm','modifier',1,'tight','+120 chain range · 20% slower attacks'),
('tight','Tight Circuit',6,'storm','modifier',2,'long_route','35% more arc damage · 40% less range'),
('quick','Quick Charge',6,'tap','modifier',1,'reserve','30% faster arcs · Smaller shield gains'),
('reserve','Reserve Charge',6,'tap','modifier',2,'quick','Store shield energy · Release on brace'),
('storm_cap','Broadcast Storm',8,'storm','capstone',1,'','Branching arcs · Hit +2 targets'),
('tap_cap','Closed Circuit',8,'tap','capstone',1,'','Full reservoir grants a brief overshield')]),
'bass_driver':('Studio Monitor',{'damage':10.0,'interval':2.4,'radius':100.0,'push':25.0,'exposure':15.0,'mode':0.0,'modifier':0.0,'capstone':0.0},[
('gain','Heavy cone',0,'','damage',1.5,'','+1.5 pulse damage'),
('radius','Big cabinet',0,'','radius',15.0,'','+15 pulse radius'),
('rate','Quick beat',0,'','interval',-0.15,'','Fire faster · −0.15s between pulses'),
('wide','Wideband',3,'','mode',1,'compression','40% wider pulses · 20% less damage'),
('compression','Compression',3,'','mode',2,'wide','Heavy armor-breaking hits · Narrow pulses'),
('wide_cone','Wide Cone',6,'wide','modifier',1,'deep','50% wider · 35% shorter reach'),
('deep','Deep Cone',6,'wide','modifier',2,'wide_cone','60% longer reach · 30% narrower'),
('hard','Hard Clip',6,'compression','modifier',1,'direct','Strip more armor · 25% slower pulses'),
('direct','Direct Injection',6,'compression','modifier',2,'hard','50% more elite damage · Half knockback'),
('wall','Wall of Sound',8,'wide','capstone',1,'','Send a broad shockwave up the arena'),
('crush','Crushing Note',8,'compression','capstone',1,'','Heavier pulses · Strip +20 armor')]),
'static_net':('Mixing Desk',{'damage':0.0,'interval':4.2,'radius':125.0,'duration':2.5,'slow':0.3,'charges':2.0,'mode':0.0,'modifier':0.0,'capstone':0.0},[
('slow','Thick static',0,'','slow',0.05,'','+5% slow strength · 60% maximum'),
('radius','Wide screen',0,'','radius',18.0,'','+18 field radius'),
('duration','Long broadcast',0,'','duration',0.5,'','Fields last +0.5 seconds'),
('dead','Dead Air',3,'','mode',1,'screen','Stronger slow · Interrupt enemy abilities'),
('screen','Interference Screen',3,'','mode',2,'dead','Intercept +3 shots · Weaker slow'),
('blank','Blank Channel',6,'dead','modifier',1,'hum','Longer interruption · 25% slower fields'),
('hum','Low Hum',6,'dead','modifier',2,'blank','Longer fields · Shorter interruption'),
('dense','Dense Mesh',6,'screen','modifier',1,'wide','Intercept +3 shots · 25% smaller fields'),
('wide','Wide Mesh',6,'screen','modifier',2,'dense','40% wider fields · Intercept −1 shot'),
('zone','Dead Zone',8,'dead','capstone',1,'','Long disruption · Elites resist repeat jams'),
('firewall','Signal Firewall',8,'screen','capstone',1,'','Block up to 12 shots per field')])}
details={
'arc_aerial.storm':'Hit up to four distinct targets at 80% damage. Each arc adds one Charged stack for 3s (maximum 3); each stack adds 5% arc damage.',
'arc_aerial.tap':'One target at 60% damage. Eligible direct hits restore up to 2 shield, at most once per 0.8s. No overheal. Each hit also fills a separate 12-point reservoir for Closed Circuit.',
'arc_aerial.quick':'Attack interval ×0.7. Each eligible restoration is reduced from 2 to 1.5 shield; shared 0.8s restoration cooldown remains.',
'arc_aerial.reserve':'Direct hits store 2 energy (maximum 12) instead of restoring shield immediately. Brace releases stored energy as effective shield restoration.',
'arc_aerial.tap_cap':'When brace consumes a full 12-point reservoir, grant 10 overshield for 4s. It absorbs before ordinary shield and cannot refill itself. Quick Charge also fills the reservoir on direct hits.',
'bass_driver.compression':'Pulse radius ×0.65, damage ×1.5 and exposure +25 armor reduction for 3s. Armor cannot fall below zero. Up to eight enemies per pulse.',
'bass_driver.hard':'Add 25 armor reduction to exposure. Pulse interval ×1.25; armor floor remains zero.',
'bass_driver.crush':'Pulse damage ×1.5 and exposure +20. Up to eight targets; armor floor zero. No percentage-health execution.',
'bass_driver.wall':'Replace the local pulse with a shockwave traveling up to 600 units upward at 400 units/s (234 with Wide Cone, 576 with Deep Cone). Hit each enemy once, up to 12 enemies per wave; damage and exposure retain branch modifiers.',
'static_net.dead':'Slow strength +15 percentage points (60% normal cap, 25% elite cap). Interrupt abilities for 0.35s; reapplication cooldown is 2s, or 4s for elites. Resistant targets retain a 20% ability-speed reduction.',
'static_net.blank':'Interruption lasts 0.7s; activation interval ×1.25. Elite interruption is capped at 0.2s with 4s cooldown.',
'static_net.hum':'Field duration +1.5s; interruption reduced to 0.15s. Slow ends 0.6s after leaving a field.',
'static_net.zone':'Field duration +1s and interruption +0.25s. Elite jam caps and cooldown still apply; immune targets retain the ability-speed reduction.',
'static_net.firewall':'Each field has a total budget of 12 intercepted projectiles and lasts +1s. Budget never refills during the field. One active field at a time.',
}
for track,(name,stats,cards) in tracks.items():
 key='M4_'+track.upper();strings[key+'_NAME']=name
 branches=[c[1] for c in cards if c[2]==3]
 strings[key+'_PREVIEW']=' / '.join(branches)+'. Rank 3: choose a path. Rank 6: choose its modifier. Rank 8: matching capstone.'
 refs=['[gd_resource type="Resource" script_class="TrackDefinition" load_steps=%d format=3]'%(len(cards)+2),'[ext_resource type="Script" path="res://scripts/progression/track_definition.gd" id="1"]']
 for n,(cid,title,rank,prereq,stat,value,exclude,short) in enumerate(cards,2):
  full=track+'.'+cid; ck='M4_'+full.upper().replace('.','_');strings[ck+'_NAME']=title;strings[ck+'_SHORT']=short;strings[ck+'_DESC']=details.get(full,short+'.')
  text=f'''[gd_resource type="Resource" script_class="UpgradeDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/upgrade_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"{full}"
name_key = &"{ck}_NAME"
description_key = &"{ck}_DESC"
target_id = &"{track}"
required_rank = {rank}
stack_cap = {1 if rank else 4}
prerequisite = &"{track+'.'+prereq if prereq else ''}"
excludes = Array[StringName]([{('&'+chr(34)+track+'.'+exclude+chr(34)) if exclude else ''}])
stat = &"{stat}"
amount = {float(value)}
'''
  (ROOT/'content/m4/upgrades'/f'{full}.tres').write_text(text)
  refs.append(f'[ext_resource type="Resource" path="res://content/m4/upgrades/{full}.tres" id="{n}"]')
 refs+=['[resource]','script = ExtResource("1")',f'id = &"{track}"',f'name_key = &"{key}_NAME"',f'preview_key = &"{key}_PREVIEW"','support = true','baseline = {'+', '.join(f'&"{k}": {v}' for k,v in stats.items())+'}','options = ['+', '.join(f'ExtResource("{n}")' for n in range(2,len(cards)+2))+']']
 (ROOT/'content/m4/tracks'/f'{track}.tres').write_text('\n'.join(refs)+'\n')
# Ten deliberately authored patterns teach armor/ranged threats before the finale.
patterns=[['s']*10,['s','d']*5,['s','p','s','d']*3,['c','s','d','s','p','s']*2,['p','d','s','s','c','s']*2,['c','s','d','p','s','d']*2,['p','s','c','d','s','s']*3,['e','s','p','d','s','c','s','s','d','p'],['d','s','p','c','s','s']*3,['e','p','s','d','c','s','e','p','s','c','d','s']]
ids={'s':'m2.swarmer','d':'m2.diver','c':'m2.carrier','p':'m4.plated','e':'m4.elite'}
for i,pattern in enumerate(patterns,1):
 (ROOT/'content/m4/waves'/f'wave_{i}.tres').write_text(f'''[gd_resource type="Resource" script_class="WaveDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/wave_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"m4.wave_{i}"
name_key = &"M4_WAVE_NAME"
description_key = &"M4_WAVE_DESC"
spawn_interval = {1.8 if i<4 else 1.55}
enemy_ids = Array[StringName]([{', '.join('&"'+ids[x]+'"' for x in pattern)}])
''')
for name,health,speed,armor,elite in [('plated',70,28,55,False),('elite',220,18,80,True)]:
 (ROOT/'content/m4/enemies'/f'{name}.tres').write_text(f'''[gd_resource type="Resource" script_class="EnemyDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/enemy_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"m4.{name}"
name_key = &"M4_{name.upper()}_NAME"
description_key = &"M4_{name.upper()}_DESC"
path_kind = 2
health = {float(health)}
speed = {float(speed)}
radius = {36.0 if elite else 27.0}
breach_damage = {48.0 if elite else 22.0}
projectile_limit = 4
ability_interval = {3.0 if elite else 4.0}
armor = {float(armor)}
elite = {str(elite).lower()}
''')
strings.update({'M4_WAVE_NAME':'Standard wave','M4_WAVE_DESC':'Protect the station through ten waves.','M4_PLATED_NAME':'Plated carrier','M4_PLATED_DESC':'Armored carrier with four telegraphed shots.','M4_ELITE_NAME':'Overseer','M4_ELITE_DESC':'Armored elite. Resists slow and knockback; repeat interruptions have a cooldown.'})
with (ROOT/'assets/ui_strings.csv').open(newline='') as f: rows={r['keys']:r['en'] for r in csv.DictReader(f)}
rows.update(strings)
with (ROOT/'assets/ui_strings.csv').open('w',newline='') as f:
 w=csv.writer(f,lineterminator='\n');w.writerow(['keys','en']);w.writerows(rows.items())
