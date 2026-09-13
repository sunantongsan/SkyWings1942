"""Build the editable Godot project from versioned source and original GLBs."""
from pathlib import Path
import shutil, subprocess, sys, argparse
repo=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser();parser.add_argument('--output',default='game');args=parser.parse_args()
target=Path(args.output).resolve()
if target==repo or repo.is_relative_to(target):raise SystemExit('Output must not replace source')
subprocess.run([sys.executable,str(repo/'tools/build_models.py')],check=True)
target.mkdir(parents=True,exist_ok=True)
for name in ['project.godot','export_presets.cfg']:shutil.copy2(repo/'godot_src'/name,target/name)
shutil.copytree(repo/'godot_override',target,dirs_exist_ok=True,ignore=shutil.ignore_patterns('*.import','.godot','*.uid'))
print('Editable Godot project:',target)
