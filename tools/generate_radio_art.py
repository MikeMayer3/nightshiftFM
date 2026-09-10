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

def enemy_finish(name, body):
    """Original vector materials and device-specific machining, with no aura/glow."""
    import re
    defs = '''<defs>
    <linearGradient id="pearl" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#fcfff5"/><stop offset=".38" stop-color="#d8e4e9"/><stop offset=".62" stop-color="#a6bac8"/><stop offset="1" stop-color="#667b91"/></linearGradient>
    <linearGradient id="body" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#6b829c"/><stop offset=".4" stop-color="#334c66"/><stop offset="1" stop-color="#102237"/></linearGradient>
    <linearGradient id="glass" x1="0" y1="0" x2=".7" y2="1"><stop stop-color="#456885"/><stop offset=".4" stop-color="#19384e"/><stop offset="1" stop-color="#081424"/></linearGradient>
    <linearGradient id="steel" x1="0" y1="0" x2="1" y2="0"><stop stop-color="#d6d1b9"/><stop offset=".35" stop-color="#7d8e9f"/><stop offset=".7" stop-color="#56647b"/><stop offset="1" stop-color="#bdc1b5"/></linearGradient>
    </defs>'''
    shadow = re.sub(r'(fill|stroke)="#[a-fA-F0-9]{6}"', r'\1="#070e19"', body)
    colors = {'pearl':['#e8ece5','#edf0ec','#cad5df','#d1dce1','#d8dce4','#becde0'],
              'body':['#344658','#2e4960','#2b304b','#273647','#253c52'],
              'glass':['#182c40','#1b3142','#213b50','#192f43','#253851','#1c2c49','#173147'],
              'steel':['#646e7c','#596d86','#476980']}
    for material, values in colors.items():
        for color in values: body = body.replace('fill="'+color+'"','fill="url(#'+material+')"')
    extra = ''
    def screw(x,y):return circle(x,y,2.2,'#111d2c','#91a6b3',.8)+line(f'M{x-1} {y}h2','#d4e2de',.8)
    if name.startswith('swarmer'):
        extra = line('M34 29v65q0 15 12 16M92 30v69','#fbfff4',1.7)
        extra += '<path d="M41 26h40L41 49Z" fill="#c4edee" opacity=".12"/>'
        extra += line('M51 78l-4 4 4 4M77 78l4 4-4 4','#6c8194',1.6) + rect(56,108,16,3,'#152434',1,width=0)
        extra += screw(34,18)+screw(94,110)
    elif name.startswith('diver'):
        extra = line('M18 36q0-17 14-19M108 36q0-17-14-19','#ffffff',3)
        extra += ''.join(line(f'M25 {y}h8M96 {y}h8','#718a9c',1.4) for y in [28,33,38])
        extra += rect(31,100,12,6,'#879da9',2,width=0)+rect(85,100,12,6,'#879da9',2,width=0)
        extra += line('M34 57v32M94 57v32','#ffffff',1.6)
    elif name.startswith('carrier') or name=='core':
        extra = ''.join(line(f'M28 {y}h72','#0b1e2d',1.5) for y in range(62,99,7))
        extra += line('M21 50v40q0 18 15 20M106 54v39','#a4c8d4',2)
        extra += rect(51,107,26,5,'#0c1829',2,width=0)
        extra += ''.join(rect(53+n*6,108,3,2,'#f59ab5',0,width=0) for n in range(4))
    elif name=='plated':
        extra = line('M33 12h43M27 34v47M99 31v48','#c8d5d5',2)
        extra += ''.join(screw(x,y) for x in [23,105] for y in [23,97])
        extra += '<path d="M36 26h46L36 53Z" fill="#d0f3e5" opacity=".13"/>'
        extra += line('M85 80v22M90 80v22','#142c38',2)
    elif name=='caster':
        extra = line('M19 49h78M17 52v30','#f3fff6',2)
        extra += ''.join(rect(20+n*8,61,4,18,'#153149',1,width=0) for n in range(3))
        extra += ''.join(rect(85+n*7,65,3,13,'#153149',1,width=0) for n in range(3))
        extra += screw(19,94)+screw(108,94)+line('M21 17l5 21M108 17l-5 21','#e3fff1',2)
    elif name in ['jammer','silence']:
        extra = line('M26 47q0-30 24-31M77 16q26 4 26 31','#eef6e7',3)
        extra += ''.join(line(f'M16 {y}h12M99 {y}h12','#718da5',2) for y in range(67,102,7))
        extra += rect(19,52,9,4,'#f193b9',1,width=0)+rect(100,52,9,4,'#f193b9',1,width=0)
        extra += line('M14 59v40M115 59v40','#c8dcd8',1.5)
    elif name=='mimic':
        extra = ''.join(rect(56,y,16,4,'#162e41',2,width=0) for y in [4,12,112,120])
        extra += line('M30 50q0-21 20-21M32 82q0 15 15 15','#f9fff0',2)
        extra += '<path d="M36 38h43L36 66Z" fill="#a0ebdd" opacity=".15"/>'
        extra += rect(107,72,5,15,'#849bb3',2,width=0)
    elif name=='mortar':
        extra = line('M39 33V19q0-5 5-5h32M15 86h92','#f8fff0',2)
        extra += '<path d="M45 20h36L45 48Z" fill="#add5ea" opacity=".14"/>'
        extra += ''.join(screw(x,107) for x in [17,111]) + rect(58,78,14,5,'#07182a',2,width=0)
    elif name=='caller':
        extra = line('M24 35V22q0-12 12-12M25 103q0 14 10 15','#edfff6',2)
        extra += '<path d="M33 22h59L33 71Z" fill="#c6def6" opacity=".12"/>'
        extra += rect(99,44,4,24,'#e3b38d',1,width=0) + rect(54,116,20,3,'#1c344c',1,width=0)
        extra += line('M79 88v13M84 88v13','#f8b490',2)
    elif name=='aerial':
        extra = ''.join(line(f'M{42+n*8} 44v46','#173247',1.8) for n in range(6))
        extra += line('M30 57q4-19 20-24','#d6fbef',3) + rect(55,103,18,5,'#77dbcf',2,width=0)
    return defs + '<g transform="translate(3 4)" opacity=".8">'+shadow+'</g>'+body+extra

def save(name, body):
    if name.startswith(('swarmer_', 'diver_', 'carrier_')) or name in ['plated','caster','jammer','mimic','mortar','caller','core','silence','aerial']:
        body = enemy_finish(name, body)
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

# Expanded modern-device roster: shape, hardware and marks distinguish every role.
save('plated', rect(22,8,84,112,'#646e7c',15,'#131d2b',5) + rect(32,22,64,51,'#1b3142',6) +
     line('M44 43h40M44 54h25','#8edbd4',4) + dial(64,94,14,'#e4b974') +
     ''.join(rect(x,y,12,18,'#d3ac74',2) for x in [17,99] for y in [18,85]))
save('caster', rect(12,44,104,60,'#cad5df',12) + line('M25 46L17 15M103 46l8-31','#91d8ee',7) +
     circle(64,72,18,'#213b50','#76c5e5',3) + line('M52 72h24M64 60v24','#a9edeb',4) +
     ''.join(circle(x,94,3,'#64c6c2',width=0) for x in [28,39,50,78,89,100]) + line('M43 33Q64 12 85 33','#88cfe0',3))
save('jammer', line('M19 67V53Q19 9 64 9t45 44v14','#b7accf',12) +
     rect(9,53,27,56,'#2b304b',12,'#bfaccf',4) + rect(92,53,27,56,'#2b304b',12,'#bfaccf',4) +
     line('M44 66l12-12v36l-12-12h-6V66M74 61l18 26M92 61L74 87','#e993b4',4))
save('mimic', rect(47,0,34,128,'#3e485b',10) + rect(24,24,80,80,'#d1dce1',22) +
     rect(31,31,66,66,'#192f43',17) + circle(106,56,5,'#efab75') +
     line('M44 60h10l7-15 10 31 8-16h7','#80e1c7',4))
save('mortar', rect(9,80,110,35,'#596d86',12) + rect(35,9,58,80,'#d8dce4',8) +
     rect(41,16,46,63,'#253851',5) + line('M53 32l23 16-23 16Z','#f0ad86',4) +
     circle(28,97,6,'#f0ad86') + grille(45,92,60,15,'#a9b6c6'))
save('caller', rect(20,4,88,120,'#becde0',18,'#394e70',4) + rect(28,17,72,94,'#1c2c49',12) +
     ''.join(circle(41,y,4,'#f6b690',width=0) + line(f'M52 {y}h33','#a8bdd8',4) for y in [37,55,73]) +
     line('M56 86l15 9-15 9Z','#ee88b0',3) + rect(48,7,32,5,'#172b46',3))
save('core', rect(20,21,88,102,'#2e4960',30,'#aeced7',4) +
     ''.join(line(f'M{x} 64v39','#739cae',2) for x in range(33,103,9)) +
     '<ellipse cx="64" cy="38" rx="36" ry="19" fill="#173147" stroke="#8ce3db" stroke-width="5"/>' +
     line('M42 39q-6-12 6-13q7-18 19-5q18-3 19 10q8 13-11 14H50','#d3efea',3))
save('silence', line('M15 68V53Q15 5 64 5t49 48v15','#96a8c0',14) +
     rect(4,53,32,68,'#273647',12,'#d2dddf',4) + rect(92,53,32,68,'#273647',12,'#d2dddf',4) +
     line('M15 64v42M113 64v42','#eda5ad',4) + line('M43 66l12-15v42L43 79M69 56l17 34M86 56L69 90','#eda5ad',5))
save('aerial', circle(64,67,43,'#253c52','#9ed8dc',5) + circle(64,67,28,'#476980','#b7d6de',3) +
     circle(64,67,12,'#c4e4e5') + line('M40 14Q64 0 88 14M46 25q18-11 36 0','#d7f2e9',4))

# 16-bar / 32-second original instrumental loop at 120 BPM. Deterministic synthesis;
# no commercial samples. Rounded organ chords, electric-piano melody, bass and brushes.
def station_loop():
    rate=22050; duration=32; samples=[]
    roots=[48,53,57,55]; melody=[72,76,79,76,74,72,67,69,72,74,76,79,81,79,76,74]
    freq=lambda note:440*2**((note-69)/12)
    for i in range(rate*duration):
        t=i/rate; bar=int(t/2); root=roots[(bar//2)%4]; beat=t%0.5; step=int(t/.5)
        chord=sum(math.sin(math.tau*freq(root+n)*t) for n in [0,4,7,11])*.023
        bass=math.sin(math.tau*freq(root-12+(7 if step%4==2 else 0))*beat)*math.exp(-beat*9)*.09
        age=t%0.5; note=melody[step%16] + (0 if (bar//8)%2==0 else -12)
        lead=(math.sin(math.tau*freq(note)*age)+.2*math.sin(math.tau*freq(note)*2*age))*math.exp(-age*7)*.065
        kick=math.sin(math.tau*(55*beat+2*(1-math.exp(-beat*35))))*math.exp(-beat*22)*(.05 if step%2==0 else .018)
        hat=math.sin(i*1.791)*math.sin(i*.371)*math.exp(-(t%.25)*100)*.018
        envelope=min(1,t/.015,(duration-t)/.015)
        samples.append(struct.pack('<h',int(32767*envelope*(chord+bass+lead+kick+hat))))
    with wave.open(str(AUDIO/'station.wav'),'wb') as f:
        f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(samples))
station_loop()
sound('warning',[220,440],.32,.12)
sound('shield',[261.63,523.25],.25,.12)
print('Expanded roster: nine device silhouettes; original 32-second station loop and two counterplay cues.')
