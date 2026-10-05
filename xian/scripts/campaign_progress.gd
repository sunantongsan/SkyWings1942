extends RefCounted
const COUNT=90
var path="user://campaign_progress_v1.json"
var stars: Dictionary={}
var selected=1
func load_progress():
	stars={};selected=1
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var parser=JSON.new()
		if parser.parse(FileAccess.get_file_as_string(candidate))!=OK:continue
		var data=parser.data
		if not data is Dictionary or data.get("version",0)!=1 or not data.get("stars") is Dictionary:continue
		for key in data.stars:
			if str(key).is_valid_int() and int(key)>=1 and int(key)<=COUNT and (data.stars[key] is float or data.stars[key] is int):stars[str(int(key))]=clampi(int(data.stars[key]),0,3)
		selected=clampi(int(data.get("selected",1)),1,unlocked());return
func unlocked() -> int:
	for n in range(1,COUNT):
		if int(stars.get(str(n),0))<1:return n
	return COUNT
func total() -> int:
	var sum=0
	for value in stars.values():sum+=int(value)
	return sum
func record(number: int,result: int) -> Error:
	if number<1 or number>unlocked():return ERR_INVALID_PARAMETER
	stars[str(number)]=maxi(int(stars.get(str(number),0)),clampi(result,0,3));selected=number
	return save()
func save() -> Error:
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if not file:return FileAccess.get_open_error()
	file.store_string(JSON.stringify({"version":1,"stars":stars,"selected":selected}));file.flush()
	var error=file.get_error();file.close()
	if error!=OK:return error
	# Keep last known complete progress, then atomically replace the current file.
	if FileAccess.file_exists(path):
		error=DirAccess.copy_absolute(path,path+".bak")
		if error!=OK:return error
	return DirAccess.rename_absolute(path+".tmp",path)
