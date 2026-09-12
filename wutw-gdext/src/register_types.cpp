#include "register_types.h"

#include <gdextension_interface.h>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "map_biomes.h"
#include "quad_tree.h"
#include "map_generation_config.h"
#include "generated_map.h"
#include "map_generator.h"
#include "map_sprite_type.h"
#include "map_sprite_type_composite.h"
#include "map_sprite_type_tree.h"
#include "map_sprite_type_mountain.h"
#include "map_sprite_type_grass.h"
#include "map_sprite_type_building.h"
#include "map_sprite_type_generic.h"
#include "map_sprite_type_lake.h"
#include "map_sprite_type_river.h"
#include "map_sprite_type_sea_wave.h"
#include "map_sprite_placer.h"
#include "map_sprite_renderer.h"
#include "map_ambiance_tracker.h"
#include "road_creator.h"

using namespace godot;

void initialize_wutw_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;

	GDREGISTER_CLASS(MapBiomeConfig);
	GDREGISTER_CLASS(MapBaseConfig);
	GDREGISTER_CLASS(MapInputTextures);
	GDREGISTER_CLASS(MapShardBottomConfig);
	GDREGISTER_CLASS(MapStampConfig);
	GDREGISTER_CLASS(MapRiverConfig);
	GDREGISTER_CLASS(MapGenerationConfig);

	GDREGISTER_CLASS(MapBiomes);
	GDREGISTER_CLASS(MapPath);
	GDREGISTER_CLASS(GeneratedMap);
	GDREGISTER_CLASS(MapGenerator);

	GDREGISTER_CLASS(QuadTree);
	GDREGISTER_CLASS(MapSpriteCollision);
	GDREGISTER_CLASS(MapSpriteCollision_Circle);
	GDREGISTER_CLASS(MapSpriteCollision_Rect);
	GDREGISTER_CLASS(MapSpriteCollision_Line);
	GDREGISTER_CLASS(MapSpriteCollision_Triangle);
	GDREGISTER_CLASS(MapEffectAttachment);
	GDREGISTER_CLASS(MapSpriteType);
	GDREGISTER_CLASS(MapSpriteType_Tree);
	GDREGISTER_CLASS(MapSpriteType_Mountain);
	GDREGISTER_CLASS(MapSpriteType_Grass);
	GDREGISTER_CLASS(MapSpriteType_Building);
	GDREGISTER_CLASS(MapSpriteType_Generic);
	GDREGISTER_CLASS(MapSpriteType_River);
	GDREGISTER_CLASS(MapSpriteType_SeaWave);
	GDREGISTER_CLASS(MapSpriteType_Lake);
	GDREGISTER_CLASS(MapSpriteComponent);
	GDREGISTER_CLASS(MapSpriteType_Composite);
	GDREGISTER_CLASS(MapSpritePlacer);
	GDREGISTER_CLASS(MapSpritePlacerConfig);
	GDREGISTER_CLASS(MapSpritePlacement);
	GDREGISTER_CLASS(MapSpriteRenderer);
	GDREGISTER_CLASS(RoadCreator);
	
	GDREGISTER_CLASS(MapAmbianceTracker);
}

void uninitialize_wutw_module(ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) return;
}

extern "C" {
	GDExtensionBool GDE_EXPORT wutw_library_init(GDExtensionInterfaceGetProcAddress p_get_proc_address, const GDExtensionClassLibraryPtr p_library, GDExtensionInitialization *r_initialization) {
		godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);
		init_obj.register_initializer(initialize_wutw_module);
		init_obj.register_terminator(uninitialize_wutw_module);
		init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);
		return init_obj.init();
	}
}
