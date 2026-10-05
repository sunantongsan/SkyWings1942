extends SceneTree
# Format conversion only; source pixels stay at their original resolution.
# WebP keeps alpha and reduces download/export size for Android.
func _initialize():
	for file in DirAccess.get_files_at("res://assets/realistic"):
		if not file.ends_with(".png"):continue
		var source="res://assets/realistic/"+file
		var image=Image.load_from_file(source)
		assert(not image.is_empty())
		assert(image.save_webp(source.trim_suffix(".png")+".webp",true,0.90)==OK)
	print("REALISTIC_FORMAT_CONVERSION_PASSED");quit()
