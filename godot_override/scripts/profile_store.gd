extends RefCounted
## A versioned local colony save; temp replacement plus a last-good backup.
var recovered_backup := false
var load_error := false

func read_profile(path:String)->Dictionary:
	recovered_backup=false;load_error=false
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var parsed=_parse_file(candidate)
		if _valid(parsed):
			recovered_backup=candidate!=path
			return parsed
		load_error=true
	return {}

func write_profile(path:String,data:Dictionary)->bool:
	if not _valid(data):return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:return false
	file.store_string(JSON.stringify(data));file.flush();file.close()
	if FileAccess.file_exists(path):
		# Never replace a valid backup with a corrupt main file.
		if _valid(_parse_file(path)):
			if DirAccess.copy_absolute(path,path+".bak")!=OK:return false
		if DirAccess.remove_absolute(path)!=OK:return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func _valid(data:Variant)->bool:
	if not data is Dictionary:return false
	if data.get("schema",0)!=1:return false
	for key in ["home_planet","tutorial_step","resources","buildings","unit_stock"]:
		if not data.has(key):return false
	if not _number(data.home_planet,0,14) or not _number(data.tutorial_step,0,13):return false
	if not data.resources is Array or data.resources.size()!=4:return false
	for value in data.resources:
		if not _number(value,0,1e12):return false
	if not data.unit_stock is Array or data.unit_stock.size()!=20:return false
	for value in data.unit_stock:
		if not _number(value,0,1000000):return false
	if not data.buildings is Array or data.buildings.size()>300:return false
	var kinds:Dictionary={}
	for b in data.buildings:
		if not b is Dictionary:return false
		if not _number(b.get("type",-1),0,9) or not _number(b.get("level",0),1,100):return false
		if not b.get("pos") is Array or b.pos.size()!=3:return false
		if not _number(b.pos[0],-18,18) or not _number(b.pos[1],0,0) or not _number(b.pos[2],-15,15):return false
		kinds[int(b.type)]=true
	var order:=[0,1,2,5,3,4,6,8,7,9]
	for i in mini(int(data.tutorial_step),10):
		if not kinds.has(order[i]):return false
	return true

func _number(value:Variant,low:float,high:float)->bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value)>=low and float(value)<=high

func _parse_file(path:String)->Variant:
	var parser:=JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK:return null
	return parser.data
