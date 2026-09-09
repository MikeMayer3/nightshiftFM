#!/usr/bin/env python3
"""Generate the eight M6 immutable recipes and their localized contracts."""
import csv
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RECIPES = [
 ('ball_lightning','Ball Lightning',['arc_aerial','reverb_well'],'',1.5,6,3,18,120,0,0,'Three direct Arc hits on Charged enemies inside a Well discharge 18 damage to up to 6 enemies. 1.5s cooldown.'),
 ('dead_zone','Dead Zone',['static_net','bass_driver'],'slowed',.5,6,1,0,120,.45,0,'Bass hits on Net-slowed enemies jam up to 6 targets for 0.45s. 0.5s pulse cooldown; elites resist interruption.'),
 ('b_side','B-Side',['needle_swarm','echo_deck'],'marked',.08,8,1,0,120,0,0,'Echo replays prefer marked enemies within replay reach. Works with precision shots, volleys and beams.'),
 ('live_wire','Live Wire',['arc_aerial','static_net'],'',1,6,1,0,120,0,0,'Net ticks charge up to 6 enemies once per second. Maximum 3 Charged stacks; creates no Arc attack.'),
 ('pressure_drop','Pressure Drop',['bass_driver','reverb_well'],'',.8,6,1,0,120,0,.08,'Each Bass activation gains 8% extra damage per enemy in its overlap with a Well, up to 6. Each enemy counts once. 0.8s cooldown.'),
 ('double_drop','Double Drop',['echo_deck','bass_driver'],'',.8,6,3,0,120,0,.4,'Every third direct Bass activation adds a 40% damage repeat to up to 6 targets. 0.8s cooldown; repeats cannot repeat.'),
 ('needle_thread','Needle Thread',['main','needle_swarm'],'marked',.08,8,1,20,120,0,.1,'A main shot aimed at a mark pierces one extra target; a volley gains 20 armor penetration; a beam gains 10% damage. Echoes do not inherit this bonus.'),
 ('feedback_loop','Feedback Loop',['shield','arc_aerial'],'',12,8,1,28,320,0,0,'A shield break emits 28 damage in a 320-radius pulse, up to 8 targets. 12s cooldown. The pulse never restores shield or triggers retaliation.'),
]

def main():
    folder = ROOT/'content/synergies'
    folder.mkdir(exist_ok=True)
    preloads=[]
    strings={}
    for id,name,endpoints,capability,cooldown,cap,threshold,damage,radius,duration,coefficient,desc in RECIPES:
        key='M6_'+id.upper()
        text='[gd_resource type="Resource" script_class="SynergyDefinition" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/core/definitions/synergy_definition.gd" id="1"]\n[resource]\nscript = ExtResource("1")\n'
        text+=f'id = &"{id}"\nname_key = &"{key}_NAME"\ndescription_key = &"{key}_DESC"\n'
        text+='endpoint_ids = Array[StringName](['+', '.join('&"'+x+'"' for x in endpoints)+'])\n'
        text+=f'capability = &"{capability}"\ncooldown = {cooldown}\ntarget_cap = {cap}\nthreshold = {threshold}\ndamage = {damage}\nradius = {radius}\nduration = {duration}\ncoefficient = {coefficient}\n'
        (folder/(id+'.tres')).write_text(text)
        preloads.append(f'\t&"{id}": preload("res://content/synergies/{id}.tres"),')
        strings[key+'_NAME']=name
        strings[key+'_DESC']=desc
    (ROOT/'scripts/patchboard/patchboard_content.gd').write_text('class_name PatchboardContent\nextends RefCounted\nconst VERSION: String = "m6.1"\nconst RECIPES: Dictionary = {\n'+'\n'.join(preloads)+'\n}\n')
    with (ROOT/'assets/ui_strings.csv').open(newline='') as f: rows=list(csv.DictReader(f))
    rows=[r for r in rows if r['keys'] not in strings]
    rows.extend({'keys':k,'en':v} for k,v in strings.items())
    with (ROOT/'assets/ui_strings.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=['keys','en'],lineterminator='\n'); w.writeheader(); w.writerows(rows)
if __name__=='__main__': main()
