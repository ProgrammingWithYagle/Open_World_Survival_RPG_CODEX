"""Original score and procedural foley for The Mossbound Atlas.

No downloaded samples or generated music services. The score below is authored
as notes, chords, rhythms and instrument envelopes; the output is deterministic.
"""
import json
import math
import wave
from pathlib import Path
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'godot/audio'
RATE=22050
RNG=np.random.default_rng(815370)
REPORT={}

def save(name,a,loop=False):
    a=np.nan_to_num(a)
    if a.ndim==1:a=np.column_stack((a,a))
    peak=float(np.max(np.abs(a)))
    if peak>0.89:a*=0.89/peak
    # Remove DC and suppress discontinuities without flattening transients.
    a-=a.mean(axis=0)
    edge=min(180,len(a)//4)
    a[:edge]*=np.linspace(0,1,edge)[:,None]
    a[-edge:]*=np.linspace(1,0,edge)[:,None]
    # Edge fades can reintroduce DC in short impacts. Remove it through the
    # same window so the first/last samples remain exactly silent.
    window=np.ones(len(a),dtype=np.float32)
    window[:edge]=np.linspace(0,1,edge)
    window[-edge:]=np.linspace(1,0,edge)
    a-=window[:,None]*(a.sum(axis=0)/window.sum())[None,:]
    final_peak=float(np.max(np.abs(a)))
    if final_peak>.89:a*=.89/final_peak
    pcm=(np.clip(a,-1,1)*32767).astype('<i2')
    with wave.open(str(OUT/(name+'.wav')),'wb') as f:
        f.setnchannels(2);f.setsampwidth(2);f.setframerate(RATE);f.writeframes(pcm.tobytes())
    REPORT[name]={'seconds':round(len(a)/RATE,3),'peak':round(float(np.max(np.abs(a))),5),'rms':round(float(np.sqrt(np.mean(a*a))),5),'loop':loop}

def hz(note):return 440.0*2**((note-69)/12)

def voice(note,duration,kind='pluck',velocity=1):
    n=max(1,int(duration*RATE));t=np.arange(n)/RATE;f=hz(note)
    attack=np.minimum(1,t/(.018 if kind=='flute' else .004))
    release=np.minimum(1,(duration-t)/(.16 if kind=='flute' else .045))
    if kind=='pluck':
        y=(np.sin(2*np.pi*f*t)+.31*np.sin(2*np.pi*f*2*t)+.12*np.sin(2*np.pi*f*3*t))*np.exp(-t*5.0)
    elif kind=='bell':
        y=(np.sin(2*np.pi*f*t)+.28*np.sin(2*np.pi*f*2.003*t)+.11*np.sin(2*np.pi*f*3.98*t))*np.exp(-t*3.5)
    elif kind=='flute':
        vibrato=.0025*np.sin(2*np.pi*4.4*t)*np.minimum(t*3,1)
        y=(np.sin(2*np.pi*f*t+vibrato*np.sin(2*np.pi*f*t))+.07*np.sin(4*np.pi*f*t))*np.exp(-t*.8)
        y+=RNG.normal(0,.012,n)*np.minimum(t*10,1)
    elif kind=='bass':y=(np.sin(2*np.pi*f*t)+.13*np.sin(4*np.pi*f*t))*np.exp(-t*2)
    else:y=(np.sin(2*np.pi*f*t)+.14*np.sin(2*np.pi*f*1.001*t))*np.minimum(t/.15,1)*np.exp(-t*.7)
    return (y*attack*release*velocity).astype(np.float32)

def add(buffer,when,sample,volume=.15,pan=0):
    start=int(when*RATE)
    if start>=len(buffer):return
    sample=sample[:len(buffer)-start]
    buffer[start:start+len(sample),0]+=sample*volume*math.sqrt((1-pan)/2)
    buffer[start:start+len(sample),1]+=sample*volume*math.sqrt((1+pan)/2)

# An original rising fourth / falling third motif; each region develops it.
THEMES={
 'bracken':{'root':50,'bpm':84,'scale':[0,2,3,5,7,9,10],'chords':[[0,3,7],[5,9,12],[10,14,17],[7,10,14]],'lead':'flute'},
 'fen':{'root':55,'bpm':76,'scale':[0,2,4,6,7,9,11],'chords':[[0,4,7],[2,6,9],[9,12,16],[7,11,14]],'lead':'bell'},
 'cinder':{'root':45,'bpm':92,'scale':[0,2,3,5,7,8,10],'chords':[[0,3,7],[8,12,15],[5,8,12],[7,10,14]],'lead':'pluck'},
 'storm':{'root':52,'bpm':88,'scale':[0,2,3,5,7,9,10],'chords':[[0,3,7],[9,12,16],[5,9,12],[7,10,14]],'lead':'flute'},
 'hollow':{'root':53,'bpm':72,'scale':[0,2,4,5,7,9,11],'chords':[[0,4,7],[9,12,16],[5,9,12],[7,11,14]],'lead':'bell'},
 'combat':{'root':50,'bpm':116,'scale':[0,2,3,5,7,8,10],'chords':[[0,3,7],[0,5,8],[8,12,15],[7,10,14]],'lead':'pluck'},
}

def compose(name,score):
    beat=60/score['bpm'];length=64*beat
    out=np.zeros((int(RATE*length),2),np.float32)
    root=score['root'];scale=score['scale']
    melody=[(0,0,1),(1.5,3,.5),(2,2,1),(3.25,0,.5), (4,4,1.5),(6,3,.5),(6.75,1,.75), (8,2,1),(9.5,5,.5),(10,4,1),(11.5,2,.5), (12,1,1.5),(14,0,1)]
    for bar in range(16):
        chord=score['chords'][(bar//2)%4]
        for j,offset in enumerate([0,.75,1.5,2.25,3,3.5]):
            note=root+12+chord[(j+bar)%3]
            add(out,(bar*4+offset)*beat,voice(note,1.05,'pluck'),.11,(-.4 if j%2 else .35))
        for offset in (0,2):add(out,(bar*4+offset)*beat,voice(root+chord[0]-12,1.2,'bass'),.16,0)
        if name in ('cinder','combat'):
            for offset in (0,1,2,3):
                n=int(.12*RATE);t=np.arange(n)/RATE
                drum=np.sin(2*np.pi*(72*t-130*t*t))*np.exp(-t*36)+RNG.normal(0,.05,n)*np.exp(-t*45)
                add(out,(bar*4+offset)*beat,drum,.12 if offset%2==0 else .055,0)
        if bar%4==3:
            add(out,(bar*4+3.25)*beat,voice(root+24+chord[2],.5,'bell'),.06,.55)
    for phrase in range(4):
        for onset,degree,dur in melody:
            octave=12+(12 if phrase==2 else 0)
            if phrase==3 and onset>=12:degree=max(0,degree-1)
            note=root+octave+scale[degree]
            add(out,(phrase*16+onset)*beat,voice(note,dur*beat,score['lead']),.16,-.12)
        # A restrained answering line in the rests rather than a continuous drone.
        add(out,(phrase*16+7.5)*beat,voice(root+19,beat*.6,'bell'),.065,.4)
        add(out,(phrase*16+15)*beat,voice(root+12,beat*.8,'pluck'),.09,.35)
    wet=np.zeros_like(out)
    for delay,gain in ((.137,.14),(.293,.09),(.443,.04)):
        wet+=np.roll(out,int(delay*RATE),axis=0)[:,::-1]*gain
    save('music_'+name,out+wet,True)

def effects():
    for index in range(6):
        n=int(RATE*.15);t=np.arange(n)/RATE;noise=RNG.normal(0,1,n)
        dull=np.convolve(noise,np.ones(9)/9,mode='same')
        save('step_'+str(index),dull*np.exp(-t*48)*.35)
    for name,freq,decay in [('wood',180,24),('stone',650,36),('hit',110,20),('hurt',83,12),('build',230,22)]:
        n=int(RATE*.32);t=np.arange(n)/RATE
        noise=RNG.normal(0,.12,n);y=(np.sin(2*np.pi*freq*t)+.3*np.sin(2*np.pi*freq*1.48*t)+noise)*np.exp(-t*decay)*.3
        save(name,y)
    for name,notes in [('pickup',[76,83]),('craft',[62,69,74]),('eat',[55,60]),('restore',[62,65,69,74,77]),('victory',[62,69,74,77,81,86]),('ui',[75]),('spell',[81,88,93])]:
        out=np.zeros((int(RATE*(len(notes)*.12+.9)),2),np.float32)
        for i,note in enumerate(notes):add(out,i*.12,voice(note,.8,'bell'),.24,(-.2 if i%2 else .2))
        save(name,out)
    n=int(RATE*.24);t=np.arange(n)/RATE;noise=RNG.normal(0,1,n)
    save('swing',noise*np.sin(np.pi*t/.24)**2*.12)
    save('bow',voice(59,.45,'pluck')*.35)
    # Forest bed: low wind, leaf rustle, and a few short bird calls in the distance.
    n=RATE*24;t=np.arange(n)/RATE
    wind=RNG.normal(0,.03,n)
    wind=np.convolve(wind,np.ones(61)/61,mode='same')*(.5+.5*np.sin(t*.23)**2)
    bed=np.column_stack((wind,np.roll(wind,500)))
    for when in (1.2,4.7,8.1,13.2,18.7,21.1):
        for offset,note in ((0,90),(.13,94),(.28,92)):
            add(bed,when+offset,voice(note,.18,'flute'),.035,-.55 if when<12 else .55)
    save('ambience_forest',bed,True)

if __name__=='__main__':
    OUT.mkdir(parents=True,exist_ok=True)
    for name,score in THEMES.items():compose(name,score)
    effects()
    (OUT/'audio_manifest.json').write_text(json.dumps(REPORT,indent=2)+'\n')
    (ROOT/'docs/ORIGINAL_AUDIO_SCORE.json').write_text(json.dumps({'composer':'Original score authored for The Mossbound Atlas','sample_rate':RATE,'themes':THEMES,'motif':'See tools/compose_audio.py for note and rhythm notation.','samples':'Synthesized instruments and procedural foley; no third-party samples.'},indent=2)+'\n')
    print(f'Composed {len(THEMES)} original themes and {len(REPORT)-len(THEMES)} sound/ambience assets.')
