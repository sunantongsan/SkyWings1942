@tool
extends EditorPlugin
var exporter:EditorExportPlugin
func _enter_tree()->void:
	exporter=AdsExport.new();add_export_plugin(exporter)
func _exit_tree()->void:remove_export_plugin(exporter)
class AdsExport extends EditorExportPlugin:
	func _get_name()->String:return "GalaxyAds"
	func _supports_platform(platform:EditorExportPlatform)->bool:return platform is EditorExportPlatformAndroid
	func _get_android_libraries(_platform:EditorExportPlatform,_debug:bool)->PackedStringArray:
		return PackedStringArray(["galaxy_ads/GalaxyAds.aar"])
	func _get_android_dependencies(_platform:EditorExportPlatform,_debug:bool)->PackedStringArray:
		return PackedStringArray(["com.google.android.gms:play-services-ads:24.0.0","com.google.android.ump:user-messaging-platform:3.1.0"])
