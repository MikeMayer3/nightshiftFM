#!/usr/bin/env python3
"""Reproduce the deliberately bounded M3 catalog and its English card text."""
import csv
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
TRACKS = {
 'main': ('Pulse Transmitter', False, {'damage':8.0,'interval':0.48,'targets':1.0,'range':200.0}, [
 ('gain','Signal gain','damage',2,0,'',0,''),
 ('rate','Quick pulse','interval',-0.04,0,'',0,''),
 ('reach','Clean signal','damage',1,0,'interval',-0.02,''),
 ('ricochet','Ricochet','targets',1,3,'damage',-2,''),
 ('long_route','Long rebound','range',160,6,'interval',0.08,'ricochet'),
 ('capstone','Broadcast burst','targets',2,8,'',0,'long_route')]),
 'shield': ('Capacitor',False,{'capacity':50.0,'recharge':3.0,'duration':2.5,'cooldown':12.0,'brace_recharge':0.0},[
 ('reserve','Larger reserve','capacity',12,0,'',0,''),
 ('recovery','Recovery coil','recharge',0.6,0,'',0,''),
 ('hold','Long brace','duration',0.5,0,'',0,''),
 ('bastion','Bastion','duration',2,3,'cooldown',2,''),
 ('live_coil','Live coil','brace_recharge',6,6,'recharge',-0.5,'bastion'),
 ('capstone','Night reserve','capacity',30,8,'cooldown',-4,'live_coil')]),
 'arc_aerial': ('Valve Microphone',True,{'damage':5.0,'interval':1.25,'targets':2.0,'range':170.0,'branching':0.0},[
 ('gain','Coil gain','damage',0.75,0,'',0,''),
 ('rate','Fast oscillator','interval',-0.1,0,'',0,''),
 ('reach','Antenna reach','range',34,0,'',0,''),
 ('storm','Storm Network','targets',2,3,'damage',-1,''),
 ('long_route','Long Route','range',120,6,'interval',0.2,'storm'),
 ('capstone','Broadcast Storm','targets',2,8,'branching',1,'long_route')])}
labels={'branching':'branching mode (each hit may branch from an earlier contact; total target cap still applies)','damage':'damage per hit','interval':'seconds between attacks','targets':'maximum distinct targets','range':'jump range','capacity':'shield capacity (no instant refill)','recharge':'shield per second after hit delay','duration':'brace seconds','cooldown':'brace cooldown seconds','brace_recharge':'shield per second while braced, even during hit delay'}
short_effects = {
 'main.gain': '+2 damage', 'main.rate': 'Fire faster · −0.04s between shots',
 'main.reach': '+1 damage · Fire faster (−0.02s)',
 'main.ricochet': 'Hit +1 target · −2 damage per hit',
 'main.long_route': '+160 jump range · Fire slower (+0.08s)',
 'main.capstone': 'Hit +2 targets per burst',
 'shield.reserve': '+12 shield capacity', 'shield.recovery': '+0.6 shield recovery / sec',
 'shield.hold': 'Brace lasts +0.5 seconds',
 'shield.bastion': '+2s brace · +2s cooldown',
 'shield.live_coil': 'Heal 6 / sec while braced\n−0.5 / sec normal recovery',
 'shield.capstone': '+30 shield capacity · −4s cooldown',
 'arc_aerial.gain': '+0.75 damage per hit',
 'arc_aerial.rate': 'Fire faster · −0.1s between attacks',
 'arc_aerial.reach': '+34 chain range',
 'arc_aerial.storm': 'Chain to +2 targets · −1 damage per hit',
 'arc_aerial.long_route': '+120 chain range · Fire slower (+0.2s)',
 'arc_aerial.capstone': 'Branching chains · Hit +2 targets',
}
strings={}
for track,(name,support,baseline,cards) in TRACKS.items():
    key='M3_'+track.upper()
    strings[key+'_NAME']=name
    strings[key+'_PREVIEW']='Rank 3: '+cards[3][1]+' → Rank 6: '+cards[4][1]+' → Rank 8: '+cards[5][1]+'.'
    ext=['[gd_resource type="Resource" script_class="TrackDefinition" load_steps=8 format=3]', '[ext_resource type="Script" path="res://scripts/progression/track_definition.gd" id="1"]']
    for n,(cid,title,stat,amount,rank,second,second_amount,prereq) in enumerate(cards,2):
        full=track+'.'+cid
        ckey='M3_'+full.upper().replace('.','_')
        strings[ckey+'_NAME']=title
        strings[ckey+'_SHORT']=short_effects[full]
        strings[ckey+'_DESC']=f'{amount:+g} {labels[stat]}'+(f'; {second_amount:+g} {labels[second]}' if second else '')+'.'
        card=f'''[gd_resource type="Resource" script_class="UpgradeDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/upgrade_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"{full}"
name_key = &"{ckey}_NAME"
description_key = &"{ckey}_DESC"
target_id = &"{track}"
required_rank = {rank}
stack_cap = {1 if rank else 4}
prerequisite = &"{track+'.'+prereq if prereq else ''}"
stat = &"{stat}"
amount = {float(amount)}
second_stat = &"{second}"
second_amount = {float(second_amount)}
'''
        (ROOT/'content/upgrades'/f'{full}.tres').write_text(card)
        ext.append(f'[ext_resource type="Resource" path="res://content/upgrades/{full}.tres" id="{n}"]')
    stats='{'+', '.join(f'&"{k}": {v}' for k,v in baseline.items())+'}'
    ext += ['[resource]','script = ExtResource("1")',f'id = &"{track}"',f'name_key = &"{key}_NAME"',f'preview_key = &"{key}_PREVIEW"',f'support = {str(support).lower()}',f'baseline = {stats}','options = Array[ExtResource("2")]([])']
    # Typed resource arrays use the script resource type, not a particular card instance.
    ext[-1]='options = ['+', '.join(f'ExtResource("{n}")' for n in range(2,8))+']'
    (ROOT/'content/tracks'/f'{track}.tres').write_text('\n'.join(ext)+'\n')
with (ROOT/'assets/ui_strings.csv').open(newline='') as f: rows=dict((r['keys'],r['en']) for r in csv.DictReader(f))
rows.update(strings)
with (ROOT/'assets/ui_strings.csv').open('w',newline='') as f:
    w=csv.writer(f, lineterminator="\n"); w.writerow(['keys','en']); w.writerows(rows.items())
