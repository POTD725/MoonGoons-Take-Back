from pathlib import Path

OUT = Path('assets/generated/cinematics')
OUT.mkdir(parents=True, exist_ok=True)
W, H = 1280, 720


def stars():
    items=[]
    for i in range(150):
        x=(i*109+31)%W
        y=(i*67+19)%470
        r=0.7+(i%3)*0.42
        op=0.24+(i%5)*0.11
        items.append(f'<circle cx="{x}" cy="{y}" r="{r:.2f}" fill="#d8f7ff" opacity="{op:.2f}"/>')
    return ''.join(items)


def defs():
    return '''<defs>
<linearGradient id="space" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#02060d"/><stop offset=".55" stop-color="#071522"/><stop offset="1" stop-color="#02050a"/></linearGradient>
<linearGradient id="metal" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#60798a"/><stop offset=".45" stop-color="#2b4353"/><stop offset="1" stop-color="#101d28"/></linearGradient>
<linearGradient id="deck" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#25465d"/><stop offset="1" stop-color="#101f2c"/></linearGradient>
<radialGradient id="core"><stop stop-color="#d8ffff"/><stop offset=".25" stop-color="#55efff"/><stop offset=".62" stop-color="#0878a6"/><stop offset="1" stop-color="#031522"/></radialGradient>
<filter id="glow"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>
<filter id="shadow" x="-30%" y="-30%" width="160%" height="180%"><feDropShadow dx="0" dy="12" stdDeviation="11" flood-color="#000" flood-opacity=".72"/></filter>
<pattern id="grid" width="42" height="42" patternUnits="userSpaceOnUse"><path d="M42 0H0V42" fill="none" stroke="#67dfff" stroke-opacity=".08"/></pattern>
</defs>'''


def shell(body, accent='#5ee8ff'):
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="{W}" height="{H}" viewBox="0 0 {W} {H}">{defs()}
<rect width="{W}" height="{H}" fill="url(#space)"/>{stars()}
<rect x="18" y="18" width="1244" height="684" rx="26" fill="none" stroke="{accent}" stroke-opacity=".28" stroke-width="3"/>
{body}</svg>'''


def station(cx=640, cy=330, scale=1.0, alarm=False):
    accent='#ff4f67' if alarm else '#58eaff'
    b=[]
    b.append(f'<g transform="translate({cx} {cy}) scale({scale})" filter="url(#shadow)">')
    b.append(f'<path d="M-420 20L0-225 420 20 0 260z" fill="#101a24" stroke="{accent}" stroke-opacity=".55" stroke-width="4"/>')
    b.append('<path d="M-392 18L0-205 392 18 0 239z" fill="url(#grid)" opacity=".95"/>')
    rooms=[(-250,-55,120,75,'#56ffb2'),(250,-55,120,75,'#ffb15e'),(-290,80,110,68,'#d36aff'),(290,80,110,68,'#5eefff'),(-190,175,104,62,'#a9ceff'),(0,194,104,62,'#ffc96b'),(190,175,104,62,'#5aafff')]
    for x,y,w,h,c in rooms:
        b.append(f'<g transform="translate({x} {y})"><polygon points="0,-{h} {w},-{h/2:.1f} 0,0 -{w},-{h/2:.1f}" fill="url(#metal)" stroke="{c}" stroke-width="3"/><polygon points="-{w},-{h/2:.1f} 0,0 0,{h} -{w},{h/2:.1f}" fill="#132735" stroke="{c}" stroke-opacity=".6"/><polygon points="{w},-{h/2:.1f} 0,0 0,{h} {w},{h/2:.1f}" fill="#0b1923" stroke="{c}" stroke-opacity=".6"/><rect x="-{w*.45:.1f}" y="-{h*.2:.1f}" width="{w*.9:.1f}" height="8" rx="4" fill="{c}" opacity=".75" filter="url(#glow)"/></g>')
    b.append(f'<g><polygon points="0,-160 150,-75 0,20 -150,-75" fill="url(#metal)" stroke="{accent}" stroke-width="4"/><polygon points="-150,-75 0,20 0,145 -150,52" fill="#172d3b" stroke="{accent}" stroke-opacity=".6"/><polygon points="150,-75 0,20 0,145 150,52" fill="#0a1923" stroke="{accent}" stroke-opacity=".6"/><ellipse cx="0" cy="-50" rx="64" ry="36" fill="#05273c" stroke="{accent}" stroke-width="4"/><ellipse cx="0" cy="-50" rx="37" ry="21" fill="url(#core)" filter="url(#glow)"/></g>')
    for x1,y1,x2,y2 in [(-130,-62,-205,-45),(130,-62,205,-45),(-110,30,-225,78),(110,30,225,78),(-55,85,-130,150),(0,105,0,172),(55,85,130,150)]:
        b.append(f'<path d="M{x1} {y1}L{x2} {y2}" stroke="#29485b" stroke-width="24" stroke-linecap="round"/><path d="M{x1} {y1}L{x2} {y2}" stroke="{accent}" stroke-opacity=".55" stroke-width="4" stroke-linecap="round" filter="url(#glow)"/>')
    b.append('</g>')
    return ''.join(b)


def ship(x,y,s=1.0,flip=False,enemy=False):
    accent='#ff536f' if enemy else '#59eaff'
    transform=f'translate({x} {y}) scale({-s if flip else s} {s})'
    return f'''<g transform="{transform}" filter="url(#shadow)"><path d="M-115 8L-38-38 55-27 118 3 56 30-38 36z" fill="url(#metal)" stroke="{accent}" stroke-width="3"/><path d="M-45 2L-12-22 46-16 70 0 24 10z" fill="#071c2b"/><path d="M-12-22l16-24 42 10 3 19" fill="#37576d" stroke="{accent}"/><rect x="72" y="-2" width="38" height="8" rx="4" fill="{accent}" filter="url(#glow)"/><path d="M-90 12l-54 8M-88 22l-70 18" stroke="{accent}" stroke-opacity=".5" stroke-width="5"/></g>'''


def officers(y=530, count=12, color='#76eaff'):
    p=[]
    for i in range(count):
        x=180+i*78
        p.append(f'<g transform="translate({x} {y})"><circle cy="-26" r="9" fill="#cdeeff"/><path d="M0-16v34m-14 30L0 18l14 30M-18-2L0 7l18-9" stroke="{color}" stroke-width="7" stroke-linecap="round"/><rect x="-12" y="-11" width="24" height="20" rx="5" fill="#20394a" stroke="{color}"/></g>')
    return ''.join(p)

frames={}
frames['crater_market_blackout.svg']=shell(f'''
<circle cx="1040" cy="105" r="112" fill="#17354e" opacity=".72"/><path d="M0 410L260 250 540 335 815 235 1280 410V720H0z" fill="#101821"/>
<g opacity=".9"><path d="M75 475L280 330l205 145-205 118z" fill="#172935" stroke="#546e7c"/><path d="M450 485L680 325l220 155-220 125z" fill="#172935" stroke="#546e7c"/><path d="M835 470L1040 330l190 145-190 110z" fill="#172935" stroke="#546e7c"/></g>
<g filter="url(#glow)"><path d="M40 78H1240" stroke="#ff435e" stroke-opacity=".42" stroke-width="8"/><circle cx="190" cy="112" r="12" fill="#ff435e"/><circle cx="640" cy="112" r="12" fill="#ff435e"/><circle cx="1090" cy="112" r="12" fill="#ff435e"/></g>
{officers(565,11,'#ff5c72')}
<g opacity=".82"><path d="M930 430l70-78 70 78-70 80z" fill="#07090d" stroke="#ff526e"/><path d="M1080 442l55-65 55 65-55 67z" fill="#07090d" stroke="#ff526e"/></g>
<path d="M0 0H1280V720H0z" fill="#7a0015" opacity=".12"/>
''','#ff536e')
frames['ghost_key_heist.svg']=shell(f'''
<path d="M120 560L120 170 640 55 1160 170V560L640 675z" fill="#08131e" stroke="#5de9ff" stroke-opacity=".48" stroke-width="4"/>
<path d="M150 535L150 192 640 85 1130 192V535L640 642z" fill="url(#grid)"/>
<g transform="translate(640 330)" filter="url(#glow)"><polygon points="0,-120 86,-44 48,80 -48,80 -86,-44" fill="#052642" stroke="#6ef1ff" stroke-width="5"/><circle r="44" fill="url(#core)"/><path d="M-14 8h28v48h-28zM-30-12h60v24h-60z" fill="#bdfcff"/></g>
<g transform="translate(335 445)"><circle cy="-72" r="28" fill="#152331" stroke="#ff64b2"/><path d="M0-44v105m-50 80L0 61l50 80M-70-12L0 18l70-30" stroke="#ff64b2" stroke-width="22" stroke-linecap="round"/><rect x="-44" y="-30" width="88" height="75" rx="16" fill="#1b2635" stroke="#ff64b2"/></g>
<g transform="translate(950 445)"><circle cy="-72" r="28" fill="#152331" stroke="#6beaff"/><path d="M0-44v105m-50 80L0 61l50 80M-70-12L0 18l70-30" stroke="#6beaff" stroke-width="22" stroke-linecap="round"/><rect x="-44" y="-30" width="88" height="75" rx="16" fill="#1b2635" stroke="#6beaff"/></g>
<path d="M380 430Q640 280 900 430" fill="none" stroke="#62eaff" stroke-width="5" stroke-dasharray="12 12" filter="url(#glow)"/>
''')
frames['station_reactivation.svg']=shell(f'''
{station(640,330,1.0,False)}
<g filter="url(#glow)"><circle cx="640" cy="280" r="110" fill="none" stroke="#5ceeff" stroke-width="5" opacity=".5"/><circle cx="640" cy="280" r="155" fill="none" stroke="#5ceeff" stroke-width="3" opacity=".28"/></g>
{officers(620,12,'#65eaff')}
<path d="M130 650H1150" stroke="#6fefff" stroke-opacity=".35" stroke-width="3"/>
''')
frames['patrol_launch.svg']=shell(f'''
<path d="M0 500L270 300H1010L1280 500V720H0z" fill="#111c27" stroke="#426579" stroke-width="4"/>
<path d="M90 510L330 340H950L1190 510" fill="none" stroke="#65eaff" stroke-opacity=".55" stroke-width="6"/>
<path d="M180 610H1100" stroke="#65eaff" stroke-width="8" stroke-dasharray="36 24" opacity=".45"/>
{ship(620,380,1.45,False,False)}
{ship(305,265,.65,False,False)}{ship(965,250,.62,True,False)}
<path d="M500 400L180 520M740 400L1100 520" stroke="#53eaff" stroke-opacity=".15" stroke-width="55"/>
{officers(640,9,'#ffbf69')}
''')
frames['syndicate_assault.svg']=shell(f'''
{station(600,390,.78,True)}
{ship(210,175,.82,False,True)}{ship(1020,155,.9,True,True)}{ship(1040,390,.65,True,True)}
{ship(250,500,.62,False,False)}
<path d="M260 180L470 315M1010 165L780 310M1010 390L780 410" stroke="#ff536e" stroke-width="8" filter="url(#glow)"/>
<path d="M315 500L470 430" stroke="#5ceeff" stroke-width="9" filter="url(#glow)"/>
<circle cx="760" cy="335" r="46" fill="#ffb145" opacity=".58" filter="url(#glow)"/><circle cx="760" cy="335" r="20" fill="#fff1b8"/>
<path d="M0 0H1280V720H0z" fill="#7a0015" opacity=".08"/>
''','#ff536e')
frames['victory_reclaim.svg']=shell(f'''
<circle cx="1000" cy="115" r="140" fill="#254e73" opacity=".75"/><circle cx="965" cy="86" r="116" fill="#3a77a8" opacity=".38"/>
{station(640,355,.92,False)}
{ship(230,185,.62,False,False)}{ship(1025,190,.62,True,False)}{ship(940,505,.5,True,False)}
<path d="M150 640Q640 500 1130 640" fill="none" stroke="#ffc76b" stroke-opacity=".42" stroke-width="16" filter="url(#glow)"/>
{officers(625,12,'#72eaff')}
<g filter="url(#glow)"><path d="M640 82l18 38 42 6-31 29 8 42-37-20-37 20 8-42-31-29 42-6z" fill="#ffd66a"/></g>
''','#ffd66a')

for name, svg in frames.items():
    (OUT/name).write_text(svg, encoding='utf-8')
print(f'Generated {len(frames)} cinematic frames in {OUT}')
