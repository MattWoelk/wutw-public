@abstract
class_name ArtPiece
extends Resource

enum DateType {
	EXACT = 0,
	APPROXIMATE = 1,
	PERIOD_KAMAKURA = 10,
	PERIOD_MUROMACHI = 20,
	PERIOD_EDO = 30,
	PERIOD_MEIJI = 40,
	PERIOD_TAISHO = 50,
	UNKNOWN = 100,
}

@export var final_image_tex: LazyTextureResource
@export var province: JapanProvinceArea.Province
@export_multiline var blurb: String

@abstract func get_title() -> String
@abstract func get_attribution() -> String
@abstract func get_start_year() -> int
@abstract func get_end_year() -> int
@abstract func get_sort_index() -> int

# Abstract, but if we mark it as such, the static analyzer can't guess it's a coroutine.
# It's more useful to get warnings at call sites than at the implementations, of which there are fewer.
func get_original_image() -> Texture2D:
	Utils.ensure(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return null
