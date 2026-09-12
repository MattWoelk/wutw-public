#include "map_generation_config.h"

using namespace godot;

void MapBiomeConfig::_bind_methods() {
#define BIND_MAPBIOMECONFIG_FLOAT(name) \
    ClassDB::bind_method(D_METHOD("set_" #name, #name), &MapBiomeConfig::set_##name); \
    ClassDB::bind_method(D_METHOD("get_" #name), &MapBiomeConfig::get_##name); \
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, #name), "set_" #name, "get_" #name);

    BIND_MAPBIOMECONFIG_FLOAT(min_mask_for_land)
    BIND_MAPBIOMECONFIG_FLOAT(max_altitude_for_sea)
    BIND_MAPBIOMECONFIG_FLOAT(max_moisture_for_dry_biome)
    BIND_MAPBIOMECONFIG_FLOAT(min_temperature_for_desert)
    BIND_MAPBIOMECONFIG_FLOAT(max_moisture_for_brushland)
    BIND_MAPBIOMECONFIG_FLOAT(max_temperature_for_brushland)
    BIND_MAPBIOMECONFIG_FLOAT(max_moisture_for_steppe)
    BIND_MAPBIOMECONFIG_FLOAT(max_temperature_for_steppe)
    BIND_MAPBIOMECONFIG_FLOAT(min_altitude_for_seashore)
    BIND_MAPBIOMECONFIG_FLOAT(min_altitude_for_mountain)
    BIND_MAPBIOMECONFIG_FLOAT(min_moisture_for_swamp)
    BIND_MAPBIOMECONFIG_FLOAT(max_altitude_for_swamp)
    BIND_MAPBIOMECONFIG_FLOAT(min_moisture_for_forest)
#undef BIND_MAPBIOMECONFIG_FLOAT
}

void MapBaseConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_texture_mask", "texture_mask"), &MapBaseConfig::set_texture_mask);
    ClassDB::bind_method(D_METHOD("get_texture_mask"), &MapBaseConfig::get_texture_mask);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "texture_mask", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
                 "set_texture_mask", "get_texture_mask");

    ClassDB::bind_method(D_METHOD("set_texture_altitude", "texture_altitude"), &MapBaseConfig::set_texture_altitude);
    ClassDB::bind_method(D_METHOD("get_texture_altitude"), &MapBaseConfig::get_texture_altitude);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::DICTIONARY,
            "texture_altitude",
            PROPERTY_HINT_TYPE_STRING,
            "{" +
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":Texture2D" +
            + ";" +
            "float"
        ),
        "set_texture_altitude",
        "get_texture_altitude"
    );

    ClassDB::bind_method(D_METHOD("set_starting_point", "starting_point"), &MapBaseConfig::set_starting_point);
    ClassDB::bind_method(D_METHOD("get_starting_point"), &MapBaseConfig::get_starting_point);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "starting_point"), "set_starting_point", "get_starting_point");

    ClassDB::bind_method(D_METHOD("set_altitude_skew_curve", "altitude_skew_curve"), &MapBaseConfig::set_altitude_skew_curve);
    ClassDB::bind_method(D_METHOD("get_altitude_skew_curve"), &MapBaseConfig::get_altitude_skew_curve);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "altitude_skew_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_altitude_skew_curve", "get_altitude_skew_curve");
}

void MapInputTextures::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_basemap_configs", "basemap_configs"), &MapInputTextures::set_basemap_configs);
    ClassDB::bind_method(D_METHOD("get_basemap_configs"), &MapInputTextures::get_basemap_configs);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "basemap_configs",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapBaseConfig"
        ),
        "set_basemap_configs",
        "get_basemap_configs"
    );

    ClassDB::bind_method(D_METHOD("set_noise_mask", "noise_mask"), &MapInputTextures::set_noise_mask);
    ClassDB::bind_method(D_METHOD("get_noise_mask"), &MapInputTextures::get_noise_mask);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "noise_mask", PROPERTY_HINT_RESOURCE_TYPE, "FastNoiseLite"), "set_noise_mask", "get_noise_mask");

    ClassDB::bind_method(D_METHOD("set_noise_altitude", "noise_altitude"), &MapInputTextures::set_noise_altitude);
    ClassDB::bind_method(D_METHOD("get_noise_altitude"), &MapInputTextures::get_noise_altitude);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "noise_altitude", PROPERTY_HINT_RESOURCE_TYPE, "FastNoiseLite"), "set_noise_altitude", "get_noise_altitude");

    ClassDB::bind_method(D_METHOD("set_noise_moisture", "noise_moisture"), &MapInputTextures::set_noise_moisture);
    ClassDB::bind_method(D_METHOD("get_noise_moisture"), &MapInputTextures::get_noise_moisture);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "noise_moisture", PROPERTY_HINT_RESOURCE_TYPE, "FastNoiseLite"), "set_noise_moisture", "get_noise_moisture");

    ClassDB::bind_method(D_METHOD("set_noise_temperature", "noise_temperature"), &MapInputTextures::set_noise_temperature);
    ClassDB::bind_method(D_METHOD("get_noise_temperature"), &MapInputTextures::get_noise_temperature);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "noise_temperature", PROPERTY_HINT_RESOURCE_TYPE, "FastNoiseLite"), "set_noise_temperature", "get_noise_temperature");

    ClassDB::bind_method(D_METHOD("set_noise_frequency", "noise_frequency"), &MapInputTextures::set_noise_frequency);
    ClassDB::bind_method(D_METHOD("get_noise_frequency"), &MapInputTextures::get_noise_frequency);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "noise_frequency"), "set_noise_frequency", "get_noise_frequency");
}

void MapShardBottomConfig::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_cliff_curve", "cliff_curve"), &MapShardBottomConfig::set_cliff_curve);
    ClassDB::bind_method(D_METHOD("get_cliff_curve"), &MapShardBottomConfig::get_cliff_curve);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "cliff_curve", PROPERTY_HINT_RESOURCE_TYPE, "Curve"), "set_cliff_curve", "get_cliff_curve");

    ClassDB::bind_method(D_METHOD("set_resolution_multiplier", "resolution_multiplier"), &MapShardBottomConfig::set_resolution_multiplier);
    ClassDB::bind_method(D_METHOD("get_resolution_multiplier"), &MapShardBottomConfig::get_resolution_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "resolution_multiplier"), "set_resolution_multiplier", "get_resolution_multiplier");

    ClassDB::bind_method(D_METHOD("set_height_above_clouds", "height_above_clouds"), &MapShardBottomConfig::set_height_above_clouds);
    ClassDB::bind_method(D_METHOD("get_height_above_clouds"), &MapShardBottomConfig::get_height_above_clouds);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "height_above_clouds"), "set_height_above_clouds", "get_height_above_clouds");

    ClassDB::bind_method(D_METHOD("set_edge_cloud_spacing", "edge_cloud_spacing"), &MapShardBottomConfig::set_edge_cloud_spacing);
    ClassDB::bind_method(D_METHOD("get_edge_cloud_spacing"), &MapShardBottomConfig::get_edge_cloud_spacing);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "edge_cloud_spacing"), "set_edge_cloud_spacing", "get_edge_cloud_spacing");
}

void MapStampConfig::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_comment", "comment"), &MapStampConfig::set_comment);
    ClassDB::bind_method(D_METHOD("get_comment"), &MapStampConfig::get_comment);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "comment"), "set_comment", "get_comment");
    
    ClassDB::bind_method(D_METHOD("set_stamp_count_range", "stamp_count_range"), &MapStampConfig::set_stamp_count_range);
    ClassDB::bind_method(D_METHOD("get_stamp_count_range"), &MapStampConfig::get_stamp_count_range);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "stamp_count_range"), "set_stamp_count_range", "get_stamp_count_range");

    ClassDB::bind_method(D_METHOD("set_radius", "radius"), &MapStampConfig::set_radius);
    ClassDB::bind_method(D_METHOD("get_radius"), &MapStampConfig::get_radius);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "radius"), "set_radius", "get_radius");

    ClassDB::bind_method(D_METHOD("set_allowed_biomes", "allowed_biomes"), &MapStampConfig::set_allowed_biomes);
    ClassDB::bind_method(D_METHOD("get_allowed_biomes"), &MapStampConfig::get_allowed_biomes);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "allowed_biomes",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::INT) + "/" + String::num(PROPERTY_HINT_ENUM) + ":CLOUDS,SEA,DESERT,WASTELAND,SWAMP,STEPPE,PLAINS,MOUNTAIN,BRUSHLAND,FOREST,SEASHORE"
        ),
        "set_allowed_biomes",
        "get_allowed_biomes"
    );

    ClassDB::bind_method(D_METHOD("set_sprite_types", "sprite_types"), &MapStampConfig::set_sprite_types);
    ClassDB::bind_method(D_METHOD("get_sprite_types"), &MapStampConfig::get_sprite_types);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "sprite_types",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType"
        ),
        "set_sprite_types",
        "get_sprite_types"
    );


    ClassDB::bind_method(D_METHOD("set_seed_sprite_type", "seed_sprite_type"), &MapStampConfig::set_seed_sprite_type);
    ClassDB::bind_method(D_METHOD("get_seed_sprite_type"), &MapStampConfig::get_seed_sprite_type);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "seed_sprite_type", PROPERTY_HINT_RESOURCE_TYPE, "MapSpriteType"), "set_seed_sprite_type", "get_seed_sprite_type");

    ClassDB::bind_method(D_METHOD("set_sprite_count_range", "sprite_count_range"), &MapStampConfig::set_sprite_count_range);
    ClassDB::bind_method(D_METHOD("get_sprite_count_range"), &MapStampConfig::get_sprite_count_range);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "sprite_count_range"), "set_sprite_count_range", "get_sprite_count_range");

    ClassDB::bind_method(D_METHOD("set_sprite_clumping_factor", "sprite_clumping_factor"), &MapStampConfig::set_sprite_clumping_factor);
    ClassDB::bind_method(D_METHOD("get_sprite_clumping_factor"), &MapStampConfig::get_sprite_clumping_factor);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sprite_clumping_factor"), "set_sprite_clumping_factor", "get_sprite_clumping_factor");

    ClassDB::bind_method(D_METHOD("set_sprite_spacing_multiplier", "sprite_spacing_multiplier"), &MapStampConfig::set_sprite_spacing_multiplier);
    ClassDB::bind_method(D_METHOD("get_sprite_spacing_multiplier"), &MapStampConfig::get_sprite_spacing_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sprite_spacing_multiplier"), "set_sprite_spacing_multiplier", "get_sprite_spacing_multiplier");
}

void MapRiverConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_origin_mountain_sprites", "origin_mountain_sprites"), &MapRiverConfig::set_origin_mountain_sprites);
    ClassDB::bind_method(D_METHOD("get_origin_mountain_sprites"), &MapRiverConfig::get_origin_mountain_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "origin_mountain_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType"
        ),
        "set_origin_mountain_sprites",
        "get_origin_mountain_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_origin_sprites", "origin_sprites"), &MapRiverConfig::set_origin_sprites);
    ClassDB::bind_method(D_METHOD("get_origin_sprites"), &MapRiverConfig::get_origin_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "origin_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType_River"
        ),
        "set_origin_sprites",
        "get_origin_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_from_north_sprites", "from_north_sprites"), &MapRiverConfig::set_from_north_sprites);
    ClassDB::bind_method(D_METHOD("get_from_north_sprites"), &MapRiverConfig::get_from_north_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "from_north_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType_River"
        ),
        "set_from_north_sprites",
        "get_from_north_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_from_east_sprites", "from_east_sprites"), &MapRiverConfig::set_from_east_sprites);
    ClassDB::bind_method(D_METHOD("get_from_east_sprites"), &MapRiverConfig::get_from_east_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "from_east_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType_River"
        ),
        "set_from_east_sprites",
        "get_from_east_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_from_south_sprites", "from_south_sprites"), &MapRiverConfig::set_from_south_sprites);
    ClassDB::bind_method(D_METHOD("get_from_south_sprites"), &MapRiverConfig::get_from_south_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "from_south_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType_River"
        ),
        "set_from_south_sprites",
        "get_from_south_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_from_west_sprites", "from_west_sprites"), &MapRiverConfig::set_from_west_sprites);
    ClassDB::bind_method(D_METHOD("get_from_west_sprites"), &MapRiverConfig::get_from_west_sprites);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "from_west_sprites",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType_River"
        ),
        "set_from_west_sprites",
        "get_from_west_sprites"
    );

    ClassDB::bind_method(D_METHOD("set_waterfall_sprite", "waterfall_sprite"), &MapRiverConfig::set_waterfall_sprite);
    ClassDB::bind_method(D_METHOD("get_waterfall_sprite"), &MapRiverConfig::get_waterfall_sprite);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "waterfall_sprite", PROPERTY_HINT_RESOURCE_TYPE, "MapSpriteType"), "set_waterfall_sprite", "get_waterfall_sprite");

    ClassDB::bind_method(D_METHOD("set_sprite_size", "sprite_size"), &MapRiverConfig::set_sprite_size);
    ClassDB::bind_method(D_METHOD("get_sprite_size"), &MapRiverConfig::get_sprite_size);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "sprite_size"), "set_sprite_size", "get_sprite_size");

    ClassDB::bind_method(D_METHOD("set_min_length", "min_length"), &MapRiverConfig::set_min_length);
    ClassDB::bind_method(D_METHOD("get_min_length"), &MapRiverConfig::get_min_length);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "min_length"), "set_min_length", "get_min_length");

    ClassDB::bind_method(D_METHOD("set_min_good_length", "min_good_length"), &MapRiverConfig::set_min_good_length);
    ClassDB::bind_method(D_METHOD("get_min_good_length"), &MapRiverConfig::get_min_good_length);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "min_good_length"), "set_min_good_length", "get_min_good_length");

    ClassDB::bind_method(D_METHOD("set_max_good_length", "max_good_length"), &MapRiverConfig::set_max_good_length);
    ClassDB::bind_method(D_METHOD("get_max_good_length"), &MapRiverConfig::get_max_good_length);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "max_good_length"), "set_max_good_length", "get_max_good_length");
}

Ref<MapSpriteType_River> MapRiverConfig::get_sprite_type(Direction from, Direction to) {
    // Helper to get the correct sprite array and index based on direction.
    // Each array is expected to have 3 elements, order as per comment in header.
    int index = -1;
    TypedArray<MapSpriteType_River>* sprites = nullptr;
    switch (from) {
    case Direction::ORIGIN:
        sprites = &origin_sprites;
        // EAST, SOUTH, WEST, NORTH
        if (to == Direction::EAST) index = 0;
        else if (to == Direction::SOUTH) index = 1;
        else if (to == Direction::WEST) index = 2;
        else if (to == Direction::NORTH) index = 3;
        break;
    case Direction::NORTH:
        sprites = &from_north_sprites;
        // EAST, SOUTH, WEST
        if (to == Direction::EAST) index = 0;
        else if (to == Direction::SOUTH) index = 1;
        else if (to == Direction::WEST) index = 2;
        break;
    case Direction::EAST:
        sprites = &from_east_sprites;
        // SOUTH, WEST, NORTH
        if (to == Direction::SOUTH) index = 0;
        else if (to == Direction::WEST) index = 1;
        else if (to == Direction::NORTH) index = 2;
        break;
    case Direction::SOUTH:
        sprites = &from_south_sprites;
        // EAST, NORTH, WEST
        if (to == Direction::EAST) index = 0;
        else if (to == Direction::NORTH) index = 1;
        else if (to == Direction::WEST) index = 2;
        break;
    case Direction::WEST:
        sprites = &from_west_sprites;
        // NORTH, EAST, SOUTH
        if (to == Direction::NORTH) index = 0;
        else if (to == Direction::EAST) index = 1;
        else if (to == Direction::SOUTH) index = 2;
        break;
    }
    if (sprites && index >= 0 && index < sprites->size()) {
        return (*sprites)[index];
    }
    return nullptr;
}

Ref<MapSpriteType> MapRiverConfig::get_origin_mountain_sprite(Direction to)
{
    switch (to) {
    case Direction::NORTH:
        return origin_mountain_sprites[0];
    case Direction::EAST:
        return origin_mountain_sprites[1];
    case Direction::SOUTH:
        return origin_mountain_sprites[2];
    case Direction::WEST:
        return origin_mountain_sprites[3];
    default:
        return Ref<MapSpriteType>();
    }
}

void MapGenerationConfig::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_size", "size"), &MapGenerationConfig::set_size);
    ClassDB::bind_method(D_METHOD("get_size"), &MapGenerationConfig::get_size);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "size"), "set_size", "get_size");

    ClassDB::bind_method(D_METHOD("set_despeckle_max_tiles", "despeckle_max_tiles"), &MapGenerationConfig::set_despeckle_max_tiles);
    ClassDB::bind_method(D_METHOD("get_despeckle_max_tiles"), &MapGenerationConfig::get_despeckle_max_tiles);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "despeckle_max_tiles"), "set_despeckle_max_tiles", "get_despeckle_max_tiles");

    ClassDB::bind_method(D_METHOD("set_sdf_max_distance", "sdf_max_distance"), &MapGenerationConfig::set_sdf_max_distance);
    ClassDB::bind_method(D_METHOD("get_sdf_max_distance"), &MapGenerationConfig::get_sdf_max_distance);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "sdf_max_distance"), "set_sdf_max_distance", "get_sdf_max_distance");

    ClassDB::bind_method(D_METHOD("set_sdf_blur_radius", "sdf_blur_radius"), &MapGenerationConfig::set_sdf_blur_radius);
    ClassDB::bind_method(D_METHOD("get_sdf_blur_radius"), &MapGenerationConfig::get_sdf_blur_radius);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "sdf_blur_radius"), "set_sdf_blur_radius", "get_sdf_blur_radius");

    ClassDB::bind_method(D_METHOD("set_clip_width", "clip_width"), &MapGenerationConfig::set_clip_width);
    ClassDB::bind_method(D_METHOD("get_clip_width"), &MapGenerationConfig::get_clip_width);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "clip_width"), "set_clip_width", "get_clip_width");

    ClassDB::bind_method(D_METHOD("set_clip_resolution_multiplier", "clip_resolution_multiplier"), &MapGenerationConfig::set_clip_resolution_multiplier);
    ClassDB::bind_method(D_METHOD("get_clip_resolution_multiplier"), &MapGenerationConfig::get_clip_resolution_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "clip_resolution_multiplier"), "set_clip_resolution_multiplier", "get_clip_resolution_multiplier");

    ClassDB::bind_method(D_METHOD("set_input_textures", "input_textures"), &MapGenerationConfig::set_input_textures);
    ClassDB::bind_method(D_METHOD("get_input_textures"), &MapGenerationConfig::get_input_textures);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "input_textures", PROPERTY_HINT_RESOURCE_TYPE, "MapInputTextures"), "set_input_textures", "get_input_textures");

    ClassDB::bind_method(D_METHOD("set_shard_bottom_config", "shard_bottom_config"), &MapGenerationConfig::set_shard_bottom_config);
    ClassDB::bind_method(D_METHOD("get_shard_bottom_config"), &MapGenerationConfig::get_shard_bottom_config);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "shard_bottom_config", PROPERTY_HINT_RESOURCE_TYPE, "MapShardBottomConfig"), "set_shard_bottom_config", "get_shard_bottom_config");

    ClassDB::bind_method(D_METHOD("set_stamp_configs", "stamp_configs"), &MapGenerationConfig::set_stamp_configs);
    ClassDB::bind_method(D_METHOD("get_stamp_configs"), &MapGenerationConfig::get_stamp_configs);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "stamp_configs",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapStampConfig"
        ),
        "set_stamp_configs",
        "get_stamp_configs"
    );

    ClassDB::bind_method(D_METHOD("set_river_config", "river_config"), &MapGenerationConfig::set_river_config);
    ClassDB::bind_method(D_METHOD("get_river_config"), &MapGenerationConfig::get_river_config);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "river_config", PROPERTY_HINT_RESOURCE_TYPE, "MapRiverConfig"), "set_river_config", "get_river_config");

    ClassDB::bind_method(D_METHOD("set_torii_sprite", "river_config"), &MapGenerationConfig::set_torii_sprite);
    ClassDB::bind_method(D_METHOD("get_torii_sprite"), &MapGenerationConfig::get_torii_sprite);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "torii_sprite", PROPERTY_HINT_RESOURCE_TYPE, "MapSpriteType"), "set_torii_sprite", "get_torii_sprite");
    
    ClassDB::bind_method(D_METHOD("set_biome_sprite_configs", "biome_sprite_configs"), &MapGenerationConfig::set_biome_sprite_configs);
    ClassDB::bind_method(D_METHOD("get_biome_sprite_configs"), &MapGenerationConfig::get_biome_sprite_configs);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::DICTIONARY,
            "biome_sprite_configs",
            PROPERTY_HINT_TYPE_STRING,
            "{" +
            String::num(Variant::INT) + "/" + String::num(PROPERTY_HINT_ENUM) + ":CLOUDS,SEA,DESERT,WASTELAND,SWAMP,STEPPE,PLAINS,MOUNTAIN,BRUSHLAND,FOREST,SEASHORE"
            + ";" +
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpritePlacerConfig"
        ),
        "set_biome_sprite_configs",
        "get_biome_sprite_configs"
    );

    ClassDB::bind_method(D_METHOD("set_sprite_dupe_decay", "sprite_dupe_decay"), &MapGenerationConfig::set_sprite_dupe_decay);
    ClassDB::bind_method(D_METHOD("get_sprite_dupe_decay"), &MapGenerationConfig::get_sprite_dupe_decay);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "sprite_dupe_decay"), "set_sprite_dupe_decay", "get_sprite_dupe_decay");

    ClassDB::bind_method(D_METHOD("set_biome_config", "biome_config"), &MapGenerationConfig::set_biome_config);
    ClassDB::bind_method(D_METHOD("get_biome_config"), &MapGenerationConfig::get_biome_config);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "biome_config", PROPERTY_HINT_RESOURCE_TYPE, "MapBiomeConfig"), "set_biome_config", "get_biome_config");
}
