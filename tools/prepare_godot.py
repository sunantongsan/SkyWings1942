from pathlib import Path
import random
ROOT=Path('game/assets')
for d in ['buildings','units','maps','ui']:
    (ROOT/d).mkdir(parents=True,exist_ok=True)

BUILDINGS=[
('galactic_core','#2ecbff','#174d9a','core'),('fusion_reactor','#3ee9ff','#176f9c','reactor'),('metal_extractor','#ffb13c','#5c6773','extractor'),('oil_processor','#ff7b26','#5b443e','processor'),('crystal_mine','#bd52ff','#5f2b86','crystal'),('resource_vault','#ffc04c','#505865','vault'),('star_hangar','#51bfff','#374d68','hangar'),('research_lab','#6de8ff','#285d80','lab'),('laser_tower','#ff5252','#4d3140','tower'),('shield_generator','#51d8ff','#2d618c','shield')]

def header(w=256,h=256):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'

def building_svg(name,c1,c2,kind):
    s=[header(),'<defs>',f'<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>','<filter id="glow"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>','</defs>','<ellipse cx="128" cy="210" rx="95" ry="20" fill="#000" opacity=".30"/>','<polygon points="40,174 128,126 216,174 128,224" fill="#273543" stroke="#7895ad" stroke-width="3"/>']
    if kind=='core':
        s += [f'<polygon points="70,172 82,92 103,80 113,42 128,22 143,42 153,80 174,92 186,172 128,204" fill="url(#g)" stroke="#d9f7ff" stroke-width="3"/>','<path d="M128 28 L128 126" stroke="#77e8ff" stroke-width="8" filter="url(#glow)"/>']
    elif kind=='reactor':
        s += [f'<ellipse cx="128" cy="145" rx="66" ry="55" fill="url(#g)" stroke="#d9f7ff" stroke-width="3"/>','<ellipse cx="128" cy="117" rx="38" ry="22" fill="#84f7ff" filter="url(#glow)"/>','<rect x="68" y="151" width="18" height="48" rx="7" fill="#50606c"/><rect x="170" y="151" width="18" height="48" rx="7" fill="#50606c"/>']
    elif kind=='extractor':
        s += [f'<rect x="75" y="105" width="90" height="80" rx="12" fill="url(#g)" stroke="#e1edf5" stroke-width="3"/>','<path d="M73 105 L105 70 L125 80 L159 52" stroke="#ffc552" stroke-width="17" stroke-linecap="round"/><circle cx="70" cy="184" r="25" fill="#48525a"/><circle cx="178" cy="184" r="23" fill="#555c62"/>']
    elif kind=='processor':
        s += [f'<rect x="75" y="104" width="100" height="87" rx="12" fill="url(#g)" stroke="#ffd6b3" stroke-width="3"/>','<rect x="88" y="56" width="25" height="70" rx="8" fill="#6c4a3c"/><rect x="128" y="42" width="25" height="82" rx="8" fill="#754437"/><circle cx="126" cy="126" r="26" fill="#ff7a1b" filter="url(#glow)"/>']
    elif kind=='crystal':
        s += ['<g fill="#c654ff" stroke="#f0c8ff" stroke-width="3" filter="url(#glow)"><polygon points="128,38 153,101 128,176 103,101"/><polygon points="80,90 105,131 88,184 60,136"/><polygon points="176,84 198,132 174,185 151,135"/></g>']
    elif kind=='vault':
        s += [f'<rect x="62" y="92" width="132" height="102" rx="15" fill="url(#g)" stroke="#ffe0a0" stroke-width="3"/>','<rect x="78" y="115" width="42" height="32" rx="5" fill="#d8982d"/><rect x="136" y="115" width="42" height="32" rx="5" fill="#e4aa38"/><circle cx="128" cy="169" r="18" fill="#323d48" stroke="#ffc754" stroke-width="5"/>']
    elif kind=='hangar':
        s += [f'<path d="M55 177 L66 83 Q128 48 190 83 L202 177 Z" fill="url(#g)" stroke="#d8efff" stroke-width="3"/>','<path d="M84 164 L84 108 Q128 87 172 108 L172 164 Z" fill="#071827" stroke="#4ed4ff" stroke-width="4"/><polygon points="128,115 154,151 128,143 102,151" fill="#65d9ff"/>']
    elif kind=='lab':
        s += [f'<rect x="73" y="103" width="110" height="91" rx="14" fill="url(#g)" stroke="#d9f7ff" stroke-width="3"/>','<circle cx="128" cy="91" r="41" fill="#4fc9ff" fill-opacity=".35" stroke="#94efff" stroke-width="4" filter="url(#glow)"/><path d="M167 75 L196 49 M176 84 L207 84" stroke="#d6f7ff" stroke-width="5"/>']
    elif kind=='tower':
        s += [f'<rect x="99" y="112" width="58" height="80" rx="13" fill="url(#g)" stroke="#f4dfe3" stroke-width="3"/>','<circle cx="128" cy="103" r="34" fill="#3e4854" stroke="#ff6464" stroke-width="5"/><rect x="122" y="36" width="13" height="86" rx="6" fill="#e9eef3" transform="rotate(32 128 103)"/><circle cx="151" cy="78" r="12" fill="#ff3d3d" filter="url(#glow)"/>']
    else:
        s += [f'<g fill="url(#g)" stroke="#d9f7ff" stroke-width="3"><rect x="70" y="130" width="25" height="64" rx="8"/><rect x="161" y="130" width="25" height="64" rx="8"/><rect x="116" y="112" width="25" height="82" rx="8"/></g>','<circle cx="128" cy="117" r="62" fill="#4ccfff" fill-opacity=".20" stroke="#7ae9ff" stroke-width="4" filter="url(#glow)"/>']
    s.append('</svg>')
    return ''.join(s)

for n,a,b,k in BUILDINGS:
    (ROOT/'buildings'/f'{n}.svg').write_text(building_svg(n,a,b,k))

UNITS=[
('fighter','#45d7ff','#1365ff','fighter'),('interceptor','#8a7cff','#3c2dff','fighter'),('bomber','#ff6655','#941d2b','wide'),('heavy_fighter','#ff785e','#742033','wide'),('stealth_fighter','#47e0d1','#1a3d5a','stealth'),('gunship','#ffa43c','#225a93','gunship'),('missile_cruiser','#ef5b54','#2b334d','cruiser'),('destroyer','#63b9ff','#263f72','cruiser'),('battle_cruiser','#ff584f','#482945','cruiser'),('carrier','#97b8d9','#354251','carrier'),('battle_tank','#c8b06a','#4d5138','tank'),('siege_tank','#cfb078','#4a4c35','tank'),('artillery','#d0a26e','#56452e','artillery'),('rocket_launcher','#d3a36b','#403b31','rocket'),('mech_warrior','#48c9ff','#173b67','mech'),('sniper_unit','#78b7d9','#2a3039','soldier'),('shield_drone','#56e8ff','#145f8e','drone'),('repair_drone','#5fefff','#3a7498','drone'),('assault_soldier','#ff5959','#252d3c','soldier'),('elite_commander','#ffb24b','#1b4b80','mech')]

def unit_svg(name,c1,c2,kind):
    s=[header(),'<defs>',f'<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>','<filter id="glow"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>','</defs>','<ellipse cx="128" cy="198" rx="78" ry="18" fill="#000" opacity=".28"/>']
    if kind in ('fighter','wide','stealth','gunship','cruiser','carrier'):
        pts={'fighter':'128,38 160,96 218,126 165,146 148,208 128,176 108,208 91,146 38,126 96,96','wide':'128,46 178,92 225,126 173,142 153,190 128,169 103,190 83,142 31,126 78,92','stealth':'128,46 174,102 219,132 157,142 128,197 99,142 37,132 82,102','gunship':'128,44 172,88 205,115 181,158 154,146 145,202 111,202 102,146 75,158 51,115 84,88','cruiser':'128,32 160,72 178,108 211,127 176,145 159,205 128,182 97,205 80,145 45,127 78,108 96,72','carrier':'128,34 169,76 199,107 220,142 165,150 152,207 128,188 104,207 91,150 36,142 57,107 87,76'}[kind]
        s += [f'<polygon points="{pts}" fill="url(#g)" stroke="#d8f6ff" stroke-width="3" filter="url(#glow)"/>','<path d="M128 55 L145 130 L128 164 L111 130 Z" fill="#e8fbff" opacity=".9"/>',f'<circle cx="128" cy="119" r="13" fill="{c1}" stroke="#fff" stroke-width="3"/>','<path d="M106 174 L98 224 L118 193 M150 174 L158 224 L138 193" stroke="#59dfff" stroke-width="7" stroke-linecap="round" opacity=".85"/>']
    elif kind in ('tank','artillery','rocket'):
        s += ['<rect x="52" y="116" width="152" height="72" rx="24" fill="url(#g)" stroke="#e7dfbd" stroke-width="3"/>','<circle cx="76" cy="190" r="22" fill="#1a1d20" stroke="#8e927b" stroke-width="6"/><circle cx="180" cy="190" r="22" fill="#1a1d20" stroke="#8e927b" stroke-width="6"/>',f'<rect x="86" y="91" width="84" height="58" rx="18" fill="{c1}" stroke="#f8e9c4" stroke-width="3"/>']
        if kind=='tank':
            s += ['<rect x="122" y="58" width="16" height="82" rx="7" fill="#c7b27d" transform="rotate(20 130 99)"/>']
        elif kind=='artillery':
            s += ['<rect x="125" y="32" width="15" height="118" rx="7" fill="#d7c198" transform="rotate(12 132 91)"/>']
        else:
            s += ['<g fill="#cf7638"><rect x="93" y="53" width="18" height="72" rx="8"/><rect x="120" y="47" width="18" height="78" rx="8"/><rect x="147" y="53" width="18" height="72" rx="8"/></g>']
    elif kind=='drone':
        s += [f'<circle cx="128" cy="128" r="58" fill="url(#g)" stroke="#dfffff" stroke-width="4" filter="url(#glow)"/>','<circle cx="128" cy="128" r="27" fill="#b9f8ff"/><circle cx="128" cy="128" r="15" fill="#0a6ca8"/><path d="M69 104 L38 75 M187 104 L218 75 M69 152 L38 181 M187 152 L218 181" stroke="#8cecff" stroke-width="13" stroke-linecap="round"/>']
    else:
        s += [f'<circle cx="128" cy="63" r="28" fill="{c1}" stroke="#d9f2ff" stroke-width="3"/>',f'<path d="M91 94 Q128 75 165 94 L178 157 Q151 175 128 165 Q105 175 78 157 Z" fill="url(#g)" stroke="#d7e8f5" stroke-width="3"/>','<path d="M95 160 L75 224 M161 160 L181 224 M82 111 L42 165 M174 111 L214 165" stroke="#a9bed0" stroke-width="18" stroke-linecap="round"/>']
    s.append('</svg>')
    return ''.join(s)

for n,a,b,k in UNITS:
    (ROOT/'units'/f'{n}.svg').write_text(unit_svg(n,a,b,k))

MAPS=[('terra','#173d29','#4e8a43','#39a7d8'),('volcanis','#29171a','#7d2e1f','#ff4a16'),('cryon','#234558','#9ed5e9','#d9fbff'),('desertus','#68451f','#c88d49','#f2c77c'),('noctis','#091326','#263a60','#5b78b5'),('aquara','#0b4764','#3f9f85','#4ad9d0'),('mechanis','#1f2833','#526678','#38bdf8'),('toxicus','#2d4519','#6f9c35','#a6f05a'),('nebularis','#25133f','#723d91','#c859ff'),('asteroid_belt','#23252b','#62584f','#a98c6d'),('ruins','#39342f','#766c5d','#b39a72'),('orbit_station','#162638','#384e66','#45c8ff'),('moon_base','#34363a','#85888e','#d1d3d8'),('gas_giant','#553b32','#ad7658','#f2c285'),('wormhole','#19082e','#4e1d78','#7e5cff')]

def map_svg(name,a,b,accent,idx):
    rr=random.Random(1942+idx)
    dots=''.join(f'<circle cx="{rr.randint(20,1004)}" cy="{rr.randint(20,1004)}" r="{rr.randint(8,48)}" fill="{accent}" fill-opacity="{rr.uniform(.05,.22):.2f}"/>' for _ in range(75))
    rings='' if name not in ('mechanis','orbit_station','moon_base','wormhole') else ''.join(f'<circle cx="512" cy="512" r="{r}" fill="none" stroke="{accent}" stroke-opacity=".18" stroke-width="10"/>' for r in (110,180,270,360))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024"><defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient><filter id="n"><feTurbulence type="fractalNoise" baseFrequency=".015" numOctaves="4" seed="{idx+7}"/></filter></defs><rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" filter="url(#n)" opacity=".12"/>{dots}{rings}<path d="M0 720 Q220 650 410 740 T760 700 T1024 735 V1024 H0 Z" fill="#07111c" opacity=".18"/></svg>'

for i,(n,a,b,c) in enumerate(MAPS):
    (ROOT/'maps'/f'{n}.svg').write_text(map_svg(n,a,b,c,i))

stars=''.join(f'<circle cx="{random.Random(99+i).randint(20,1900)}" cy="{random.Random(199+i).randint(20,800)}" r="2"/>' for i in range(90))
splash=f'''<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080"><defs><radialGradient id="space"><stop offset="0" stop-color="#16365f"/><stop offset="1" stop-color="#020611"/></radialGradient><linearGradient id="ship" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#75e6ff"/><stop offset="1" stop-color="#1e4d94"/></linearGradient></defs><rect width="1920" height="1080" fill="url(#space)"/><circle cx="330" cy="820" r="430" fill="#1a5278"/><circle cx="330" cy="820" r="420" fill="#194739" opacity=".65"/><g fill="#fff" opacity=".65">{stars}</g><g transform="translate(970 310) scale(2.4)"><polygon points="128,38 160,96 218,126 165,146 148,208 128,176 108,208 91,146 38,126 96,96" fill="url(#ship)" stroke="#d8f6ff" stroke-width="3"/><circle cx="128" cy="119" r="13" fill="#45d7ff"/></g><text x="110" y="225" font-family="sans-serif" font-size="112" font-weight="900" fill="#fff">GALAXY 1942</text><text x="120" y="292" font-family="sans-serif" font-size="38" letter-spacing="15" fill="#58dfff">SPACE STRATEGY</text><text x="120" y="350" font-family="sans-serif" font-size="24" letter-spacing="8" fill="#aacbe4">BUILD • EXPAND • DEFEND • CONQUER</text></svg>'''
(ROOT/'ui'/'splash.svg').write_text(splash)
print('Generated 10 buildings, 20 units, 15 maps, splash.')
