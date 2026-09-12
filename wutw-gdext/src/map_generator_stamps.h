#pragma once

#include <godot_cpp/classes/image_texture.hpp>
#include "map_generator.h"

using namespace godot;

class MapGenerator_Stamps {
public:
    MapGenerator_Stamps(Vector2i size, const PackedByteArray& biome_bitmap, const TypedArray<MapStampConfig> stamp_configs,
        Ref<MapSpritePlacer> placer, const std::mt19937& rng, bool use_legacy_distribution)
        : size(size), biome_bitmap(biome_bitmap), stamp_configs(stamp_configs),
          placer(placer), rng(rng), use_legacy_distribution(use_legacy_distribution) {}

    TypedArray<MapSpritePlacement> generate();

private:
    const Vector2i size;
    const PackedByteArray biome_bitmap;
    const TypedArray<MapStampConfig> stamp_configs;
    Ref<MapSpritePlacer> placer;
    const bool use_legacy_distribution;
    std::mt19937 rng;

    std::vector<std::pair<Ref<MapStampConfig>, Vector2>> choose_stamp_centers();
};
