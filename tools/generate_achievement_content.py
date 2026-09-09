#!/usr/bin/env python3
"""Generate the M9 catalog from the 48 approved catalog rows, without inventing goals."""
from pathlib import Path
import csv
import io
import json
import re

ROOT = Path(__file__).resolve().parents[1]
LIVE = {'first_broadcast', 'patch_cable', 'sound_engineer', 'stereo', 'minimalist',
        'all_hands', 'soloist_duet', 'variety_show', 'deep_focus', 'no_scratches',
        'unbroken', 'second_wind', 'close_call'}
THRESHOLDS = {'local_legend': 4, 'deep_signal': 4, 'still_on_air': 4, 'full_schedule': 12,
              'new_dials': 3, 'backup_plans': 3, 'sound_engineer': 8, 'variety_show': 6,
              'bouncer': 100, 'know_enemy': 8, 'boss_notebook': 3, 'blueprint_collector': 12,
              'signal_archive': 12, 'endless_20': 20, 'endless_40': 40, 'endless_60': 60, 'endless_three': 20}
rows = re.findall(r'^\| `([^`]+)` \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$', (ROOT/'docs/CONTENT_CATALOG.md').read_text(), re.M)
assert len(rows) == 48, f'Expected 48 achievement rows, found {len(rows)}'
strings = {}
registry = ['class_name AchievementCatalog', 'extends RefCounted', '## Generated immutable catalog; pending entries cannot award progress.', 'const ALL: Dictionary = {']
folder = ROOT/'content/achievements'
folder.mkdir(parents=True, exist_ok=True)
for ident, category, name, condition in rows:
    key = 'M9_ACH_' + ident.upper()
    strings[key], strings[key+'_DESC'] = name.strip(), condition.strip()
    mastery = category.strip() == 'Weapon mastery'
    available = ident in LIVE or mastery
    threshold = 3 if ident.endswith('_three_capstones') else THRESHOLDS.get(ident, 1)
    family = ident.split('_first_capstone')[0].split('_three_capstones')[0] if mastery else ''
    parameters = '{&"family": &"'+family+'"}' if family else '{}'
    modes = ['contract'] if category.strip() == 'Contracts' else ['endless'] if category.strip() == 'Endless' else ['campaign','contract','endless'] if mastery else ['campaign']
    pending = 'M9_PENDING_ENDLESS' if category.strip() == 'Endless' else 'M9_PENDING_TELEMETRY' if ident in ['bouncer','hold_the_line'] else 'M9_PENDING_CAMPAIGN'
    progress_kind = 'set' if mastery or ident in ['sound_engineer','variety_show'] else 'flag' if threshold == 1 else 'counter'
    (folder/f'{ident}.tres').write_text(f'''[gd_resource type="Resource" script_class="AchievementDefinition" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/core/definitions/achievement_definition.gd" id="1"]
[resource]
script = ExtResource("1")
id = &"{ident}"
name_key = &"{key}"
description_key = &"{key}_DESC"
category = {json.dumps(category.strip())}
progress_kind = &"{progress_kind}"
threshold = {threshold}
condition_id = &"{ident}"
condition_parameters = {parameters}
eligible_modes = Array[StringName]([{', '.join('&'+json.dumps(x) for x in modes)}])
minimum_difficulty = {2 if ident == 'overtime' else 1 if ident == 'full_schedule' else 0}
reward_id = &"cosmetic.achievement.{ident}"
available = {str(available).lower()}
pending_key = &"{'' if available else pending}"
''')
    registry.append(f'\t&"{ident}": preload("res://content/achievements/{ident}.tres"),')
registry.append('}')
(ROOT/'scripts/achievements').mkdir(parents=True, exist_ok=True)
(ROOT/'scripts/achievements/achievement_catalog.gd').write_text('\n'.join(registry)+'\n')
strings.update({
 'M9_ACHIEVEMENTS':'Achievements', 'M9_HINT':'Cosmetic titles only. Progress is committed when an eligible mission ends in victory.',
 'M9_PENDING_ENDLESS':'Pending: Endless mode.', 'M9_PENDING_TELEMETRY':'Pending: committed defensive-event tracking.',
 'M9_PENDING_CAMPAIGN':'Pending: remaining campaign content and mode rules.',
 'M9_PROGRESS':'%d / %d', 'M9_EARNED':'Earned', 'M9_TRACK':'Track goal', 'M9_UNTRACK':'Untrack goal',
 'M9_TRACKED':'Tracked goals · up to three', 'M9_USE_TITLE':'Use cosmetic title', 'M9_ACTIVE_TITLE':'Active title: %s',
 'M9_NATIVE_UNAVAILABLE':'Saved on this device. Native achievement sync is not available yet.',
 'M9_PRACTICE':'Editor, debug and prototype runs do not earn achievements.',
 'M9_REPORT_HISTORY':'Station damage taken: %.1f · Peak supports: %d',
 'M9_REPORT_OUTPUT':'Effective damage: %.1f · Intercepted bolts: %d',
 'M9_REPORT_HINT':'Burst is included in main damage. Exposure assistance is reported separately and is not added to damage totals.',
 'M9_RESULT_ELIGIBLE':'This run records local achievements on victory.',
 'M9_RESULT_PRACTICE':'Practice or legacy run: achievement rewards disabled.',
})
p=ROOT/'assets/ui_strings.csv'; localized=list(csv.reader(io.StringIO(p.read_text())))
indices={r[0]:i for i,r in enumerate(localized) if r}
for key,value in strings.items():
    if key in indices: localized[indices[key]]=[key,value]
    else: localized.append([key,value])
buf=io.StringIO();csv.writer(buf,lineterminator='\n').writerows(localized);p.write_text(buf.getvalue())
print('Generated 48 definitions: 25 available, 23 explicitly pending.')
