#!/usr/bin/env python3
"""Export the unchanged game under an isolated QA package; preserve regular app saves."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
output = args.output.resolve()
output.parent.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='nightshift-patchboard-qa-') as folder:
    project = Path(folder) / 'project'
    shutil.copytree(root, project, ignore=shutil.ignore_patterns('.git', '.godot', 'builds', 'docs', 'prompts', '__pycache__'))
    config = project / 'export_presets.cfg'
    config.write_text(config.read_text().replace('org.nightshiftfm.spike', 'org.nightshiftfm.patchboardqa').replace('package/name="Nightshift FM"', 'package/name="Nightshift Patchboard QA"'))
    hashes = {}
    for directory in ['scripts', 'scenes', 'content', 'assets']:
        for path in sorted((root / directory).rglob('*')):
            if path.is_file():
                relative = path.relative_to(root)
                assert path.read_bytes() == (project / relative).read_bytes()
                hashes[str(relative)] = hashlib.sha256(path.read_bytes()).hexdigest()
    subprocess.run(['sh', str(project / 'tools/godot.sh'), 'import'], check=True)
    subprocess.run([os.environ['GODOT_BIN'], '--headless', '--path', str(project), '--export-debug', 'Android Debug', str(output)], check=True)
    output.with_suffix('.manifest.json').write_text(json.dumps({'apk_sha256': hashlib.sha256(output.read_bytes()).hexdigest(), 'runtime_sources': hashes, 'differences': ['Android package ID and app label only; regular boot scene and game runtime unchanged']}, indent=2))
print(output)
