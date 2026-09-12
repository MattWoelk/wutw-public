#pragma once

#include "map_generator.h"

using namespace godot;

class MapGenerator_Basemap {
public:
    MapGenerator_Basemap(Vector2i size,
                         const Ref<MapBiomeConfig> biome_config,
                         const Ref<MapInputTextures> input_textures,
                         const Ref<MapBaseConfig> basemap_config,
                         const std::mt19937& rng,
                         int despeckle_max_tiles,
                         bool use_legacy_distribution)
        : size(size), biome_config(biome_config), input_textures(input_textures),
          basemap_config(basemap_config), rng(rng), despeckle_max_tiles(despeckle_max_tiles),
          use_legacy_distribution(use_legacy_distribution) {}

    PackedByteArray generate();

private:
    const Vector2i size;
    const Ref<MapBiomeConfig> biome_config;
    const Ref<MapInputTextures> input_textures;
    const Ref<MapBaseConfig> basemap_config;
    const int despeckle_max_tiles;
    const bool use_legacy_distribution;
    std::mt19937 rng;

    Ref<Image> mask_image;
    Ref<Image> altitude_image;
    Ref<FastNoiseLite> noise_mask;
    Ref<FastNoiseLite> noise_altitude;
    Ref<FastNoiseLite> noise_moisture;
    Ref<FastNoiseLite> noise_temperature;

    PackedByteArray biome_bitmap;

    void despeckle();
    float sample_mask(int x, int y) const;
    float sample_altitude(int x, int y) const;
    float sample_moisture(int x, int y) const;
    float sample_temperature(int x, int y) const;
    Biome sample_biome(int x, int y) const;
    void set_biome(int x, int y, Biome biome);
    bool can_place_forest(Biome biome) const;
    bool can_place_swamp(Biome biome) const;
};
