#!/usr/bin/env python3
# Synthesizes the TAKEN IN PARIS soundscape: ambience beds, tension-reactive music
# layers, an accordion busker loop, and one-shot SFX. Mono 22050 Hz WAV; an ffmpeg pass
# converts each to seamless-looping OGG (libvorbis). No external assets / licensing.
import numpy as np, wave, os, struct

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "wav")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(20260615)

def t(dur): return np.linspace(0, dur, int(SR*dur), endpoint=False)
def sine(f, dur, ph=0.0): return np.sin(2*np.pi*f*t(dur)+ph)
def saw(f, dur, parts=8):
    x = np.zeros(int(SR*dur))
    for k in range(1, parts+1):
        x += (1.0/k)*np.sin(2*np.pi*f*k*t(dur))
    return x/np.max(np.abs(x)+1e-9)
def noise(dur): return rng.uniform(-1, 1, int(SR*dur))
def onepole_lp(x, a):  # a in (0,1), smaller = darker
    y = np.zeros_like(x); acc = 0.0
    for i in range(len(x)):
        acc += a*(x[i]-acc); y[i] = acc
    return y
def onepole_hp(x, a): return x - onepole_lp(x, a)
def env_exp(n, atk, dec):
    e = np.ones(n)
    a = int(atk*SR); d = int(dec*SR)
    if a > 0: e[:a] = np.linspace(0, 1, a)
    if d > 0 and d < n: e[-d:] = np.exp(-np.linspace(0, 5, d))
    return e
def fade_loop(x, fade=0.6):
    # crossfade the tail onto the head so the loop is seamless
    n = int(fade*SR); n = min(n, len(x)//3)
    head = x[:n].copy(); tail = x[-n:].copy()
    w = np.linspace(0, 1, n)
    x[:n] = head*w + tail*(1-w)
    return x[:-n]
def norm(x, peak=0.9):
    m = np.max(np.abs(x))+1e-9
    return (x/m)*peak
def save(name, x):
    x = np.clip(x, -1, 1)
    data = (x*32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name+".wav"), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(data.tobytes())
    print("  wav", name, f"{len(x)/SR:.1f}s")

# ---------------------------------------------------------------- ambience beds
def amb_street():
    dur = 14.0; n = int(SR*dur)
    base = onepole_lp(noise(dur), 0.012)*0.5          # low traffic rumble
    hum  = sine(70, dur)*0.05 + sine(110, dur)*0.03
    # occasional distant car-pass swells
    x = base+hum
    for _ in range(5):
        sw = onepole_lp(noise(2.5), 0.02)*np.hanning(int(2.5*SR))*rng.uniform(0.2,0.4)
        s = int(rng.uniform(0, dur-3)*SR)
        if s+len(sw) <= n: x[s:s+len(sw)] += sw
    # faint pigeon coos (two short warbles)
    for _ in range(3):
        f0 = rng.uniform(380, 460)
        w1 = sine(f0,0.18)*env_exp(int(0.18*SR),0.01,0.12)
        w2 = sine(f0*0.8,0.18)*0.6*env_exp(int(0.18*SR),0.02,0.12)
        coo = np.concatenate([w1, np.zeros(int(0.08*SR)), w2])*0.15
        s = int(rng.uniform(1, dur-2)*SR)
        if s+len(coo) < n: x[s:s+len(coo)] += coo
    return fade_loop(norm(x, 0.7))

def amb_cafe():
    dur = 12.0
    murmur = onepole_lp(noise(dur), 0.05)*onepole_lp(np.abs(noise(dur)),0.001)
    murmur = onepole_hp(murmur, 0.02)*0.6
    room = sine(95,dur)*0.03
    x = murmur+room
    # cutlery clinks
    for _ in range(7):
        c=rng.uniform(0,dur-0.2); f=rng.uniform(2200,3600)
        clink=sine(f,0.06)*env_exp(int(0.06*SR),0.001,0.05)*0.12
        s=int(c*SR); x[s:s+len(clink)]+=clink
    return fade_loop(norm(x,0.6))

def amb_gallery():
    dur=10.0
    air = onepole_lp(noise(dur),0.006)*0.35
    hum = sine(60,dur)*0.04+sine(180,dur)*0.015
    return fade_loop(norm(air+hum,0.5))

def amb_crypt():
    dur=12.0
    drone = sine(48,dur)*0.25 + sine(72,dur)*0.12 + onepole_lp(noise(dur),0.004)*0.3
    x=drone
    for _ in range(6):  # water drips
        c=rng.uniform(0,dur-0.4); f=rng.uniform(900,1500)
        drip=sine(f,0.12)*env_exp(int(0.12*SR),0.001,0.11)*0.18
        s=int(c*SR); x[s:s+len(drip)]+=drip
    return fade_loop(norm(x,0.6))

# ---------------------------------------------------------------- music layers
NOTES={'A2':110,'C3':130.81,'D3':146.83,'E3':164.81,'F3':174.61,'G3':196,'A3':220,'B3':246.94,
       'C4':261.63,'D4':293.66,'E4':329.63,'F4':349.23,'G4':392,'A4':440,'Bb3':233.08,'Eb4':311.13}
def pad(freqs, dur, vol=0.2):
    x=np.zeros(int(SR*dur))
    for f in freqs:
        x+=sine(f,dur)*0.5+sine(f*2,dur)*0.12+saw(f,dur)*0.08
    e=np.ones(len(x)); a=int(0.8*SR); e[:a]=np.linspace(0,1,a); e[-a:]=np.linspace(1,0,a)
    return x*e/len(freqs)*vol

def music_explore():
    dur=18.0; x=pad([NOTES['A2'],NOTES['C3'],NOTES['E3']],dur,0.18)
    x+=pad([NOTES['F3'],NOTES['A3'],NOTES['C4']],dur,0.0)  # placeholder; sparse melody below
    mel=['E4','G4','A4','G4','E4','D4','C4','E4']; x2=np.zeros(int(SR*dur)); pos=2.0
    for i,nm in enumerate(mel):
        d=rng.choice([1.0,1.5,0.75]); f=NOTES[nm]
        note=(saw(f,d)*0.5+sine(f,d)*0.5)*env_exp(int(d*SR),0.04,d*0.7)*0.16
        s=int(pos*SR)
        if s+len(note)<len(x2): x2[s:s+len(note)]+=note
        pos+=d
        if pos>dur-2: break
    return fade_loop(norm(x+x2,0.55))

def music_tension():
    dur=16.0; x=pad([NOTES['A2'],NOTES['Bb3'],NOTES['Eb4']],dur,0.2)  # dissonant
    # pulse / heartbeat
    pulse=np.zeros(int(SR*dur)); period=0.6
    p=0.0
    while p<dur-0.3:
        thump=sine(55,0.18)*env_exp(int(0.18*SR),0.005,0.16)*0.4
        s=int(p*SR); pulse[s:s+len(thump)]+=thump; p+=period
    return fade_loop(norm(x+pulse,0.6))

def accordion():
    # a slow French waltz in 3/4 on a reedy (detuned saw) tone
    dur=15.0
    seq=[('A3',1),('C4',1),('E4',1),('D4',1.5),('C4',0.5),('B3',1),
         ('A3',1),('E3',1),('A3',1),('C4',1.5),('B3',0.5),('A3',1),
         ('G3',1),('B3',1),('D4',1),('C4',1.5),('B3',0.5),('A3',1)]
    x=np.zeros(int(SR*dur)); pos=0.0
    for nm,beats in seq:
        d=beats*0.5; f=NOTES.get(nm,220)
        reed=(saw(f,d)*0.6+saw(f*1.01,d)*0.4)  # detune = accordion shimmer
        reed*=env_exp(int(d*SR),0.05,d*0.5)*0.22
        s=int(pos*SR)
        if s+len(reed)<len(x): x[s:s+len(reed)]+=reed
        # bass on the 1
        if abs(pos%1.5)<0.01:
            b=sine(f/2,0.4)*env_exp(int(0.4*SR),0.01,0.35)*0.12
            if s+len(b)<len(x): x[s:s+len(b)]+=b
        pos+=d
        if pos>dur-1: break
    return fade_loop(norm(x,0.6))

# ---------------------------------------------------------------- one-shot SFX
def sfx_collect():
    x=np.concatenate([sine(660,0.09),sine(990,0.16)])
    return norm(x*env_exp(len(x),0.005,0.18),0.7)
def sfx_deduce():
    a=sine(523.25,0.18); b=sine(783.99,0.45)
    x=np.concatenate([a,b]); return norm(x*env_exp(len(x),0.01,0.4),0.7)
def sfx_takedown():
    thud=sine(80,0.18)*env_exp(int(0.18*SR),0.002,0.16)
    cloth=onepole_hp(noise(0.2),0.3)*env_exp(int(0.2*SR),0.001,0.18)*0.4
    n=min(len(thud),len(cloth)); return norm(thud[:n]+cloth[:n],0.8)
def sfx_spotted():
    x=np.concatenate([sine(880,0.12),sine(740,0.12),sine(560,0.2)])
    return norm(x*env_exp(len(x),0.002,0.22),0.8)
def sfx_alarm():
    dur=2.0; x=np.zeros(int(SR*dur)); p=0.0
    while p<dur-0.25:
        tone=sine(720,0.22)*env_exp(int(0.22*SR),0.01,0.2)
        s=int(p*SR); x[s:s+len(tone)]+=tone; p+=0.25
        tone2=sine(540,0.22)*env_exp(int(0.22*SR),0.01,0.2)
        s=int(p*SR); x[s:s+len(tone2)]+=tone2[:max(0,len(x)-s)]; p+=0.25
    return fade_loop(norm(x,0.6),0.1)
def sfx_pick_tick(): return norm(onepole_hp(noise(0.03),0.5)*env_exp(int(0.03*SR),0.001,0.025),0.5)
def sfx_pick_ok():
    clunk=sine(180,0.1)*env_exp(int(0.1*SR),0.002,0.09)
    ch=sine(880,0.18)*env_exp(int(0.18*SR),0.005,0.16)*0.6
    n=min(len(clunk),len(ch)); return norm(np.concatenate([clunk,ch]),0.7)
def sfx_pick_fail():
    x=onepole_lp(rng.uniform(-1,1,int(0.22*SR)),0.05)
    buzz=np.sign(sine(120,0.22))*0.4
    return norm((x*0.4+buzz)*env_exp(len(x),0.002,0.2),0.6)
def sfx_door():
    creak=onepole_lp(noise(0.4),0.02)*np.linspace(0.1,0.5,int(0.4*SR))
    thunk=sine(90,0.15)*env_exp(int(0.15*SR),0.002,0.14)
    x=np.concatenate([creak,thunk]); return norm(x*env_exp(len(x),0.01,0.2),0.7)
def sfx_heli():
    dur=3.0; carrier=sine(28,dur)
    blade=(1+0.9*np.sign(np.sin(2*np.pi*11*t(dur))))*0.5
    rumble=onepole_lp(noise(dur),0.02)*0.5
    x=(carrier*0.5+rumble)*blade + sine(220,dur)*0.05*blade
    return fade_loop(norm(x,0.6),0.15)
def sfx_camera():
    c1=onepole_hp(noise(0.02),0.5)*env_exp(int(0.02*SR),0.001,0.018)
    gap=np.zeros(int(0.04*SR))
    c2=onepole_hp(noise(0.03),0.5)*env_exp(int(0.03*SR),0.001,0.025)
    return norm(np.concatenate([c1,gap,c2]),0.7)
def sfx_ui(): return norm(sine(520,0.05)*env_exp(int(0.05*SR),0.002,0.045),0.4)
def sfx_note():
    base=onepole_hp(noise(0.3),0.4); n=len(base)
    a=int(0.05*SR); e=np.concatenate([np.linspace(0,1,a),np.linspace(1,0,n-a)])
    return norm(base*e*0.5,0.5)

JOBS={
 'amb_street':amb_street,'amb_cafe':amb_cafe,'amb_gallery':amb_gallery,'amb_crypt':amb_crypt,
 'music_explore':music_explore,'music_tension':music_tension,'accordion':accordion,
 'sfx_collect':sfx_collect,'sfx_deduce':sfx_deduce,'sfx_takedown':sfx_takedown,'sfx_spotted':sfx_spotted,
 'sfx_alarm':sfx_alarm,'sfx_pick_tick':sfx_pick_tick,'sfx_pick_ok':sfx_pick_ok,'sfx_pick_fail':sfx_pick_fail,
 'sfx_door':sfx_door,'sfx_heli':sfx_heli,'sfx_camera':sfx_camera,'sfx_ui':sfx_ui,'sfx_note':sfx_note,
}
if __name__=='__main__':
    print("synthesizing...")
    for name,fn in JOBS.items(): save(name, fn())
    print("done.")
