#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/classes/fast_noise_lite.hpp>
#include <godot_cpp/variant/typed_dictionary.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include "map_sprite_type.h"
#include "map_biomes.h"
#include "map_sprite_type_river.h"

using namespace godot;

class MapBiomeConfig : public Resource {
    GDCLASS(MapBiomeConfig, Resource)

private:
    float min_mask_for_land = 0.5;
    float max_altitude_for_sea = 0.5;
    float max_moisture_for_dry_biome = 0.3;
    float min_temperature_for_desert = 0.5;
    float max_moisture_for_brushland = 0.4;
    float max_temperature_for_brushland = 0.6;
    float max_moisture_for_steppe =0.6;
    float max_temperature_for_steppe = 0.7;
    float min_altitude_for_seashore = 0.4;
    float min_altitude_for_mountain = 0.9;
    float min_moisture_for_swamp = 0.7;
    float max_altitude_for_swamp = 0.7;
    float min_moisture_for_forest = 0.65;

protected:
    static void _bind_methods();

public:
    void set_min_mask_for_land(float v) { min_mask_for_land = v; }
    float get_min_mask_for_land() const { return min_mask_for_land; }

    void set_max_altitude_for_sea(float v) { max_altitude_for_sea = v; }
    float get_max_altitude_for_sea() const { return max_altitude_for_sea; }

    void set_max_moisture_for_dry_biome(float v) { max_moisture_for_dry_biome = v; }
    float get_max_moisture_for_dry_biome() const { return max_moisture_for_dry_biome; }

    void set_min_temperature_for_desert(float v) { min_temperature_for_desert = v; }
    float get_min_temperature_for_desert() const { return min_temperature_for_desert; }

    void set_max_moisture_for_brushland(float v) { max_moisture_for_brushland = v; }
    float get_max_moisture_for_brushland() const { return max_moisture_for_brushland; }

    void set_max_temperature_for_brushland(float v) { max_temperature_for_brushland = v; }
    float get_max_temperature_for_brushland() const { return max_temperature_for_brushland; }

    void set_max_moisture_for_steppe(float v) { max_moisture_for_steppe = v; }
    float get_max_moisture_for_steppe() const { return max_moisture_for_steppe; }

    void set_max_temperature_for_steppe(float v) { max_temperature_for_steppe = v; }
    float get_max_temperature_for_steppe() const { return max_temperature_for_steppe; }

    void set_min_altitude_for_seashore(float v) { min_altitude_for_seashore = v; }
    float get_min_altitude_for_seashore() const { return min_altitude_for_seashore; }

    void set_min_altitude_for_mountain(float v) { min_altitude_for_mountain = v; }
    float get_min_altitude_for_mountain() const { return min_altitude_for_mountain; }

    void set_min_moisture_for_swamp(float v) { min_moisture_for_swamp = v; }
    float get_min_moisture_for_swamp() const { return min_moisture_for_swamp; }

    void set_max_altitude_for_swamp(float v) { max_altitude_for_swamp = v; }
    float get_max_altitude_for_swamp() const { return max_altitude_for_swamp; }

    void set_min_moisture_for_forest(float v) { min_moisture_for_forest = v; }
    float get_min_moisture_for_forest() const { return min_moisture_for_forest; }
};

class MapBaseConfig : public Resource {
    GDCLASS(MapBaseConfig, Resource)

private:
    Ref<Texture2D> texture_mask;
    TypedDictionary<Texture2D, float> texture_altitude;
    Vector2i starting_point = Vector2i(50, 200);
    Ref<Curve> altitude_skew_curve;

protected:
    static void _bind_methods();

public:
    void set_texture_mask(const Ref<Texture2D>& p) { texture_mask = p; }
    Ref<Texture2D> get_texture_mask() const { return texture_mask; }

    void set_texture_altitude(const TypedDictionary<Texture2D, float>& p) { texture_altitude = p; }
    TypedDictionary<Texture2D, float> get_texture_altitude() const { return texture_altitude; }

    void set_starting_point(const Vector2i& p) { starting_point = p; }
    Vector2i get_starting_point() const { return starting_point; }

    void set_altitude_skew_curve(const Ref<Curve>& p) { altitude_skew_curve = p; }
    Ref<Curve> get_altitude_skew_curve() const { return altitude_skew_curve; }
};

class MapInputTextures : public Resource {
    GDCLASS(MapInputTextures, Resource)

private:
    TypedArray<MapBaseConfig> basemap_configs;
    Ref<FastNoiseLite> noise_mask;
    Ref<FastNoiseLite> noise_altitude;
    Ref<FastNoiseLite> noise_moisture;
    Ref<FastNoiseLite> noise_temperature;
    float noise_frequency = 5.0f;

protected:
    static void _bind_methods();

public:
    void set_noise_frequency(float p) { noise_frequency = p; }
    float get_noise_frequency() const { return noise_frequency; }

    void set_basemap_configs(const TypedArray<MapBaseConfig>& p) { basemap_configs = p; }
    TypedArray<MapBaseConfig> get_basemap_configs() const { return basemap_configs; }

    void set_noise_mask(const Ref<FastNoiseLite>& p) { noise_mask = p; }
    Ref<FastNoiseLite> get_noise_mask() const { return noise_mask; }

    void set_noise_altitude(const Ref<FastNoiseLite>& p) { noise_altitude = p; }
    Ref<FastNoiseLite> get_noise_altitude() const { return noise_altitude; }

    void set_noise_moisture(const Ref<FastNoiseLite>& p) { noise_moisture = p; }
    Ref<FastNoiseLite> get_noise_moisture() const { return noise_moisture; }

    void set_noise_temperature(const Ref<FastNoiseLite>& p) { noise_temperature = p; }
    Ref<FastNoiseLite> get_noise_temperature() const { return noise_temperature; }
};

class MapShardBottomConfig : public Resource {
    GDCLASS(MapShardBottomConfig, Resource)

private:
    Ref<Curve> cliff_curve;
    int resolution_multiplier = 2;
    int height_above_clouds = 50;
    int edge_cloud_spacing = 15;

protected:
    static void _bind_methods();

public:
    void set_cliff_curve(const Ref<Curve>& p) { cliff_curve = p; }
    Ref<Curve> get_cliff_curve() const { return cliff_curve; }

    void set_resolution_multiplier(int p) { resolution_multiplier = p; }
    int get_resolution_multiplier() const { return resolution_multiplier; }

    void set_height_above_clouds(int p) { height_above_clouds = p; }
    int get_height_above_clouds() const { return height_above_clouds; }

    void set_edge_cloud_spacing(int p) { edge_cloud_spacing = p; }
    int get_edge_cloud_spacing() const { return edge_cloud_spacing; }
};

class MapStampConfig : public Resource {  
    GDCLASS(MapStampConfig, Resource)  

private:
    String comment;

    Vector2i stamp_count_range = Vector2i(0, 3);  
    int radius = 3;
    TypedArray<int> allowed_biomes;  // Really MapBiomes::Biome, but that fails to bind.

    TypedArray<MapSpriteType> sprite_types;
    Ref<MapSpriteType> seed_sprite_type;
    Vector2i sprite_count_range = Vector2i(2, 5);  
    float sprite_clumping_factor = 0.2f;  
    float sprite_spacing_multiplier = 1.0f;  

protected:  
   static void _bind_methods();  

public:
    void set_comment(const String& p) { comment = p; }
    String get_comment() const { return comment; }

    void set_stamp_count_range(const Vector2i& p) { stamp_count_range = p; }
    Vector2i get_stamp_count_range() const { return stamp_count_range; }

    void set_radius(int p) { radius = p; }  
    int get_radius() const { return radius; }  

    void set_allowed_biomes(const TypedArray<int>& p) { allowed_biomes = p; }
    TypedArray<int> get_allowed_biomes() const { return allowed_biomes; }

    void set_sprite_types(const TypedArray<MapSpriteType>& p) { sprite_types = p; }
    TypedArray<MapSpriteType> get_sprite_types() const { return sprite_types; }

    void set_seed_sprite_type(const Ref<MapSpriteType>& p) { seed_sprite_type = p; }
    Ref<MapSpriteType> get_seed_sprite_type() const { return seed_sprite_type; }

    void set_sprite_count_range(const Vector2i& p) { sprite_count_range = p; }  
    Vector2i get_sprite_count_range() const { return sprite_count_range; }  

    void set_sprite_clumping_factor(float p) { sprite_clumping_factor = p; }  
    float get_sprite_clumping_factor() const { return sprite_clumping_factor; }  

    void set_sprite_spacing_multiplier(float p) { sprite_spacing_multiplier = p; }  
    float get_sprite_spacing_multiplier() const { return sprite_spacing_multiplier; }  
};

class MapRiverConfig : public Resource {
    GDCLASS(MapRiverConfig, Resource)

public:
    void set_origin_mountain_sprites(const TypedArray<MapSpriteType>& p) { origin_mountain_sprites = p; }
    TypedArray<MapSpriteType> get_origin_mountain_sprites() const { return origin_mountain_sprites; }
    void set_origin_sprites(const TypedArray<MapSpriteType_River>& p) { origin_sprites = p; }
    TypedArray<MapSpriteType_River> get_origin_sprites() const { return origin_sprites; }
    void set_from_north_sprites(const TypedArray<MapSpriteType_River>& p) { from_north_sprites = p; }
    TypedArray<MapSpriteType_River> get_from_north_sprites() const { return from_north_sprites; }
    void set_from_east_sprites(const TypedArray<MapSpriteType_River>& p) { from_east_sprites = p; }
    TypedArray<MapSpriteType_River> get_from_east_sprites() const { return from_east_sprites; }
    void set_from_south_sprites(const TypedArray<MapSpriteType_River>& p) { from_south_sprites = p; }
    TypedArray<MapSpriteType_River> get_from_south_sprites() const { return from_south_sprites; }
    void set_from_west_sprites(const TypedArray<MapSpriteType_River>& p) { from_west_sprites = p; }
    TypedArray<MapSpriteType_River> get_from_west_sprites() const { return from_west_sprites; }
    void set_waterfall_sprite(const Ref<MapSpriteType_River>& p) { waterfall_sprite = p; }
    Ref<MapSpriteType_River> get_waterfall_sprite() const { return waterfall_sprite; }
    void set_sprite_size(int p) { sprite_size = p; }
    int get_sprite_size() const { return sprite_size; }
    void set_min_length(int p) { min_length = p; }
    int get_min_length() const { return min_length; }
    void set_min_good_length(int p) { min_good_length = p; }
    int get_min_good_length() const { return min_good_length; }
    void set_max_good_length(int p) { max_good_length = p; }
    int get_max_good_length() const { return max_good_length; }

    enum class Direction { ORIGIN, NORTH, EAST, SOUTH, WEST };

    Ref<MapSpriteType_River> get_sprite_type(Direction from, Direction to);
    Ref<MapSpriteType> get_origin_mountain_sprite(Direction to);

protected:
    static void _bind_methods();

private:
    TypedArray<MapSpriteType> origin_mountain_sprites;  // 4: NORTH, EAST, SOUTH, WEST
    TypedArray<MapSpriteType_River> origin_sprites;  // 4: EAST, SOUTH, WEST, NORTH
    TypedArray<MapSpriteType_River> from_north_sprites;  // 3: EAST, SOUTH, WEST
    TypedArray<MapSpriteType_River> from_east_sprites;  // 3: SOUTH, WEST, NORTH
    TypedArray<MapSpriteType_River> from_south_sprites;  // 3: EAST, NORTH, WEST
    TypedArray<MapSpriteType_River> from_west_sprites;  // 3: NORTH, EAST, SOUTH
    Ref<MapSpriteType> waterfall_sprite;
    int sprite_size = 10;
    int min_length = 3;
    int min_good_length = 8;
    int max_good_length = 12;
};

class MapGenerationConfig : public Resource {
    GDCLASS(MapGenerationConfig, Resource)

private:
    Vector2i size = Vector2i(256, 256);
    int despeckle_max_tiles = 9;
    int sdf_max_distance = 50;
    int sdf_blur_radius = 1;
    float clip_width = 5.0f;
    int clip_resolution_multiplier = 2;
    Ref<MapInputTextures> input_textures;
    Ref<MapShardBottomConfig> shard_bottom_config;
    TypedArray<MapStampConfig> stamp_configs;
    Ref<MapRiverConfig> river_config;
    Ref<MapSpriteType> torii_sprite;
    TypedDictionary<int, MapSpritePlacerConfig> biome_sprite_configs;  // Really keyed on Biome, but that doesn't bind.
    float sprite_dupe_decay = 0.8f;
    Ref<MapBiomeConfig> biome_config;

protected:
    static void _bind_methods();

public:
    void set_size(const Vector2i& p) { size = p; }
    Vector2i get_size() const { return size; }

    void set_despeckle_max_tiles(int p) { despeckle_max_tiles = p; }
    int get_despeckle_max_tiles() const { return despeckle_max_tiles; }

    void set_sdf_max_distance(int p) { sdf_max_distance = p; }
    int get_sdf_max_distance() const { return sdf_max_distance; }

    void set_sdf_blur_radius(int p) { sdf_blur_radius = p; }
    int get_sdf_blur_radius() const { return sdf_blur_radius; }

    void set_clip_width(float p) { clip_width = p; }
    float get_clip_width() const { return clip_width; }

    void set_clip_resolution_multiplier(int p) { clip_resolution_multiplier = p; }
    int get_clip_resolution_multiplier() const { return clip_resolution_multiplier; }

    void set_input_textures(const Ref<MapInputTextures>& p) { input_textures = p; }
    Ref<MapInputTextures> get_input_textures() const { return input_textures; }

    void set_shard_bottom_config(const Ref<MapShardBottomConfig>& p) { shard_bottom_config = p; }
    Ref<MapShardBottomConfig> get_shard_bottom_config() const { return shard_bottom_config; }

    void set_stamp_configs(const TypedArray<MapStampConfig>& p) { stamp_configs = p; }
    TypedArray<MapStampConfig> get_stamp_configs() const { return stamp_configs; }

    void set_river_config(const Ref<MapRiverConfig>& p) { river_config = p; }
    Ref<MapRiverConfig> get_river_config() const { return river_config; }

    void set_biome_sprite_configs(const TypedDictionary<int, MapSpritePlacerConfig>& d) { biome_sprite_configs = d; }
    TypedDictionary<int, MapSpritePlacerConfig> get_biome_sprite_configs() const { return biome_sprite_configs; }

    void set_torii_sprite(const Ref<MapSpriteType>& p) { torii_sprite = p; }
    Ref<MapSpriteType> get_torii_sprite() const { return torii_sprite; }

    void set_sprite_dupe_decay(float d) { sprite_dupe_decay = d; }
    float get_sprite_dupe_decay() const { return sprite_dupe_decay; }

    void set_biome_config(const Ref<MapBiomeConfig>& p) { biome_config = p; }
    Ref<MapBiomeConfig> get_biome_config() const { return biome_config; }
};
