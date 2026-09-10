#!/usr/bin/env python3
"""Twelve original module illustrations matching the native radio SVG equipment set."""
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/art/modules'
OUT.mkdir(parents=True, exist_ok=True)
def path(d, c='#edce8c', w=4):
    return f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round" stroke-linejoin="round"/>'
def rect(x,y,w,h,c='url(#metal)',r=5):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{c}" stroke="#121e29" stroke-width="3"/>'
def circle(x,y,r,c='#e5b16c'):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}" stroke="#182631" stroke-width="3"/>'
def base():
    return rect(22,101,116,24,'url(#wood)') + path('M29 107h101','#cf9669',2) + circle(32,116,2) + circle(128,116,2)
def tube(x,y):
    return rect(x,y,30,55,'url(#glass)',12)+path(f'M{x+8} {y+9}v34m7-34v34','#d99b59',3)+path(f'M{x+4} {y+6}v27','#e7f8ee',2)+rect(x-2,y+48,34,12,'#b28a5b',2)
art = {}
art['hot_tubes'] = base()+tube(38,43)+tube(91,31)+path('M51 28q-8-9 0-17M107 18q-8-8 0-15','#ef9462',3)
art['long_mast'] = base()+path('M49 100L80 17l31 83M62 65h36M70 43h20M59 77l39 16M68 54l25 17M80 17V5','#dcc39a',5)+path('M53 15q-15 14 0 29M107 15q15 14 0 29','#86dbc9',3)
art['heavy_battery'] = base()+rect(37,40,88,61)+rect(48,30,19,10,'#e6bd77',2)+rect(97,30,17,10,'#e6bd77',2)+rect(45,48,72,40,'#233936')+path('M80 50l-13 24h16l-6 19 22-29H82l9-14','#ffd57a',5)
art['fast_fuse'] = base()+path('M33 98l20-25M111 58l21-22','#c49360',8)+'<g transform="rotate(35 80 68)">'+rect(65,32,30,74,'url(#glass)',7)+rect(63,28,34,18)+rect(63,92,34,18)+path('M80 46l-7 14 14 15-7 17','#ffd986',3)+'</g>'+path('M31 49h18M25 61h17M112 91h16','#80dece',3)
art['signal_booster'] = base()+rect(31,49,98,52,'url(#wood)')+rect(39,56,51,28,'#d7c086')+path('M46 76l17-12 18 12M63 76l10-14','#653d37',2)+circle(110,70,12)+path('M110 70l6-6M55 45V26m49 19V17','#e7c78e',3)+path('M120 16q15 11 0 22M130 9q22 18 0 37','#7ad9c5',3)
art['quiet_room'] = base()+rect(29,22,102,79,'url(#wood)')+rect(40,30,80,65,'#273942')+''.join(path(f'M{x} 36v50','#647579',5) for x in [48,60,72,84,96,108])+circle(80,60,17,'#8ccfc0')+path('M68 60q6-13 12 0t12 0','#173831',3)
art['wideband_module'] = base()+rect(34,30,92,71)+rect(42,39,76,41,'#172b35')+path('M48 60q8-29 16 0t16 0 16 0 16 0','#80dac8',3)+path('M43 90h72','#e5c485',3)+circle(50,90,5)+circle(109,90,5)
art['narrowband_module'] = base()+rect(34,30,92,71)+rect(42,39,76,41,'#172b35')+path('M48 65h20l9-20 8 32 8-12h19','#ebbe7c',3)+path('M71 38v43M94 38v43','#78d7c9',2)+circle(80,91,8)
art['counterweight'] = base()+path('M80 26v73M39 42h82M46 42l-16 42h32ZM114 42L98 84h32Z','#c3aa7e',4)+rect(25,83,41,12)+rect(95,83,40,12)+circle(80,40,9)+path('M77 18h6','#81dac6',4)
art['thin_wire'] = base()+circle(80,63,42,'url(#wood)')+circle(80,63,29,'#202e36')+''.join(path(f'M{48+n*8} 39v49','#d9ab67',4) for n in range(9))+circle(80,63,10)+path('M115 81q24 0 14 19t8 13','#89decd',3)
art['night_ledger'] = base()+rect(37,25,85,77,'#d1bc8e',3)+rect(32,20,82,77,'url(#wood)',4)+path('M45 23v70','#d9ad6d',4)+rect(57,32,44,30,'#1f333b',2)+path('M66 40h23M66 49h17M64 76h32','#e5c58c',2)+path('M105 23v18l-6-5-6 5V23','#83d8c6',5)
art['glass_tower'] = base()+'<path d="M80 18L43 99h74Z" fill="url(#glass)" stroke="#a8eadc" stroke-width="3"/>'+path('M80 18v81M63 57h34M53 80h54M63 57l33 23M80 18l17 39-44 23','#c7e5d9',2)+path('M106 22v17M98 30h17','#f0c77e',3)
defs='''<defs><linearGradient id="metal" x2=".3" y2="1"><stop stop-color="#bbbea5"/><stop offset=".4" stop-color="#798c87"/><stop offset="1" stop-color="#435b63"/></linearGradient><linearGradient id="wood" x2="0" y2="1"><stop stop-color="#b37b54"/><stop offset="1" stop-color="#654334"/></linearGradient><linearGradient id="glass" x2="1" y2="1"><stop stop-color="#c5e9d6" stop-opacity=".8"/><stop offset=".35" stop-color="#5f9f97" stop-opacity=".3"/><stop offset="1" stop-color="#bfe3cf" stop-opacity=".65"/></linearGradient></defs>'''
for name, body in art.items():
    (OUT / (name+'.svg')).write_text('<svg xmlns="http://www.w3.org/2000/svg" width="160" height="144" viewBox="0 0 160 144">'+defs+'<ellipse cx="80" cy="129" rx="64" ry="7" fill="#09121a" opacity=".5"/>'+body+'</svg>\n')
print(f'Generated {len(art)} original module graphics')
