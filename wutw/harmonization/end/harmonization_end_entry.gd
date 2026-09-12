class_name HarmonizationEndEntry
extends VBoxContainer

var settlement: Settlement

func _ready() -> void:
	var run := Utils.get_active_run()
	var loss_per_lack := run.get_var(RunVars.Var.INSPIRATION_LOSS_PER_LACK)
	(%NameLabel as Label).text = settlement.state.settlement_name.get_display_name() + ': '
	var lacks := settlement.get_unsatisfied_lacks()
	var result_label := %ResultLabel as Label
	var inspiration_box := %InspirationBox as Control
	var inspiration_label := %InspirationLabel as Label
	match lacks.size():
		0:
			result_label.text = tr('Shortages fulfilled!')
			inspiration_box.visible = false
		1:
			result_label.text = tr('%s shortage unfulfilled.') % tr(lacks[0].name)
			inspiration_label.text = '-%d' % loss_per_lack
		2:
			result_label.text = tr('%s and %s shortages unfulfilled.') % [tr(lacks[0].name), tr(lacks[1].name)]
			inspiration_label.text = '-%d' % (2 * loss_per_lack)
		_:
			assert(false)
	GlobalTooltipSystem.attach(self, _make_tooltip_text,
			[Tooltip.RelativeDirection.RIGHT], [Tooltip.Alignment.BEGIN])

func get_inspiration_damage() -> int:
	var run := Utils.get_active_run()
	var loss_per_lack := run.get_var(RunVars.Var.INSPIRATION_LOSS_PER_LACK)
	return settlement.get_unsatisfied_lacks().size() * loss_per_lack

func _make_tooltip_text() -> String:
	var parse_result : Term.ParseResult = Term.parse('<related_term:lack><related_term:inspiration>')
	return MarkedUpLabel.expand_links(parse_result.linked_terms.keys()).bbcode_text
