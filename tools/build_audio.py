"""Original synthesized military-style brass cues; no sampled copyrighted music."""
from pathlib import Path
import math,wave,struct
ROOT=Path(__file__).resolve().parents[1]/'godot_override/assets/audio'
ROOT.mkdir(parents=True,exist_ok=True)
RATE=22050

def cue(name,notes):
    samples=[]
    for frequency,duration,bend in notes:
        phase=0.0
        for i in range(int(duration*RATE)):
            t=i/RATE;phase+=2*math.pi*frequency*(1+bend*t/duration)/RATE
            attack=min(1,t/.022);release=min(1,(duration-t)/.11)
            envelope=attack*release*(.72+.28*math.exp(-t*12))
            brass=sum(math.sin(phase*h)*math.exp(-.33*(h-1))/h for h in range(1,11))
            samples.append(brass*envelope*.43)
        samples.extend([0.0]*int(.045*RATE))
    # A quiet short room echo gives the horn body, bounded to avoid clipping.
    dry=samples[:];delay=int(.09*RATE)
    for i in range(delay,len(samples)):samples[i]+=dry[i-delay]*.12
    with wave.open(str(ROOT/name),'wb') as out:
        out.setnchannels(1);out.setsampwidth(2);out.setframerate(RATE)
        out.writeframes(b''.join(struct.pack('<h',int(max(-.95,min(.95,v))*32767)) for v in samples))
cue('victory_bugle.wav',[(392,.2,0),(392,.16,0),(523.25,.32,0),(659.25,.32,0),(783.99,.7,0),(1046.5,.65,0)])
cue('defeat_brass.wav',[(392,.35,-.02),(329.63,.4,-.04),(261.63,.5,-.05),(196,.65,-.13)])
