#!/usr/bin/env python3
"""Expanded M8 content. Preserve legacy opening waves and stable display IDs."""
from pathlib import Path
import csv,io
from generate_encounter_content import write_resource,names
ROOT=Path(__file__).resolve().parents[1]
# ID, role, display, HP, speed, armor, description/counter.
ENEMIES=[
 ('plated',1,'Rugged Player',60,34,90,'Armored music player. Exposure and penetration reduce its plating; concentrated fire also works.'),
 ('caster',2,'Sync Hub',40,33,0,'A sync hub protects nearby devices during a short link cycle. Focus or interrupt the hub; protection never makes targets immune.'),
 ('jammer',3,'Noise-Cancel Buds',32,38,0,'Channels a brief mute on one support. Focus the marked earbuds or interrupt them; the main tower always keeps firing.'),
 ('mimic',4,'Smartwatch',48,42,20,'Cycles between a visible guard and an open face. Mixed fire works in every state; concentrate attacks while open.'),
 ('mortar',5,'Streaming Dock',55,38,0,'Stops high in the field and flashes before firing destructible data packets. Focus the dock or intercept the packets.'),
 ('caller',6,'The Playlist',270,35,20,'Boss: a giant music player alternates escorts and flashing packet volleys. Clear escorts, focus the player and time your shield.'),
 ('core',7,'Cloud Speaker',340,32,35,'Boss: destroy both satellite speakers to expose the cloud core. Ordinary tower attacks can target every satellite.'),
 ('silence',8,'The Noise Canceller',430,30,45,'Boss: rotating open-face windows, one-support mute cycles and telegraphed volleys. Control effects slow its attack cycle without permanent stun.'),
 ('aerial',9,'Satellite Speaker',65,38,15,'Cloud Speaker weak point. Both satellites take ordinary damage; destroy them to expose the core.'),
]
TITLES=['First Transmission','Carrier Traffic','Crossed Wires','The Playlist','Heavy Rotation','Shared Connection','Packet Storm','Cloud Speaker','Quiet Channels','Changing Faces','Digital Crossfire','The Noise Canceller']
# Each mission has deliberate composition and an early introduction before its finale.
GROUPS={4:['m2.swarmer','m2.carrier','m2.swarmer','m2.diver'],5:['m2.swarmer','m8.plated','m2.swarmer','m2.diver'],6:['m2.swarmer','m8.caster','m8.plated','m2.swarmer'],7:['m2.diver','m8.mortar','m2.swarmer','m8.plated'],8:['m8.caster','m2.swarmer','m8.mortar','m8.plated'],9:['m2.swarmer','m8.jammer','m2.diver','m8.caster'],10:['m8.mimic','m2.swarmer','m8.jammer','m2.diver'],11:['m2.swarmer','m8.mortar','m2.swarmer','m8.plated'],12:['m8.jammer','m8.mimic','m8.mortar','m2.diver']}
STRINGS={}
for ident,role,name,hp,speed,armor,desc in ENEMIES:
 key='BROADCAST_ENEMY_'+ident.upper();STRINGS[key]=name;STRINGS[key+'_DESC']=desc
 write_resource(ROOT/f'content/broadcast/enemies/{ident}.tres','EnemyDefinition','m8.'+ident,key,f'role = {role}\nhealth = {float(hp)}\nspeed = {float(speed)}\narmor = {float(armor)}\nradius = {38.0 if role in [6,7,8] else 24.0}\nbreach_damage = {30.0 if role in [6,7,8] else 16.0}\nelite = {str(role in [6,7,8,9]).lower()}\nability_interval = {6.0 if role in [5,6,7,8] else 4.0}')
registry=['class_name BroadcastContent','extends RefCounted','const ENEMIES: Array[EnemyDefinition] = [']
registry += [f'\tpreload("res://content/broadcast/enemies/{row[0]}.tres"),' for row in ENEMIES]
registry += [']','static func enemy(id: StringName) -> EnemyDefinition:','\tfor definition: EnemyDefinition in ENEMIES:','\t\tif definition.id == id: return definition','\treturn EncounterContent.enemy(id)']
(ROOT/'scripts/campaign/broadcast_content.gd').write_text('\n'.join(registry)+'\n')
registry=['class_name BroadcastWaves','extends RefCounted','## Versioned expanded campaign; old checkpoint waves remain in EncounterWaves.','const MISSIONS: Dictionary = {']
for mission in range(1,13):
 registry.append(f'\t{mission}: [')
 ids=[]
 for wave in range(1,11):
  if mission<=3:
   registry.append(f'\t\tpreload("res://content/encounters/waves/m{mission:02}_w{wave:02}.tres"),');ids.append(f'm8.m{mission:02}.w{wave:02}');continue
  group=GROUPS[mission].copy();groups=6+wave//3
  # Introduce the new role alone with cheap escorts, before mixed waves.
  if wave<=2:group=['m2.swarmer',group[1 if mission in [4,5,6,7,9] else 0],'m2.swarmer']
  enemies=group*groups
  if mission==11 and wave>2:
   for n in range(3,len(enemies),4): enemies[n]=['m8.plated','m8.mimic','m8.caster'][(n//4)%3]
  if mission in [4,8,12] and wave in [8,10]:
   enemies=(group*2 if wave==8 else group*3)+['m8.'+{4:'caller',8:'core',12:'silence'}[mission]]
  elif wave in [6,9,10]: enemies[0]='m8.elite_'+(['swarmer','carrier','diver'][(mission-1)%3])
  if wave==10 and mission not in [4,8,12]:enemies[len(group)*3]=enemies[0]
  ident=f'm8.full.m{mission:02}.w{wave:02}';key=f'BROADCAST_M{mission}_W{wave}'
  STRINGS[key]=TITLES[mission-1]+f' · Wave {wave}';STRINGS[key+'_DESC']='Watch device tells and focus priority targets.'
  write_resource(ROOT/f'content/broadcast/waves/m{mission:02}_w{wave:02}.tres','WaveDefinition',ident,key,f'spawn_interval = {6.8 if mission<9 else 6.5}\ngroup_size = {len(group)}\nformation = {(mission+wave//3)%4}\nenemy_ids = {names(enemies)}');ids.append(ident)
  registry.append(f'\t\tpreload("res://content/broadcast/waves/m{mission:02}_w{wave:02}.tres"),')
 registry.append('\t],')
 if mission>3:
  key=f'M7_MISSION_{mission}';STRINGS[key]=f'{mission} · {TITLES[mission-1]}';STRINGS[key+'_DESC']='Protect the station through '+TITLES[mission-1]+'.'
  write_resource(ROOT/f'content/missions/campaign_{mission:02}.tres','MissionDefinition',f'campaign.{mission:02}',key,f'campaign_index = {mission}\nprototype = false\nwave_ids = {names(ids)}')
 STRINGS[f'BROADCAST_LOG_{mission}']=[
  'The first callers are still listening. The station stays on air.', 'Portable playlists swarm the rooftops, but the microphone holds.',
  'Wireless traffic crosses every lane. The tower finds a clear frequency.', 'The Playlist falls silent. Our first region can hear us again.',
  'Rugged players resist the signal. Brass and valves answer with pressure.', 'Sync hubs link the opposition. Breaking one link opens the whole group.',
  'Streaming docks fill the air with packets. Every intercepted shot buys time.', 'The cloud core loses its satellites. Broadcast reaches the switchyard.',
  'Noise cancellation steals a channel at a time. The main tower keeps speaking.', 'Watch faces shift their defenses. Mixed instruments find the opening.',
  'Every generation of device joins the attack. The station answers together.', 'The last cancellation field breaks. There is still room for live radio.'
 ][mission-1]
registry.append('}');(ROOT/'scripts/campaign/broadcast_waves.gd').write_text('\n'.join(registry)+'\n')
p=ROOT/'assets/ui_strings.csv';rows=list(csv.reader(io.StringIO(p.read_text())));indices={row[0]:i for i,row in enumerate(rows) if row}
for key,value in STRINGS.items():
 if key in indices:rows[indices[key]]=[key,value]
 else:rows.append([key,value])
buf=io.StringIO();csv.writer(buf,lineterminator='\n').writerows(rows);p.write_text(buf.getvalue())
print('Generated complete 12-mission registry, 90 new waves, five enemy roles, three bosses and targetable satellites.')

# Compact station presentation copy.
import csv
with (ROOT / "assets/ui_strings.csv").open(newline="") as f: rows = list(csv.reader(f))
replacements = {'M4_LEGEND': 'Dots: Charged · Pause marks: slowed · Slash: exposed\nCross: jammed · Bar and chevron: incoming shot', 'BROADCAST_ALL_CONNECTIONS': 'All connections', 'BROADCAST_READY_CONNECTIONS': 'Ready connections', 'BROADCAST_NO_CONNECTIONS': 'No connections ready. Go live or browse the recipes.', 'MENU_START': 'New broadcast', 'BOOT_EYEBROW': 'OFFLINE • STATION DEFENSE', 'BOOT_SUBTITLE': 'Keep the signal alive.', 'BOOT_FOOTER': 'Original radio instruments • Modern rivals', 'BROADCAST_PATCH_HINT': 'Choose a socket. Connect a ready pair. Go live.', 'BROADCAST_DETAILS': 'Details +', 'BROADCAST_HIDE_DETAILS': 'Details −', 'BROADCAST_GUARDED': 'GUARDED', 'BROADCAST_OPEN': 'OPEN', 'BROADCAST_CHANNEL': 'TUNING', 'BROADCAST_VOLLEY': 'PACKETS', 'BROADCAST_MUTED': 'MUTED'}
for row in rows:
    if row and row[0] in replacements: row[1] = replacements.pop(row[0])
rows.extend([[key, value] for key, value in replacements.items()])
with (ROOT / "assets/ui_strings.csv").open("w", newline="") as f: csv.writer(f, lineterminator="\n").writerows(rows)
