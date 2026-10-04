extends RefCounted
const DIRS=[Vector2i.RIGHT,Vector2i.UP,Vector2i.LEFT,Vector2i.DOWN]
static func cell(b: Dictionary) -> Vector2i:
	return Vector2i(int(b.x),int(b.y)) if b.has("x") else Vector2i(b.pos)
static func is_wall(b: Dictionary) -> bool:return b.get("id",b.get("kind",""))=="wall" and float(b.get("hp",1))>0
static func mask(buildings: Array, pos: Vector2i) -> int:
	var value=0
	for b in buildings:
		if not is_wall(b):continue
		var delta=cell(b)-pos
		for i in range(4):
			if delta==DIRS[i]:value|=1<<i
	return value
static func run_indices(buildings: Array, selected: int) -> Array:
	if selected<0 or selected>=buildings.size() or not is_wall(buildings[selected]):return []
	var origin=cell(buildings[selected]);var bits=mask(buildings,origin)
	var axis=int(buildings[selected].get("rotation",0))%2
	if bits & 5==0 and bits & 10!=0:axis=1
	elif bits & 10==0 and bits & 5!=0:axis=0
	var step=Vector2i.RIGHT if axis==0 else Vector2i.DOWN
	var result=[selected]
	for direction in [-1,1]:
		for distance in range(1,16):
			var target=origin+step*direction*distance;var found=-1
			for i in range(buildings.size()):
				if is_wall(buildings[i]) and cell(buildings[i])==target:found=i;break
			if found<0:break
			result.append(found)
	return result
static func line(start: Vector2i, end: Vector2i, axis: int=-1) -> Array:
	var diff=end-start
	if axis<0:axis=0 if absi(diff.x)>=absi(diff.y) else 1
	var distance=clampi(diff.x if axis==0 else diff.y,-15,15)
	var step=Vector2i.RIGHT if axis==0 else Vector2i.DOWN
	var result=[]
	for i in range(absi(distance)+1):result.append(start+step*signi(distance)*i)
	return result
