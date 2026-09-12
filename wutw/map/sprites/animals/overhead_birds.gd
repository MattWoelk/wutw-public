class_name OverheadBirds
extends GPUParticles2D

@export var max_y := 540.0
@export var min_wait := 1.5
@export var max_wait := 10.0

func _ready() -> void:
	var mat := process_material.duplicate() as ParticleProcessMaterial
	process_material = mat
	while is_node_ready():
		mat.emission_shape_offset.y = randf_range(0, max_y)
		mat.direction.y = 0.5 - (mat.emission_shape_offset.y / max_y) + randf_range(-0.1, 0.1)
		emitting = true
		await finished
		await get_tree().create_timer(randf_range(min_wait, max_wait)).timeout
