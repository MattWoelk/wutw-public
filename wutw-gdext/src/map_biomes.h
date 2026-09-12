#pragma once

#include <godot_cpp/classes/object.hpp>

#include "quad_tree.h"
#include "map_sprite_placer.h"

using namespace godot;

class MapBiomes : public Object {
    GDCLASS(MapBiomes, Object)

public:
    enum Biome {
        CLOUDS,
        SEA,
        DESERT,
        WASTELAND,
        SWAMP,
        STEPPE,
        PLAINS,
        MOUNTAIN,
        BRUSHLAND,
        FOREST,
        SEASHORE,

        _NUM_BIOME_TYPES,
    };

protected:
    static void _bind_methods();
};

VARIANT_ENUM_CAST(MapBiomes::Biome);
