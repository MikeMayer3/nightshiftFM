#!/usr/bin/env python3
"""Generate M7 sidegrades and explicitly labeled campaign shell definitions."""
from pathlib import Path
import csv,io,re
ROOT=Path(__file__).resolve().parents[1]
MODULES=[
('hot_tubes','Hot Tubes',4,{'attack_rate':.15,'recharge':-.20},'+15% auto-attack rate; −20% shield recharge.'),
('long_mast','Long Mast',5,{'reach':.20,'hull':-.10},'+20% targeting range within the entry limit; −10% maximum hull.'),
('heavy_battery','Heavy Battery',4,{'capacity':.25,'recharge':-.20},'+25% shield capacity; −20% shield recharge.'),
('fast_fuse','Fast Fuse',5,{'cooldown':-.15,'capacity':-.15},'−15% shield-ability cooldown; −15% shield capacity.'),
('signal_booster','Signal Booster',6,{'damage':.15,'delay':1.0},'+15% additive attack damage; +1 second shield recharge delay.'),
('quiet_room','Quiet Room',6,{'recharge':.25,'support_rate':-.10},'+25% shield recharge; −10% support activation rate.'),
('wideband_module','Wideband Module',7,{'radius':.20,'direct_damage':-.15},'+20% area radius; −15% direct attack damage.'),
('narrowband_module','Narrowband Module',8,{'direct_damage':.20,'radius':-.15},'+20% direct attack damage; −15% area radius.'),
('counterweight','Counterweight',9,{'force':.25,'speed':-.10},'+25% push and pull force; −10% projectile travel speed.'),
('thin_wire','Thin Wire',10,{'charged':.30,'capacity':-.10},'+30% Charged duration; −10% shield capacity.'),
('night_ledger','Night Ledger',11,{'rerolls':1.0,'main_damage':-.10},'+1 run reroll; −10% main attack damage.'),
('glass_tower','Glass Tower',12,{'main_crit':.10,'hull':-.15},'+10 percentage points main critical chance; −15% maximum hull.'),
]
strings={}
for ident,name,unlock,effects,desc in MODULES:
 key='M7_MODULE_'+ident.upper();strings[key]=name;strings[key+'_DESC']=desc
 values=', '.join('&"%s": %s'%(k,repr(v)) for k,v in effects.items())
 (ROOT/'content/modules'/f'{ident}.tres').write_text(f'''[gd_resource type="Resource" script_class="ModuleDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/module_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"{ident}"
name_key = &"{key}"
description_key = &"{key}_DESC"
unlock_mission = 0
effects = {{{values}}}
''')
wave_ids=[]
for i in range(1,11):
 text=(ROOT/'content/active/waves'/('wave_8_turrets.tres' if i==8 else f'wave_{i}.tres')).read_text()
 wave_ids.append(re.search(r'^id = &"([^"]+)"',text,re.M).group(1))
regions=['Rooftop Relays','Flooded Switchyard','Dead Band']
for i in range(1,13):
 # M8 owns authored encounters; regenerating M7 modules must preserve them.
 existing=ROOT/'content/missions'/f'campaign_{i:02}.tres'
 if existing.exists() and 'prototype = false' in existing.read_text(): continue
 key=f'M7_MISSION_{i}';strings[key]=f'{regions[(i-1)//4]} · {i}'
 strings[key+'_DESC']='Prototype battle: reuses the current ten-wave encounter. Authored campaign battles arrive in M8.'
 values=', '.join('&"'+x+'"' for x in wave_ids)
 (ROOT/'content/missions'/f'campaign_{i:02}.tres').write_text(f'''[gd_resource type="Resource" script_class="MissionDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/mission_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"campaign.{i:02}"
name_key = &"{key}"
description_key = &"{key}_DESC"
campaign_index = {i}
prototype = true
wave_ids = Array[StringName]([{values}])
''')
module_lines='\n'.join('\t&"%s": preload("res://content/modules/%s.tres"),'%(m[0],m[0]) for m in MODULES)
mission_lines='\n'.join('\tpreload("res://content/missions/campaign_%02d.tres"),'%i for i in range(1,13))
(ROOT/'scripts/campaign/campaign_content.gd').write_text('''class_name CampaignContent
extends RefCounted
const VERSION: String = "m7.1"
const MODULES: Dictionary = {
'''+module_lines+'''
}
const MISSIONS: Array[MissionDefinition] = [
'''+mission_lines+'''
]
static func options(cleared: int, category: String) -> Array:
	if category == "main":
		var ids: Array = ["pulse"]
		if cleared >= 4: ids.append("sweep")
		if cleared >= 6: ids.append("burst")
		return ids
	if category == "shield":
		var ids: Array = ["capacitor"]
		if cleared >= 3: ids.append("relay")
		if cleared >= 8: ids.append("feedback")
		return ids
	if category == "support":
		var ids: Array = ["arc_aerial", "bass_driver", "static_net"]
		if cleared >= 2: ids.append("echo_deck")
		if cleared >= 3: ids.append("reverb_well")
		if cleared >= 4: ids.append("needle_swarm")
		return ids
	var ids: Array = []
	for id: StringName in MODULES:
		if cleared >= MODULES[id].unlock_mission: ids.append(String(id))
	return ids

static func valid_modules(value: Variant, cleared: int = 12) -> bool:
	if not SaveChecks.ids(value, 2) or not SaveChecks.unique(value): return false
	for id: Variant in value:
		if String(id) not in options(cleared, "modules"): return false
	return true

static func valid_selection(loadout: Variant, modules: Variant, cleared: int) -> bool:
	if not ArsenalContent.valid_loadout(loadout) or not valid_modules(modules, cleared): return false
	for category: String in ["main", "shield", "support"]:
		if loadout[category] not in options(cleared, category): return false
	return true
''')
p=ROOT/'assets/ui_strings.csv';rows=list(csv.reader(io.StringIO(p.read_text())));keys={r[0]:i for i,r in enumerate(rows) if r}
for key,value in strings.items():
 if key in keys:rows[keys[key]]=[key,value]
 else:rows.append([key,value])
buf=io.StringIO();csv.writer(buf,lineterminator='\n').writerows(rows);p.write_text(buf.getvalue())
print('Generated 12 modules and 12 prototype mission definitions.')
