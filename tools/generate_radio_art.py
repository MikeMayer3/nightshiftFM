#!/usr/bin/env python3
"""Original M10 vector radio machines; deterministic, no external assets."""
from pathlib import Path
import math
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/art/radio'
OUT.mkdir(parents=True, exist_ok=True)

def rect(x, y, w, h, fill, radius=4, stroke='#111b27', width=3):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{radius}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

def line(path, color='#ead9ac', width=4):
    return f'<path d="{path}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'

def circle(x, y, r, fill, stroke='#111b27', width=3):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

def dial(x, y, r, tint):
    return circle(x,y,r,'#111b27',tint,3) + line(f'M{x} {y}l{r*.5} {-r*.6}',tint,3)

def grille(x, y, w, h, tint='#9a7958'):
    return rect(x,y,w,h,'#24272a',3) + ''.join(line(f'M{x+5} {k}h{w-10}',tint,2) for k in range(y+6,y+h-2,6))

def meter(x,y,w=40,tint='#ffe5a4'):
    return rect(x,y,w,13,'#18252b',2) + line(f'M{x+5} {y+7}h{w-10}',tint,2) + line(f'M{x+w*.6} {y+3}v7','#f79877',2)

def cabinet(color='#9a6145',x=14,y=48,w=100,h=63):
    return rect(x,y+6,w,h,'#080f17',8) + rect(x,y,w,h,color,8) + line(f'M{x+7} {y+5}h{w-14}', '#ffffff', 1.5)

def save(name, body):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128"><g stroke-linecap="round" stroke-linejoin="round">{body}</g></svg>\n'
    (OUT / (name+'.svg')).write_text(svg)

save('arc', cabinet('#514862',18,91,92,23) + line('M64 95V71','#cbb7f6',7) +
     rect(40,11,48,68,'#b9a6ba',22) + rect(47,19,34,46,'#282635',15) +
     ''.join(line(f'M49 {y}h30','#d8c7d6',3) for y in range(25,64,8)) +
     line('M29 47v17q0 25 35 25t35-25V47','#b695c2',5) + dial(99,101,7,'#cbb7f6'))
save('bass', cabinet('#985f42',12,25,104,88) + circle(64,69,35,'#352724','#d5a675',4) +
     circle(64,69,26,'#604332','#241e21',3) + circle(64,69,13,'#e9b782') +
     line('M23 34v17M105 34v17M24 92v11M104 92v11','#f6cea0',3))
save('net', cabinet('#385b6c',8,31,112,82) + meter(18,40,42,'#94e4ee') + meter(70,40,39,'#94e4ee') +
     ''.join(line(f'M{x} 63v38','#111e2b',6) + rect(x-5,68+(x%3)*8,10,9,'#b1e5df',2) + circle(x,23,5,'#7ad8ee') for x in [24,44,64,84,104]))
save('echo', cabinet('#614453',10,25,108,88) +
     ''.join(circle(x,53,24,'#bca9a7','#201c2d',4) + circle(x,53,9,'#342b36') +
             ''.join(circle(x+15*math.cos(a),53+15*math.sin(a),4,'#42343d',width=0) for a in [0,2.094,4.189]) for x in [37,91]) +
     line('M38 78l12 10h29l13-10','#f4b8d9',3) + meter(23,94,42,'#f4b8d9') +
     circle(91,99,5,'#f4b8d9') + circle(106,99,4,'#d96865'))
save('needle', cabinet('#75634b',10,30,108,82) + circle(57,70,32,'#1b2830','#d9c091',3) +
     circle(57,70,23,'#273944','#53616a',2) + circle(57,70,10,'#f3d57b') +
     line('M103 43v28L81 90','#ede1b7',6) + rect(75,86,14,10,'#f3d57b',2) + circle(103,43,7,'#f3d57b'))
save('reverb', cabinet('#365752',8,33,112,79) + rect(18,44,92,38,'#162b2b',4) +
     line('M23 64'+''.join(f'l5 {(-12 if i%2==0 else 12)}' for i in range(16)), '#b0dbc2',3) +
     meter(20,92,51,'#8bddb0') + dial(96,97,10,'#8bddb0'))
for name in ['pulse','sweep','burst']:
    body = cabinet('#384b46',23,91,82,25) + line('M39 93L60 12h8l21 81M48 59h32M43 79h42M57 31h14M48 59l37 20M80 59L43 79', '#b4d2b9',4)
    body += circle(64,13,6,'#f0cd85') + line('M37 20Q23 35 37 47M91 20Q105 35 91 47','#9bd9cb',4)
    if name == 'sweep': body += line('M23 9Q0 33 23 57M105 9Q128 33 105 57','#9bd9cb',3)
    if name == 'burst': body += circle(48,48,6,'#efbc79') + circle(80,48,6,'#efbc79')
    save(name, body)

# Modern competitors: pocket players, wireless earbuds, and smart-speaker carriers.
# Their silhouettes retain the three existing movement roles without new mechanics.
for era, trim in [(1,'#e5e9df'),(2,'#91d8ee'),(3,'#d5a8fa')]:
    save(f'swarmer_{era}', rect(29,12,70,104,'#e8ece5',12,'#233545',4) +
         rect(37,22,54,43,'#182c40',5) + line('M43 53v-8h8v-12h8v21h8v-14h8v10h10',trim,3) +
         circle(64,87,18,'#f5f6f0','#9baeb4',2) + circle(64,87,7,'#344c62') +
         line('M45 105h38','#ec7781',3))
    save(f'diver_{era}', rect(29,44,16,68, '#edf0ec',8,'#3d5066',3) +
         rect(83,44,16,68, '#edf0ec',8,'#3d5066',3) +
         '<ellipse cx="36" cy="37" rx="24" ry="28" fill="#edf0ec" stroke="#3d5066" stroke-width="3"/>' +
         '<ellipse cx="92" cy="37" rx="24" ry="28" fill="#edf0ec" stroke="#3d5066" stroke-width="3"/>' +
         rect(22,21,14,27,'#25374a',7) + rect(92,21,14,27,'#25374a',7) +
         line('M39 76v22M89 76v22',trim,4) + line('M54 71l10 13 10-13','#eb788e',4))
    save(f'carrier_{era}', rect(15,14,98,103,'#344658',25,'#152332',4) +
         '<ellipse cx="64" cy="31" rx="43" ry="17" fill="#152635" stroke="'+trim+'" stroke-width="4"/>' +
         ''.join(line(f'M{x} 54v43','#667c8f',2) for x in range(27,108,9)) +
         line('M40 30h48M64 22v16',trim,3) + rect(41,98,46,9,'#ee7796',4))

# Short original synthesized broadcast cues and a gentle repeating station bed.
AUDIO = ROOT / 'assets/audio/radio'
AUDIO.mkdir(parents=True, exist_ok=True)
def sound(name, notes, duration, gain, music=False):
    rate = 22050
    with wave.open(str(AUDIO / (name+'.wav')), 'wb') as stream:
        stream.setnchannels(1); stream.setsampwidth(2); stream.setframerate(rate)
        samples=[]
        for i in range(int(rate*duration)):
            t=i/rate
            phase=t/duration
            env=min(1,t/.012)*min(1,(duration-t)/.05)
            if music:
                value=sum(math.sin(math.tau*f*t) for f in notes)/len(notes)
                env *= .65 + .35*math.sin(math.pi*phase)**2
            else:
                value=math.sin(math.tau*(notes[0]*t + (notes[-1]-notes[0])*t*t/(2*duration)))
                env *= (1-phase)**2
            samples.append(struct.pack('<h',int(32767*gain*env*value)))
        stream.writeframes(b''.join(samples))
sound('transmit',[660,330],.10,.16)
sound('hit',[110,65],.20,.22)
sound('tune',[392,784],.35,.16)
sound('station',[130.8128,196,261.6256],8,.08,True)
print('Generated 18 radio SVGs and four original audio cues.')
