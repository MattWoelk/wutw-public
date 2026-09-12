class_name MapModification_Road
extends MapModification

var src: Vector2
var src_radius: float
var dst: Vector2
var dst_radius: float

func apply(map: Map, animate: bool = true) -> bool:
	var road := await map.get_road_manager().create_new_road(src, src_radius, dst, dst_radius, not animate)
	return road != null

func _encode_args() -> Dictionary:
	return {
		'src': [src.x, src.y],
		'src_radius': src_radius,
		'dst': [dst.x, dst.y],
		'dst_radius': dst_radius,
	}

func _decode_args(encoded: Dictionary) -> void:
	src.x = encoded['src'][0]
	src.y = encoded['src'][1]
	src_radius = encoded['src_radius']
	dst.x = encoded['dst'][0]
	dst.y = encoded['dst'][1]
	dst_radius = encoded['dst_radius']
