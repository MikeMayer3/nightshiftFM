#!/usr/bin/env python3
"""Verify M8 generators and a clean source import without touching player saves."""
from pathlib import Path
import hashlib
import json
import os
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
engine = os.environ['GODOT_BIN']
evidence = root / 'docs/evidence/M8'
evidence.mkdir(parents=True, exist_ok=True)
dest = Path(tempfile.mkdtemp(prefix='nightshift-m8-fresh-')) / 'project'
shutil.copytree(root, dest, ignore=shutil.ignore_patterns('.git', '.godot', 'builds', 'evidence', '__pycache__'))
# Earlier suites write results under these source directories. Retain the
# directory structure without copying old evidence or the Godot import cache.
for directory in (root / 'docs/evidence').rglob('*'):
    if directory.is_dir():
        (dest / directory.relative_to(root)).mkdir(parents=True, exist_ok=True)
files = [*dest.glob('content/**/*.tres'), dest / 'assets/ui_strings.csv', *dest.glob('scripts/campaign/*.gd')]

def hashes():
    return {str(p.relative_to(dest)): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}

before = hashes()
for script in ['generate_campaign_content.py', 'generate_encounter_content.py']:
    subprocess.run(['python3', str(dest / 'tools' / script)], cwd=dest, check=True)
after = hashes()
changed = [key for key in before if before[key] != after[key]]
result = {'path': str(dest), 'generator_changes': changed, 'generators_idempotent': not changed, 'checks': []}
for name, args in [('import', ['--import']), ('test', ['--script', 'res://tests/test_runner.gd']), ('smoke', ['--quit-after', '10'])]:
    with (evidence / f'fresh-{name}.txt').open('w') as output:
        done = subprocess.run([engine, '--headless', '--path', str(dest), *args], stdout=output, stderr=subprocess.STDOUT)
    result['checks'].append({'check': name, 'exit': done.returncode})
    if done.returncode:
        break
(evidence / 'fresh.json').write_text(json.dumps(result, indent=2) + '\n')
print(json.dumps(result, indent=2))
raise SystemExit(0 if not changed and len(result['checks']) == 3 and all(x['exit'] == 0 for x in result['checks']) else 1)
