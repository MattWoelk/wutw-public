class_name HistoricalRecord
extends Resource

@export var name: String
@export_multiline var pages: Array[String]
@export var icon: Texture2D
@export_file('*.tscn') var cutscene_path: String
@export var cutscene_cover: LazyTextureResource
