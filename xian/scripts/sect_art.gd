extends RefCounted
# Real geometry for mechanisms/countable parts, photographed material atlas.
const WELL_MATERIALS=["ไม้ไผ่","ท่อสนิม","PVC","เหล็ก","สแตนเลส","เงิน","ทอง","ทับทิม","หยก","ทองคำฝังเพชร"]
const WALL_MATERIALS=["ไม้ไผ่ผุ","สังกะสีเก่า","ไม้ไผ่สวย","ไม้เนื้อแข็ง","แท่งคอนกรีต","อิฐมอญ","คอนกรีต","คอนกรีตเสริมเหล็ก","เหล็กกล้า","ทองคำ"]
var art
func surface(index: int) -> Material:
	var key="tier_"+str(index)
	if art.mats.has(key):return art.mats[key]
	var mat=ShaderMaterial.new();var shader=Shader.new()
	shader.code="""shader_type spatial;
uniform sampler2D atlas : source_color, filter_linear_mipmap;
uniform vec2 tile;
uniform vec2 grid_size=vec2(5.0,2.0);
uniform float metal=0.0;
void fragment(){vec2 uv=(tile+clamp(UV,vec2(0.008),vec2(0.992)))/grid_size;ALBEDO=texture(atlas,uv).rgb;METALLIC=metal;ROUGHNESS=metal>0.0?0.32:0.87;}
"""
	mat.shader=shader
	var cols=3 if index>=10 else 5;var cell=index-10 if index>=10 else index
	mat.set_shader_parameter("atlas",art.realistic.texture("pump_materials" if index>=10 else "materials"));mat.set_shader_parameter("grid_size",Vector2(cols,2));mat.set_shader_parameter("tile",Vector2(cell%cols,cell/cols));mat.set_shader_parameter("metal",0.45 if index in [1,8,9,11,12,13] else 0.0);art.mats[key]=mat;return mat
func block(parent: Node3D,pos: Vector3,size: Vector3,index: int):
	var m=art.box(parent,pos,size,"ffffff");m.material_override=surface(index);return m
func rod(parent: Node3D,a: Vector3,b: Vector3,r: float,index: int):
	var m=art.cone(parent,(a+b)*0.5,r,r,a.distance_to(b),"ffffff",16);m.quaternion=Quaternion(Vector3.UP,(b-a).normalized());m.material_override=surface(index);return m
func wall(mask: int, rotation: int, level: int) -> Node3D:
	level=clampi(level,1,10)
	var root=Node3D.new();root.set_meta("wall_mask",mask);root.set_meta("material_name",WALL_MATERIALS[level-1]);root.set_meta("visual_level",level)
	if mask==0:mask=5 if rotation%2==0 else 10
	var h=1.25+level*0.07
	for side in range(4):
		if not mask & (1<<side):continue
		var span=Node3D.new();span.rotation.y=side*PI/2;root.add_child(span)
		if level in [1,3,4]:
			for i in range(6):
				var x=0.12+i*0.25;var top=h-(0.12*(i%3) if level==1 else 0)
				if level==4:block(span,Vector3(x,top/2,0),Vector3(0.235,top,0.21),3)
				else:
					rod(span,Vector3(x,0,0),Vector3(x,top,0),0.10,level-1)
					for y in [0.35,0.83,1.18]:rod(span,Vector3(x,y-0.022,0),Vector3(x,y+0.022,0),0.113,level-1)
			for y in [0.35,0.92]:rod(span,Vector3(0,y,0.13),Vector3(1.5,y,0.13),0.055,3)
		elif level==2:
			for i in range(12):block(span,Vector3(0.0625+i*0.125,h/2,0.035 if i%2 else -0.035),Vector3(0.14,h-(i%3)*0.04,0.07),1)
			for y in [0.2,1.05]:rod(span,Vector3(0,y,0.13),Vector3(1.5,y,0.13),0.065,3)
		elif level==5:
			for i in range(5):block(span,Vector3(0.15+i*0.3,h/2,0),Vector3(0.28,h,0.4),4)
		else:
			block(span,Vector3(0.75,h/2,0),Vector3(1.5,h,0.43),level-1)
			block(span,Vector3(0.75,h+0.06,0),Vector3(1.5,0.12,0.54),level-1)
			if level in [8,9]:
				for x in [0.12,1.4]:
					block(span,Vector3(x,h/2,0.26),Vector3(0.12,h,0.1),8)
					for y in [0.25,h-0.2]:art.orb(span,Vector3(x,y,0.33),Vector3.ONE*0.09,"b4bcc0")
	block(root,Vector3(0,h/2,0),Vector3(0.22,h+0.1,0.22),level-1)
	art.batch_static(root);return root
func building(kind: String,level: int) -> Node3D:
	return well(clampi(level,1,10)) if kind=="well" else ward(clampi(level,1,10))
func well(level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("realistic_art",true);root.set_meta("visual_level",level);root.set_meta("material_name",WELL_MATERIALS[level-1])
	block(root,Vector3(0,0.06,0),Vector3(2.8,0.12,2.8),3 if level<3 else 4 if level<7 else 9)
	var pipe=Node3D.new();root.add_child(pipe)
	var radius=0.10+level*0.012;root.set_meta("pipe_radius",radius)
	var idx=[2,1,10,11,12,13,9,14,15,9][level-1]
	rod(pipe,Vector3(-0.65,0.15,0),Vector3(-0.65,1.48,0),radius,idx)
	rod(pipe,Vector3(-0.65,1.02,0),Vector3(-0.65,1.02,0.62),radius*0.8,idx)
	rod(pipe,Vector3(-0.65,1.02,0.62),Vector3(-0.65,0.86,0.62),radius*0.8,idx)
	for y in [0.2,0.65,1.25]:rod(pipe,Vector3(-0.65,y-0.04,0),Vector3(-0.65,y+0.04,0),radius*1.23,idx)
	var bucket=art.cone(root,Vector3(-0.65,0.3,0.65),0.25,0.32,0.43,"acbbc0",24)
	bucket.material_override=surface(8)
	art.cone(root,Vector3(-0.65,0.522,0.65),0.29,0.29,0.008,"293f49",24)
	var water=art.cone(root,Vector3(-0.65,0.525,0.65),0.275,0.275,0.012,"62c5dc",32)
	var water_mat=ShaderMaterial.new();var water_shader=Shader.new();water_shader.code="""shader_type spatial;
void fragment(){float ripple=sin(length(UV-vec2(0.5))*75.0-TIME*9.0)*0.5+0.5;ALBEDO=mix(vec3(0.10,0.32,0.36),vec3(0.39,0.65,0.69),ripple*0.35);ROUGHNESS=0.16;SPECULAR=0.9;}
""";water_mat.shader=water_shader;water.material_override=water_mat
	var loop=Node3D.new();loop.name="PumpMotion";loop.set_script(preload("res://scripts/pump_motion.gd"));root.add_child(loop)
	var worker=art.realistic.sprite("pump_operator",4*1.32,0);worker.name="RealisticVisual";worker.hframes=4;worker.vframes=2;worker.offset.y=256;worker.position=Vector3(0.53,0.14,0);root.add_child(worker)
	loop.worker=worker
	var lever=rod(loop,Vector3(-0.65,1.4,0),Vector3(0.1,1.3,0.08),0.055,idx);lever.name="Lever";loop.lever=lever
	var stream=art.cone(loop,Vector3(-0.65,0.69,0.62),0.032,0.026,0.34,"90e4f1",12);stream.name="Stream";loop.stream=stream
	for i in range(6):
		var drop=art.orb(loop,Vector3.ZERO,Vector3(0.026,0.05,0.026),"b0edf5");loop.drops.append(drop)
	if level==10:
		for i in range(12):
			var a=i*TAU/12;var gem=art.orb(root,Vector3(-0.65+cos(a)*radius*1.13,0.65+(i%3)*0.25,sin(a)*radius*1.13),Vector3.ONE*0.11,"d6f7ff" if i%3 else "cc2e5f")
			var mat=gem.material_override.duplicate();mat.metallic=0.7;mat.roughness=0.08;mat.emission_enabled=true;mat.emission=Color("a8ced5");gem.material_override=mat;loop.gems.append(gem)
	return root
func ward(level: int) -> Node3D:
	var root=Node3D.new();root.set_meta("realistic_art",true);root.set_meta("visual_level",level);root.set_meta("horn_count",4*level);root.set_meta("sound_radius",4.2)
	var h=2.45+level*0.12;var width=0.65+level*0.015
	block(root,Vector3(0,0.12,0),Vector3(2.55,0.24,2.55),4)
	for x in [-1,1]:
		for z in [-1,1]:
			rod(root,Vector3(x*width,0.24,z*width),Vector3(x*0.38,h,z*0.38),0.075,8)
	for i in range(5):
		var y=0.3+i*(h-0.3)/5
		for side in [-1,1]:
			rod(root,Vector3(-width,y,side*width),Vector3(width,y+(h-0.3)/5,side*width),0.025,8)
			rod(root,Vector3(side*width,y,-width),Vector3(side*width,y+(h-0.3)/5,width),0.025,8)
	block(root,Vector3(0,h,0),Vector3(1.35,0.13,1.35),8)
	for row in range(level):
		for side in range(4):
			var horn=Node3D.new();horn.name="Horn_%02d"%(row*4+side);root.add_child(horn);horn.position.y=h+0.2+row*0.30;horn.rotation.y=side*PI/2
			var shell=art.cone(horn,Vector3(0,0,0.43),0.07,0.19,0.48,"c4ccd0",24);shell.rotation.x=PI/2;shell.material_override=surface(8 if level<10 else 9)
			var inside=art.cone(horn,Vector3(0,0,0.675),0.17,0.17,0.016,"252c31",24);inside.rotation.x=PI/2
			var center=art.cone(horn,Vector3(0,0,0.686),0.048,0.048,0.024,"a1a9a6",16);center.rotation.x=PI/2
	rod(root,Vector3(0,h,0),Vector3(0,h+level*0.30+0.5,0),0.035,8)
	return root
