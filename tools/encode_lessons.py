"""Encode actual Godot captures as portable offline Theora videos (no extra Android plugin)."""
from pathlib import Path
import subprocess, sys
project=Path(sys.argv[1]).resolve()
output=project/'assets/tutorial';output.mkdir(parents=True,exist_ok=True)
for topic in ['build','power','upgrade','camp','train','raid','camera']:
    frames=project/'build/lesson_frames'/topic
    assert len(list(frames.glob('*.png')))==120, topic
    subprocess.run(['ffmpeg','-hide_banner','-loglevel','error','-y','-framerate','15','-i',str(frames/'%04d.png'),'-vf','scale=960:540','-c:v','libtheora','-q:v','6','-an',str(output/(topic+'.ogv'))],check=True)
    # Human-review frame from the middle of the same real recording.
    review=project/'build/review';review.mkdir(parents=True,exist_ok=True)
    (review/('lesson-'+topic+'.png')).write_bytes((frames/'0065.png').read_bytes())
print('ENCODED_SEVEN_OFFLINE_TUTORIAL_VIDEOS')
