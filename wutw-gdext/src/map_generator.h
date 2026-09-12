#pragma once

#include <random>
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/thread.hpp>
#include <godot_cpp/classes/image_texture.hpp>

#include "map_generation_config.h"
#include "generated_map.h"
#include "map_generator_shard_base.h"
#include "map_sprite_placer.h"

using namespace godot;

class MapGenerator : public Node {
    GDCLASS(MapGenerator, Node)

public:
    MapGenerator() = default;
    ~MapGenerator() = default;

    Ref<GeneratedMap> generate(const Ref<MapGenerationConfig>& config, const int seed, bool use_legacy_distribution = false);

protected:
    static void _bind_methods();

private:
    // Input state (const during generation).
    Ref<MapGenerationConfig> config;
    PackedByteArray mask_bitmap;
    PackedByteArray altitude_bitmap;

    // Internal state.
    std::mt19937 rng;
    bool use_legacy_distribution;
    Ref<MapBaseConfig> basemap_config;
    Ref<QuadTree> quad_tree;
    Ref<MapSpritePlacer> placer;

    // Output state.
    Ref<GeneratedMap> generated_map;
    PackedByteArray biome_bitmap;
    TypedArray<PackedByteArray> raw_sdfs;
    TypedArray<PackedByteArray> blurred_sdfs;
    PackedByteArray nonland_sdf;
    TypedArray<ImageTexture> blurred_sdf_textures;
    Ref<ImageTexture> clip_mask_texture;
    TypedArray<MapSpritePlacement> sprite_placements;
    std::vector<MapGenerator_ShardBase::OutlineSection> shard_outline_sections;
    Ref<Image> shard_base_image;
    Ref<ImageTexture> distance_to_land_sdf;
    Ref<ImageTexture> land_depth_texture;
    TypedArray<Vector2> edge_cloud_points;

    void _generate_sdf(Biome biome);
    void _generate_clip();
    void _generate_sprites();
    void _generate_shard_base_image();
    void _generate_distance_to_land();
    void _generate_land_depth();
};
