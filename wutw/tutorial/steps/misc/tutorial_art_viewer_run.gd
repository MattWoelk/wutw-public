class_name Tutorial_ArtViewer_Run
extends TutorialBase

func get_tutorial_type() -> Type:
	# There's a hub version as well, which shares a skip ID.
	return Type.RUN

func start_listening() -> void:
	pass  # Called manually.

func stop_listening() -> void:
	pass  # Called manually.

func trigger() -> void:
	var viewer := ArtViewer.get_active_instance()
	assert(viewer)

	var text := tr('''
This is the Art Viewer.

It contains details of all historical artwork used in the game, as well as uncropped high resolution images.

If you are unfamiliar with Japanese art, a brief introduction is available in the Intro tab.

Most pages have a link icon in the title leading to a web resource with more information.
''').strip_edges()

	_outline_controls([])
	_show_tooltip(viewer.get_node('%ScrollPanel') as Control, text, [Tooltip.RelativeDirection.FORCE_CENTER])
	# Hitting Esc to close the viewer keeps the tutorial on.
	viewer.closed.connect(func() -> void:
		remove()
	)

func _get_container() -> Control:
	if not _container:
		_container = Control.new()
		_container.name = (get_script() as Script).get_global_name()
		# HACK: Unlike superclass, use the loading screen layer, since the viewer is on the modal layer.
		GlobalUI.add_layer_content(_container, UI.Layer.LOADING_SCREEN)
	return _container

func get_skip_id() -> String:
	return 'art_viewer'
