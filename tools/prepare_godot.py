from pathlib import Path
import math, random
ROOT=Path('game/assets')
UNITS=ROOT/'units'; MAPS=ROOT/'maps'
UNITS.mkdir(parents=True,exist_ok=True); MAPS.mkdir(parents=True,exist_ok=True)

unit_specs=[
('fighter','#45d7ff','#1365ff','fighter'),('interceptor','#8a7cff','#3c2dff','fighter'),('bomber','#ff6655','#941d2b','wide'),('heavy_fighter','#ff785e','#742033','wide'),
('stealth_fighter','#47e0d1','#1a3d5a','stealth'),('gunship','#ffa43c','#225a93','gunship'),('missile_cruiser','#ef5b54','#2b334d','cruiser'),('destroyer','#63b9ff','#263f72','cruiser'),
('battle_cruiser','#ff584f','#482945','cruiser'),('carrier','#97b8d9','#354251','carrier'),('battle_tank','#c8b06a','#4d5138','tank'),('siege_tank','#cfb078','#4a4c35','tank'),
('artillery','#d0a26e','#56452e','artillery'),('rocket_launcher','#d3a36b','#403b31','rocket'),('mech_warrior','#48c9ff','#173b67','mech'),('sniper_unit','#78b7d9','#2a3039','soldier'),
('shield_drone','#56e8ff','#145f8e','drone'),('repair_drone','#5fefff','#3a7498','drone'),('assault_soldier','#ff5959','#252d3c','soldier'),('elite_commander','#ffb24b','#1b4b80','mech')]

def svg_header():
    return '<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">'

def unit_svg(name,c1,c2,kind):
    s=[svg_header(),'<defs>',f'<linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{c1}"/><stop offset="1" stop-color="{c2}"/></linearGradient>',
       '<filter id="glow"><feGaussianBlur stdDeviation="5" result="b"/><feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>',
       '</defs>','<ellipse cx="128" cy="198" rx="78" ry="18" fill="#000" opacity=".28"/>']
    if kind in ('fighter','wide','stealth','gunship','cruiser','carrier'):
        if kind=='fighter': pts='128,38 160,96 218,126 165,146 148,208 128,176 108,208 91,146 38,126 96,96'
        elif kind=='wide': pts='128,46 178,92 225,126 173,142 153,190 128,169 103,190 83,142 31,126 78,92'
        elif kind=='stealth': pts='128,46 174,102 219,132 157,142 128,197 99,142 37,132 82,102'
        elif kind=='gunship': pts='128,44 172,88 205,115 181,158 154,146 145,202 111,202 102,146 75,158 51,115 84,88'
        elif kind=='cruiser': pts='128,32 160,72 178,108 211,127 176,145 159,205 128,182 97,205 80,145 45,127 78,108 96,72'
        else: pts='128,34 169,76 199,107 220,142 165,150 152,207 128,188 104,207 91,150 36,142 57,107 87,76'
        s += [f'<polygon points="{pts}" fill="url(#g)" stroke="#d8f6ff" stroke-width="3" filter="url(#glow)"/>',
              '<path d="M128 55 L145 130 L128 164 L111 130 Z" fill="#e8fbff" opacity=".9"/>',
              f'<circle cx="128" cy="119" r="13" fill="{c1}" stroke="#fff" stroke-width="3"/>',
              '<path d="M106 174 L98 224 L118 193 M150 174 L158 224 L138 193" stroke="#59dfff" stroke-width="7" stroke-linecap="round" opacity=".85"/>']
    elif kind in ('tank','artillery','rocket'):
        s += ['<rect x="52" y="116" width="152" height="72" rx="24" fill="url(#g)" stroke="#e7dfbd" stroke-width="3"/>',
              '<circle cx="76" cy="190" r="22" fill="#1a1d20" stroke="#8e927b" stroke-width="6"/><circle cx="180" cy="190" r="22" fill="#1a1d20" stroke="#8e927b" stroke-width="6"/>',
              f'<rect x="86" y="91" width="84" height="58" rx="18" fill="{c1}" stroke="#f8e9c4" stroke-width="3"/>']
        if kind=='tank': s += ['<rect x="122" y="58" width="16" height="82" rx="7" fill="#c7b27d" transform="rotate(20 130 99)"/>']
        elif kind=='artillery': s += ['<rect x="125" y="32" width="15" height="118" rx="7" fill="#d7c198" transform="rotate(12 132 91)"/>']
        else: s += ['<g fill="#cf7638"><rect x="93" y="53" width="18" height="72" rx="8"/><rect x="120" y="47" width="18" height="78" rx="8"/><rect x="147" y="53" width="18" height="72" rx="8"/></g>']
    elif kind=='drone':
        s += [f'<circle cx="128" cy="128" r="58" fill="url(#g)" stroke="#dfffff" stroke-width="4" filter="url(#glow)"/>','<circle cx="128" cy="128" r="27" fill="#b9f8ff"/><circle cx="128" cy="128" r="15" fill="#0a6ca8"/>',
              '<path d="M69 104 L38 75 M187 104 L218 75 M69 152 L38 181 M187 152 L218 181" stroke="#8cecff" stroke-width="13" stroke-linecap="round"/>']
    elif kind in ('mech','soldier'):
        s += [f'<circle cx="128" cy="63" r="28" fill="{c1}" stroke="#d9f2ff" stroke-width="3"/>',f'<path d="M91 94 Q128 75 165 94 L178 157 Q151 175 128 165 Q105 175 78 157 Z" fill="url(#g)" stroke="#d7e8f5" stroke-width="3"/>',
              '<path d="M95 160 L75 224 M161 160 L181 224 M82 111 L42 165 M174 111 L214 165" stroke="#a9bed0" stroke-width="18" stroke-linecap="round"/>']
        if kind=='soldier': s += ['<rect x="176" y="111" width="14" height="90" rx="6" fill="#c7d2db" transform="rotate(18 183 156)"/>']
    s += [f'<text x="128" y="244" text-anchor="middle" font-family="sans-serif" font-size="13" fill="#bdefff" opacity=".0">{name}</text>','</svg>']
    return ''.join(s)

for name,c1,c2,kind in unit_specs:
    (UNITS/f'{name}.svg').write_text(unit_svg(name,c1,c2,kind))

maps=[
('terra','#173d29','#4e8a43','#39a7d8'),('volcanis','#29171a','#7d2e1f','#ff4a16'),('cryon','#234558','#9ed5e9','#d9fbff'),('desertus','#68451f','#c88d49','#f2c77c'),('noctis','#091326','#263a60','#5b78b5'),
('aquara','#0b4764','#3f9f85','#4ad9d0'),('mechanis','#1f2833','#526678','#38bdf8'),('toxicus','#2d4519','#6f9c35','#a6f05a'),('nebularis','#25133f','#723d91','#c859ff'),('asteroid_belt','#23252b','#62584f','#a98c6d'),
('ruins','#39342f','#766c5d','#b39a72'),('orbit_station','#162638','#384e66','#45c8ff'),('moon_base','#34363a','#85888e','#d1d3d8'),('gas_giant','#553b32','#ad7658','#f2c285'),('wormhole','#19082e','#4e1d78','#7e5cff')]

def map_svg(name,a,b,accent,idx):
    rings='' if name not in ('mechanis','orbit_station','moon_base','wormhole') else ''.join([f'<circle cx="512" cy="512" r="{r}" fill="none" stroke="{accent}" stroke-opacity=".18" stroke-width="{8+(r%20)}"/>' for r in (110,180,270,360)])
    dots=[]; rr=random.Random(1942+idx)
    for i in range(75):
        x=rr.randint(20,1004); y=rr.randint(20,1004); rad=rr.randint(8,48); op=rr.uniform(.05,.22)
        dots.append(f'<circle cx="{x}" cy="{y}" r="{rad}" fill="{accent}" fill-opacity="{op:.2f}"/>')
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024"><defs><linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="{a}"/><stop offset="1" stop-color="{b}"/></linearGradient><filter id="noise"><feTurbulence type="fractalNoise" baseFrequency=".015" numOctaves="4" seed="{idx+7}"/><feColorMatrix values="1 0 0 0 0 0 1 0 0 0 0 0 1 0 0 0 0 0 .18 0"/></filter></defs><rect width="1024" height="1024" fill="url(#bg)"/><rect width="1024" height="1024" filter="url(#noise)" opacity=".5"/>{''.join(dots)}{rings}<path d="M0 720 Q220 650 410 740 T760 700 T1024 735 V1024 H0 Z" fill="#07111c" opacity=".18"/></svg>'''

for i,(name,a,b,accent) in enumerate(maps):
    (MAPS/f'{name}.svg').write_text(map_svg(name,a,b,accent,i))
print('generated',len(unit_specs),'units and',len(maps),'maps')

main_path = Path('game/scripts/main.gd')
c = main_path.read_text()

c = c.replace(
    'var building_textures: Array[Texture2D] = []\n',
    'var building_textures: Array[Texture2D] = []\n'
    'var unit_textures: Array[Texture2D] = []\n'
    'var map_textures: Array[Texture2D] = []\n'
    'var terrain_sprite: Sprite2D\n\n'
    'const UNIT_IDS := [\n'
    '    "fighter","interceptor","bomber","heavy_fighter","stealth_fighter","gunship","missile_cruiser","destroyer","battle_cruiser","carrier",\n'
    '    "battle_tank","siege_tank","artillery","rocket_launcher","mech_warrior","sniper_unit","shield_drone","repair_drone","assault_soldier","elite_commander"\n'
    ']\n'
    'const MAP_IDS := [\n'
    '    "terra","volcanis","cryon","desertus","noctis","aquara","mechanis","toxicus","nebularis","asteroid_belt","ruins","orbit_station","moon_base","gas_giant","wormhole"\n'
    ']\n'
)

c = c.replace(
'''func _load_assets() -> void:
    for b in BUILDINGS:
        building_textures.append(load("res://assets/buildings/%s.png" % b.id))
''',
'''func _load_assets() -> void:
    for b in BUILDINGS:
        building_textures.append(load("res://assets/buildings/%s.png" % b.id))
    for id in UNIT_IDS:
        unit_textures.append(load("res://assets/units/%s.svg" % id))
    for id in MAP_IDS:
        map_textures.append(load("res://assets/maps/%s.svg" % id))
''')

c = c.replace(
'''func _create_world() -> void:
    world_layer = Node2D.new()
    world_layer.name = "World"
    add_child(world_layer)
''',
'''func _create_world() -> void:
    terrain_sprite = Sprite2D.new()
    terrain_sprite.name = "Terrain"
    terrain_sprite.texture = map_textures[0]
    terrain_sprite.position = WORLD_SIZE * 0.5
    terrain_sprite.scale = Vector2(WORLD_SIZE.x / terrain_sprite.texture.get_width(), WORLD_SIZE.y / terrain_sprite.texture.get_height())
    terrain_sprite.z_index = -10000
    add_child(terrain_sprite)
    world_layer = Node2D.new()
    world_layer.name = "World"
    add_child(world_layer)
''')

start = c.index('func _make_galaxy_ui() -> Control:')
end = c.index('\nfunc _return_home()', start)
new_galaxy = '''func _make_galaxy_ui() -> Control:
    var root := Control.new()
    root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var bg := TextureRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.texture = load("res://assets/ui/splash.jpg")
    bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    bg.modulate = Color(0.28,0.38,0.65,0.95)
    root.add_child(bg)
    var shade := ColorRect.new()
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    shade.color = Color(0.0,0.01,0.05,0.58)
    root.add_child(shade)
    var title := Label.new()
    title.position = Vector2(725,45)
    title.text = "GALAXY MAP • 15 WORLDS"
    title.add_theme_font_size_override("font_size",34)
    root.add_child(title)
    var pts := [Vector2(330,210),Vector2(575,185),Vector2(820,235),Vector2(1060,180),Vector2(1320,250),Vector2(1510,390),Vector2(1180,430),Vector2(900,420),Vector2(620,430),Vector2(390,470),Vector2(500,690),Vector2(760,690),Vector2(1020,680),Vector2(1280,690),Vector2(1510,670)]
    for i in pts.size():
        var b := Button.new()
        b.position = pts[i]
        b.size = Vector2(155,92)
        b.text = "%s\nLV.%d" % [MAP_IDS[i].replace("_"," ").to_upper(), 4+i*2]
        b.icon = map_textures[i]
        b.expand_icon = true
        b.icon_max_width = 58
        b.add_theme_font_size_override("font_size",11)
        b.add_theme_stylebox_override("normal",_panel_style(Color(0.03,0.10,0.18,0.91),24,Color(0.25,0.70,1.0),2))
        b.add_theme_stylebox_override("hover",_panel_style(Color(0.12,0.22,0.38,0.98),24,GOLD,3))
        b.pressed.connect(func(idx=i): target_planet=idx; _start_battle())
        root.add_child(b)
    var back := _button("RETURN HOME", func(): _return_home(), Vector2(230,60))
    back.position = Vector2(50,960)
    root.add_child(back)
    return root
'''
c = c[:start] + new_galaxy + c[end:]

c = c.replace(
'''func _return_home() -> void:
    mode = "base"
''',
'''func _return_home() -> void:
    mode = "base"
    terrain_sprite.texture = map_textures[0]
    terrain_sprite.position = WORLD_SIZE * 0.5
    terrain_sprite.scale = Vector2(WORLD_SIZE.x / terrain_sprite.texture.get_width(), WORLD_SIZE.y / terrain_sprite.texture.get_height())
''')

start = c.index('func _start_battle() -> void:')
end = c.index('\nfunc _battle_tick', start)
new_battle = '''func _start_battle() -> void:
    mode = "battle"
    if galaxy_layer: galaxy_layer.visible = false
    terrain_sprite.texture = map_textures[target_planet % map_textures.size()]
    terrain_sprite.position = WORLD_SIZE * 0.5
    terrain_sprite.scale = Vector2(WORLD_SIZE.x / terrain_sprite.texture.get_width(), WORLD_SIZE.y / terrain_sprite.texture.get_height())
    battle_layer = Node2D.new()
    add_child(battle_layer)
    enemy_buildings.clear()
    battle_units.clear()
    battle_damage = 0.0
    battle_time = 0.0
    var positions := [Vector2(1300,570),Vector2(950,650),Vector2(1650,650),Vector2(1080,900),Vector2(1520,900),Vector2(800,980),Vector2(1800,980)]
    var types := [0,8,8,9,6,2,3]
    for i in positions.size():
        var s := Sprite2D.new()
        s.texture = building_textures[types[i]]
        s.position = positions[i]
        s.scale = Vector2.ONE * (0.52 if i == 0 else 0.40)
        s.z_index = int(s.position.y)
        battle_layer.add_child(s)
        enemy_buildings.append({"sprite":s,"hp":500.0 if i==0 else 260.0,"max":500.0 if i==0 else 260.0,"pos":positions[i]})
    var unit_types := [0,2,5,16]
    for i in 20:
        var type_idx: int = unit_types[i % unit_types.size()]
        var s := Sprite2D.new()
        s.texture = unit_textures[type_idx]
        s.position = Vector2(690+i*45,1420+(i%4)*42)
        s.scale = Vector2.ONE * (0.34 if type_idx < 10 else 0.28)
        s.z_index = int(s.position.y)
        battle_layer.add_child(s)
        battle_units.append({"node":s,"damage":7.0+float(i%4),"type":type_idx})
    camera.position = Vector2(1300,950)
    camera.zoom = Vector2(0.72,0.72)
    battle_label = Label.new()
    battle_label.position = Vector2(650,115)
    battle_label.size = Vector2(700,60)
    battle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    battle_label.add_theme_font_size_override("font_size",26)
    canvas.add_child(battle_label)
    var retreat := _button("RETREAT",func(): _finish_battle(false),Vector2(180,56))
    retreat.position = Vector2(1690,970)
    canvas.add_child(retreat)
    retreat.name = "BattleRetreat"
'''
c = c[:start] + new_battle + c[end:]
c = c.replace('var node: Polygon2D = u.node', 'var node: Sprite2D = u.node')

start = c.index('func _draw_planet_terrain(land: Color, water: Color) -> void:')
end = c.index('\nfunc _button(', start)
new_draw = '''func _draw_planet_terrain(_land: Color, _water: Color) -> void:
    for y in [620.0,900.0,1180.0]:
        draw_line(Vector2(400,y),Vector2(2200,y+80),Color(0.06,0.08,0.10,0.72),72)
        draw_line(Vector2(400,y),Vector2(2200,y+80),Color(0.50,0.55,0.58,0.34),5)
    draw_line(Vector2(900,320),Vector2(1050,1420),Color(0.06,0.08,0.10,0.70),68)
    draw_line(Vector2(900,320),Vector2(1050,1420),Color(0.50,0.55,0.58,0.32),5)
    for x in range(260,2400,90):
        draw_line(Vector2(x,250),Vector2(x+700,1500),Color(0.25,0.75,0.65,0.045),1)
    for x in range(600,2800,90):
        draw_line(Vector2(x,250),Vector2(x-700,1500),Color(0.25,0.75,0.65,0.045),1)
'''
c = c[:start] + new_draw + c[end:]
main_path.write_text(c)
print('Godot assets and gameplay patch prepared.')
