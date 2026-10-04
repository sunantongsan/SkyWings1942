"""Assemble Xian of Clans without legacy Galaxy assets."""
from pathlib import Path
import argparse
import shutil

repo = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('--output', default='game')
args = parser.parse_args()
target = Path(args.output).resolve()
source = repo / 'xian'
if target == repo or repo.is_relative_to(target) or target.is_relative_to(source):
    raise SystemExit('Output must be separate from versioned source')
if target.exists() and any(target.iterdir()):
    raise SystemExit('Choose an empty output directory to avoid mixing old game assets')
shutil.copytree(source, target, dirs_exist_ok=True,
                ignore=shutil.ignore_patterns('.godot', 'build', '*.import'))
print('Xian of Clans project:', target)
