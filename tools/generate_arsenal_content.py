#!/usr/bin/env python3
"""M5's immutable 12 tracks / 216 options; no legacy resources are rewritten."""
import csv, json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
# Branch tuples: name, effects, [(modifier name, effects), ...], cap name, cap effects.
def branch(name, effects, a, b, cap, cap_effects):
    return name, effects, [a, b], cap, cap_effects
B = branch
TRACKS = {
'arc_aerial': ('Arc Aerial', 'Chains and armor piercing', dict(damage=6, interval=1.3, targets=2, reach=180, duration=3, elite_bonus=0), [
 B('Storm',dict(targets=2,damage_bonus=-.2),('Long Route',dict(reach=120,cadence=-.15)),('Tight Circuit',dict(reach=-70,damage_bonus=.35)),'Broadcast Storm',dict(targets=2)),
 B('Lightning Spear',dict(targets=-1,damage_bonus=1,penetration=35),('Needle Arc',dict(penetration=30,width=-10)),('Capacitor Strike',dict(damage_bonus=1,cadence=-.3)),'Thunder Needle',dict(pierce=2)),
 B('Shield Tap',dict(targets=-1,damage_bonus=-.4,healing=3),('Quick Charge',dict(cadence=.4,healing=-1)),('Reserve Charge',dict(reserve=1,healing=2)),'Closed Circuit',dict(overheal=1))]),
'echo_deck': ('Echo Deck', 'Replays main attacks', dict(damage=0,interval=1,echo_damage=.8,attacks=3,delay=.6,copies=1,reach=170,crit=0), [
 B('Rapid Repeat',dict(attacks=-1,echo_damage=-.1),('Double Tap',dict(copies=1,echo_damage=-.1)),('Staccato',dict(attacks=-1,reach=-60)),'Loop Pedal',dict(copies=1)),
 B('Layered Recording',dict(attacks=1,copies=1,delay=.5),('Long Side',dict(copies=1,attacks=1)),('Hot Master',dict(echo_damage=.3,delay=.3)),'Master Tape',dict(copies=1,priority=1)),
 B('Ghost Chorus',dict(distinct=1,reach=100),('Wide Chorus',dict(reach=150,echo_damage=-.1)),('Lead Singer',dict(priority=1,echo_damage=.15,reach=-50)),'Phantom Broadcast',dict(copies=2))]),
'bass_driver': ('Bass Driver', 'Area damage and armor exposure', dict(damage=10,interval=2.4,radius=100,push=20,exposure=20,duration=3), [
 B('Wideband',dict(radius=40,damage_bonus=-.2),('Wide Cone',dict(radius=35,push=-10)),('Deep Cone',dict(radius=-20,push=35)),'Wall of Sound',dict(pulses=2)),
 B('Compression',dict(radius=-30,damage_bonus=.8,exposure=15),('Hard Clip',dict(exposure=25,cadence=-.2)),('Direct Injection',dict(elite_bonus=.5,push=-15)),'Crushing Note',dict(damage_bonus=.6)),
 B('Aftershock',dict(pulses=2,damage_bonus=-.3),('Ringing Floor',dict(duration=2,damage_bonus=-.15)),('Double Thump',dict(pulses=1,duration=-1)),'Seismic Chorus',dict(pulses=2))]),
'needle_swarm': ('Needle Swarm', 'Traveling projectiles and marks', dict(damage=6,interval=2.4,pierce=1,steering=3,projectiles=4,duration=3,reach=700,speed=500), [
 B('Piercing Needles',dict(pierce=2,steering=-3),('Long Groove',dict(pierce=2,falloff=.15)),('Hard Cut',dict(damage_bonus=.6,pierce=-1)),'Record Cutter',dict(pierce=3)),
 B('Homing Swarm',dict(steering=4,pierce=-1),('Wide Seek',dict(reach=200,speed=-120)),('Close Pursuit',dict(steering=4,speed=100,duration=-.5)),'Needle Hurricane',dict(projectiles=3)),
 B('Marking Pins',dict(mark=.2,damage_bonus=-.2),('Spotlight',dict(mark=.15,projectiles=-1)),('Full Set',dict(projectiles=2,mark=-.05)),'Perfect Groove',dict(mark=.15,priority=1))]),
'reverb_well': ('Reverb Well', 'Pull fields and release bursts', dict(damage=3,interval=5,duration=3,radius=100,pull=32,targets=6), [
 B('Trap Room',dict(radius=35,duration=1,pull=-10),('Long Hall',dict(duration=2,pull=-8)),('Narrow Door',dict(pull=25,radius=-40)),'Dead Room',dict(slow=.2)),
 B('Pressure Well',dict(radius=-20,pull=35),('Hard Walls',dict(pull=30,duration=-1)),('Heavy Air',dict(exposure=25,damage_bonus=-.3)),'Implosion',dict(terminal=8)),
 B('Orbit Chamber',dict(orbit=1,pull=-10),('Slow Orbit',dict(duration=2,targets=-2)),('Fast Orbit',dict(duration=-1,terminal=5)),'Slingshot',dict(release=60))]),
'static_net': ('Static Net', 'Slows, intercepts and live damage', dict(damage=3,interval=5,duration=3,radius=110,slow=.3,charges=2,residual=.6), [
 B('Dead Air',dict(jam=.4,slow=.1),('Blank Channel',dict(jam=.5,cadence=-.2)),('Low Hum',dict(duration=2,jam=-.2)),'Dead Zone',dict(radius=30,duration=1)),
 B('Interference',dict(charges=2,slow=-.15),('Dense Weave',dict(charges=3,radius=-35)),('Wide Mesh',dict(radius=65,charges=-1)),'Firewall',dict(charges=4)),
 B('Live Current',dict(damage_bonus=1,slow=-.15),('Rapid Static',dict(tick_rate=.5,damage_bonus=-.25)),('High Voltage',dict(damage_bonus=1,tick_rate=-.3)),'Live Wire',dict(damage_bonus=1,duration=1))]),
'pulse': ('Pulse Spindle', 'Balanced precision shots', dict(damage=12,interval=.6,reach=600,width=22,penetration=0,projectiles=1), [
 B('Penetrator',dict(penetration=30,pierce=1),('Long Needle',dict(pierce=1,damage_bonus=-.15)),('Hard Point',dict(penetration=35,damage_bonus=.15)),'Throughline',dict(pierce=2)),
 B('Ricochet',dict(bounce=1,reach=-50),('Wide Bounce',dict(bounce=1,damage_bonus=-.2)),('Heavy Bounce',dict(damage_bonus=.35,cadence=-.15)),'Pinball Signal',dict(bounce=2)),
 B('Charge Shot',dict(damage_bonus=1.4,cadence=-.45,width=10),('Fast Charge',dict(cadence=.2,damage_bonus=-.3)),('Full Charge',dict(damage_bonus=1,penetration=25)),'Final Charge',dict(pierce=2,width=15))]),
'sweep': ('Sweep Laser', 'Sweeps through aligned enemies', dict(damage=4,interval=.22,reach=600,width=18,penetration=10,projectiles=1), [
 B('Focused Beam',dict(damage_bonus=.4,width=-6),('Fine Focus',dict(penetration=35,width=-4)),('Hot Focus',dict(damage_bonus=.5,cadence=-.2)),'Burn Through',dict(penetration=50)),
 B('Fan Sweep',dict(width=38,damage_bonus=-.3),('Broad Fan',dict(width=35,damage_bonus=-.15)),('Tight Fan',dict(width=-15,damage_bonus=.4)),'Full Spectrum',dict(width=45)),
 B('Pulse Beam',dict(damage_bonus=1,cadence=-.4),('Fast Pulse',dict(cadence=.2,damage_bonus=-.2)),('Heavy Pulse',dict(damage_bonus=.8,penetration=20)),'Resonant Beam',dict(damage_bonus=.5,width=20))]),
'burst': ('Burst Rack', 'Close-range volleys', dict(damage=6,interval=.95,reach=500,width=90,penetration=0,projectiles=4), [
 B('Wide Scatter',dict(width=60,projectiles=2,damage_bonus=-.2),('Full Spread',dict(width=50,projectiles=1)),('Heavy Pellets',dict(damage_bonus=.4,projectiles=-1)),'Scatterstorm',dict(projectiles=3)),
 B('Converging Volley',dict(width=-55,damage_bonus=.3),('Tight Group',dict(width=-15,penetration=25)),('Heavy Group',dict(damage_bonus=.4,cadence=-.2)),'Focal Volley',dict(projectiles=2)),
 B('Stagger Burst',dict(stagger=1,cadence=.2),('Quick Stagger',dict(cadence=.25,damage_bonus=-.15)),('Long Stagger',dict(projectiles=2,cadence=-.15)),'Rolling Thunder',dict(projectiles=2))]),
'capacitor': ('Capacitor', 'Large reserve / temporary overshield', dict(damage=0,capacity=65,recharge=7,delay=4,cooldown=14,mitigation=.05,break_recovery=0,duration=3), [
 B('Deep Reserve',dict(capacity=25,recharge=-1),('Deep Cell',dict(capacity=25,delay=1)),('Quick Cell',dict(recharge=3,capacity=-10)),'Vault',dict(capacity=30)),
 B('Damage Smoothing',dict(mitigation=.15,capacity=-10),('Soft Clip',dict(mitigation=.12,recharge=-1)),('Even Current',dict(delay=-1,recharge=2)),'Limiter',dict(mitigation=.15)),
 B('Emergency Reserve',dict(emergency=15,cooldown=2),('Rapid Reserve',dict(cooldown=-4,emergency=-5)),('Deep Reserve Cell',dict(emergency=15,cooldown=2)),'Last Stand',dict(emergency=20))]),
'relay': ('Relay', 'Fast recharge / instant restart', dict(damage=0,capacity=40,recharge=10,delay=2,cooldown=10,mitigation=0,break_recovery=0,duration=2), [
 B('Fast Restart',dict(delay=-.6),('Quick Switch',dict(delay=-.6,capacity=-5)),('Safe Switch',dict(capacity=10,delay=.2)),'Instant Link',dict(delay=-.6)),
 B('Sustained Recharge',dict(recharge=4,capacity=-5),('Strong Current',dict(recharge=4,delay=.5)),('Steady Current',dict(delay=-.5,recharge=1)),'Continuous Signal',dict(sustain=.4)),
 B('Recovery Pulse',dict(recovery=10,cooldown=2),('Frequent Pulse',dict(cooldown=-4,recovery=-3)),('Heavy Pulse',dict(recovery=12,cooldown=3)),'Return Signal',dict(recovery=15))]),
'feedback': ('Feedback', 'Retaliation / projectile reflection', dict(damage=0,capacity=50,recharge=8,delay=3,cooldown=13,mitigation=0,break_recovery=0,duration=2), [
 B('Reflection',dict(reflect=15),('Hot Mirror',dict(reflect=15,cooldown=2)),('Quick Mirror',dict(cooldown=-3,reflect=-3)),'Mirror Wall',dict(reflect=25)),
 B('Break Pulse',dict(break_damage=30),('Wide Pulse',dict(shield_radius=70,break_damage=-5)),('Heavy Pulse',dict(break_damage=25,cooldown=2)),'Feedback Crash',dict(break_damage=40)),
 B('Retaliation Charge',dict(retaliation=.5),('Quick Retort',dict(cooldown=-3,retaliation=-.1)),('Heavy Retort',dict(retaliation=.4,cooldown=2)),'Return to Sender',dict(retaliation=.6))]),
}
TUNES = {
'arc_aerial':[('Gain','damage_bonus',.15,3),('Tempo','cadence',.1,3),('Reach','reach',36,2),('Extra Contact','targets',1,2),('Long Charge','duration',.75,2),('Elite Hunter','elite_bonus',.15,2)],
'echo_deck':[('Replay Gain','echo_damage',.12,3),('Short Loop','attacks',-1,2),('Quick Replay','delay',-.09,2),('Extra Copy','copies',1,1),('Retarget','reach',34,2),('Replay Crit','crit',.05,2)],
'bass_driver':[('Gain','damage_bonus',.15,3),('Coverage','radius',15,2),('Tempo','cadence',.1,3),('Push','push',4,2),('Exposure','exposure',3,2),('Long Exposure','duration',.75,2)],
'needle_swarm':[('Gain','damage_bonus',.15,3),('Tempo','cadence',.1,3),('Pierce','pierce',1,2),('Steering','steering',.6,2),('Extra Needle','projectiles',1,2),('Long Mark','duration',.75,2)],
'reverb_well':[('Long Well','duration',.6,2),('Coverage','radius',15,2),('Strong Pull','pull',6.4,2),('Tick Gain','damage_bonus',.15,3),('Tempo','cadence',.1,3),('More Targets','targets',2,2)],
'static_net':[('Deep Slow','slow',.05,2),('Long Net','duration',.6,2),('Coverage','radius',16.5,2),('Tempo','cadence',.1,3),('Interception','charges',1,2),('Residual','residual',.12,2)]}
for key in ['pulse','sweep','burst']:
 TUNES[key]=[('Gain','damage_bonus',.15,3),('Tempo','cadence',.1,3),('Critical Signal','crit',.05,2),('Reach','reach',60,2),('Coverage','width',8 if key!='burst' else 15,2),('Penetration','penetration',15,2)]
TUNES['pulse'][4] = ('Extra Contact','pierce',1,2)
for key in ['capacitor','relay','feedback']:
 TUNES[key]=[('Capacity','capacity',10,3),('Recharge','recharge',2,3),('Quick Restart','delay',-.3,2),('Ability Tempo','cooldown',-1,2),('Mitigation','mitigation',.04,2),('Break Recovery','break_recovery',3,2)]

def val(v):
 if isinstance(v,dict): return '{'+', '.join('&'+json.dumps(k)+': '+val(x) for k,x in v.items())+'}'
 return str(float(v))
def run():
 base=ROOT/'content/arsenal'; (base/'upgrades').mkdir(parents=True,exist_ok=True); (base/'tracks').mkdir(exist_ok=True)
 rows={}
 def label(key,text): rows[key]=text; return key
 for chassis,(name,role,baseline,branches) in TRACKS.items():
  target='main' if chassis in ['pulse','sweep','burst'] else 'shield' if chassis in ['capacitor','relay','feedback'] else chassis
  prefix='M5_'+chassis.upper(); ids=[]
  def option(key,name,effects,rank=0,prereq='',cap=1):
   id='m5.'+chassis+'.'+key; ids.append(id); loc=prefix+'_'+key.upper()
   def effect_text(k,v):
    phrases={'orbit':'Orbit trapped enemies','reserve':'Store shield restoration','overheal':'Overflow becomes overshield','stagger':'Stagger the volley','distinct':'Replay at other targets','priority':'Prioritize elites and marked targets','terminal':'Burst when the well ends','release':'Launch enemies back on release'}
    if k in phrases: return phrases[k]
    if k=='reflect': return ('%+g'%v)+' reflected damage'
    if k=='break_damage': return ('%+g'%v)+' shield-break damage'
    if k=='steering': return 'Sharper homing' if v>0 else 'Straight flight'
    if k=='speed': return 'Faster projectiles' if v>0 else 'Slower projectiles'
    if k=='falloff': return 'Damage fades after each pierced target'
    friendly={'damage_bonus':'base damage','cadence':'attack speed','crit':'crit chance','elite_bonus':'elite damage','echo_damage':'replay damage','mitigation':'damage reduction','mark':'mark strength','slow':'slow','tick_rate':'tick speed','retaliation':'retaliation charge','sustain':'recharge while under fire'}
    labels={'copies':'replays','attacks':'shots per replay','charges':'interceptions','bounce':'ricochets','healing':'shield per discharge','emergency':'emergency shield','recovery':'shield per activation','break_recovery':'break recovery','penetration':'armor penetration'}
    if k in ['duration','delay','cooldown','residual']:
     label={'duration':'duration','delay':'replay delay' if chassis=='echo_deck' else 'recharge delay','cooldown':'ability cooldown','residual':'lingering slow'}[k]
     return ('%+g'%round(v,2))+'s '+label
    percent=k in friendly
    return ('%+g'%round(v*(100 if percent else 1),2))+('% ' if percent else ' ')+friendly.get(k,labels.get(k,k.replace('_',' ')))
   desc=', '.join(effect_text(k,v) for k,v in effects.items() if k not in ['mode','modifier','capstone']) or role
   label(loc+'_NAME',name); label(loc+'_SHORT',desc.capitalize()); label(loc+'_DESC',desc.capitalize()+'.')
   (base/'upgrades'/(id+'.tres')).write_text('[gd_resource type="Resource" script_class="UpgradeDefinition" load_steps=2 format=3]\n[ext_resource type="Script" path="res://scripts/core/definitions/upgrade_definition.gd" id="1"]\n[resource]\nscript = ExtResource("1")\nid = &"'+id+'"\nname_key = &"'+loc+'_NAME"\ndescription_key = &"'+loc+'_DESC"\ntarget_id = &"'+target+'"\nrequired_rank = '+str(rank)+'\nprerequisite = &"'+prereq+'"\nstack_cap = '+str(cap)+'\nstat = &"m5_marker"\neffects = '+val(effects)+'\n')
  for n,(title,stat,amount,cap) in enumerate(TUNES[chassis]): option('t'+str(n),title,{stat:amount},cap=cap)
  for n,(title,fx,mods,cap_title,cap_fx) in enumerate(branches,1):
   root='m5.'+chassis+'.b'+str(n)
   option('b'+str(n),title,dict(fx,mode=n),3)
   for m,(mt,mfx) in enumerate(mods,1): option('b'+str(n)+'m'+str(m),mt,dict(mfx,modifier=m),6,root)
   option('b'+str(n)+'cap',cap_title,dict(cap_fx,capstone=1),8,root)
  label(prefix+'_NAME',name); label(prefix+'_PREVIEW',role)
  ext=''.join('[ext_resource type="Resource" path="res://content/arsenal/upgrades/'+id+'.tres" id="'+str(i+2)+'"]\n' for i,id in enumerate(ids))
  defaults=dict(damage=0,interval=1,damage_bonus=0,cadence=0,crit=0,reach=180,width=24,targets=1,pierce=0,penetration=0,duration=3,mode=0,modifier=0,capstone=0)
  defaults.update(baseline)
  (base/'tracks'/(chassis+'.tres')).write_text('[gd_resource type="Resource" script_class="TrackDefinition" load_steps=20 format=3]\n[ext_resource type="Script" path="res://scripts/progression/track_definition.gd" id="1"]\n'+ext+'[resource]\nscript = ExtResource("1")\nid = &"'+target+'"\nname_key = &"'+prefix+'_NAME"\npreview_key = &"'+prefix+'_PREVIEW"\nsupport = '+('true' if target not in ['main','shield'] else 'false')+'\nattack_kind = &\"'+('area' if chassis in ['sweep','bass_driver','static_net','reverb_well'] else 'direct')+'\"\nbaseline = '+val(defaults)+'\noptions = ['+', '.join('ExtResource("'+str(i+2)+'")' for i in range(18))+']\n')
  if target not in ['main','shield']:
   label('M3_'+target.upper()+'_SHORT_NAME',name)
   for suffix,text in [('NAME',name),('SHORT',role),('DESC',role+'. Starts at rank 1.')]: label('SIGNAL_'+target.upper()+'_NEW_'+suffix,text)
 csvpath=ROOT/'assets/ui_strings.csv'
 with csvpath.open(newline='') as f: existing=list(csv.reader(f))
 existing=[r for r in existing if r[0] not in rows]
 with csvpath.open('w',newline='') as f: csv.writer(f, lineterminator="\n").writerows(existing+list(rows.items()))
 print('Generated 12 tracks, 216 options (108 support), and localized descriptions.')
if __name__=='__main__': run()
