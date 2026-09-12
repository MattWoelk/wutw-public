@abstract
class_name SpotUpgradeVisual
extends Resource

# Abstract, but if we mark it as such, the static analyzer can't guess it's a coroutine.
# It's more useful to get warnings at call sites than at the implementations, of which there are fewer.
func apply(_map: Map, _pos: Vector2, _radius: float, _roof_color_override: Color) -> MapModification:
	assert(false)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return null
