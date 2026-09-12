@tool
class_name ContextHighlight
extends Node

signal offer_changed(offered: Context)
signal request_changed(requested: Context)

var enabled := true:
	set(value):
		if enabled == value:
			return
		enabled = value
		if enabled:
			_enable_highlights()
		else:
			_disable_highlights()

var _offer_contexts: Array[Context]
var _request_contexts: Array[Context]

func offer(context: Context) -> void:
	if get_viewport().gui_is_dragging():
		return
	_clear_existing(_offer_contexts, context.node)
	_offer_contexts.append(context)
	if enabled:
		offer_changed.emit(context)

func retract_offer(node: Node) -> void:
	if _offer_contexts:
		_clear_existing(_offer_contexts, node)
		if enabled:
			offer_changed.emit(_offer_contexts[-1] if _offer_contexts else null)

func offer_on_hover(context: Context) -> void:
	assert(context.node is Control)
	(context.node as Control).mouse_entered.connect(offer.bind(context))
	(context.node as Control).mouse_exited.connect(retract_offer.bind(context.node))
	context.node.tree_exiting.connect(retract_offer.bind(context.node))

func request(context: Context) -> void:
	if get_viewport().gui_is_dragging():
		return
	_clear_existing(_request_contexts, context.node)
	_request_contexts.append(context)
	if enabled:
		request_changed.emit(context)

func retract_request(node: Node) -> void:
	if _request_contexts:
		_clear_existing(_request_contexts, node)
		if enabled:
			request_changed.emit(_request_contexts[-1] if _request_contexts else null)

func request_on_hover(context: Context) -> void:
	assert(context.node is Control)
	(context.node as Control).mouse_entered.connect(request.bind(context))
	(context.node as Control).mouse_exited.connect(retract_request.bind(context.node))
	context.node.tree_exiting.connect(retract_request.bind(context.node))

static func aspects(node: Node, in_aspect_types: Array[AspectType]) -> Context:
	var result := Context.new()
	result.node = node
	result.aspect_types = in_aspect_types
	return result

static func bonuses(node: Node, in_bonus_types: Array[BonusType]) -> Context:
	var result := Context.new()
	result.node = node
	result.bonus_types = in_bonus_types
	return result

static func terms(node: Node, in_terms: Array[Term]) -> Context:
	var result := Context.new()
	result.node = node
	result.terms = in_terms
	return result

func _clear_existing(list: Array[Context], to_remove: Node) -> void:
	for i in range(list.size() - 1, -1, -1):
		if not list[i].node or list[i].node == to_remove:
			list.remove_at(i)

func _disable_highlights() -> void:
	_offer_contexts.clear()
	_request_contexts.clear()
	offer_changed.emit(null)
	request_changed.emit(null)

func _enable_highlights() -> void:
	offer_changed.emit(_offer_contexts[-1] if _offer_contexts else null)
	request_changed.emit(_request_contexts[-1] if _request_contexts else null)

class Context extends RefCounted:
	var node: Node
	var aspect_types: Array[AspectType]
	var bonus_types: Array[BonusType]
	var terms: Array[Term]
