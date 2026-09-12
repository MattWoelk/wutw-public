#include "generated_map.h"

using namespace godot;

void MapPath::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_points", "points"), &MapPath::set_points);
    ClassDB::bind_method(D_METHOD("get_points"), &MapPath::get_points);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "points", PROPERTY_HINT_ARRAY_TYPE, "Vector2"), "set_points", "get_points");
}

void GeneratedMap::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_size", "size"), &GeneratedMap::set_size);
    ClassDB::bind_method(D_METHOD("get_size"), &GeneratedMap::get_size);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "size"), "set_size", "get_size");

    ClassDB::bind_method(D_METHOD("set_biome_bitmap", "biome_bitmap"), &GeneratedMap::set_biome_bitmap);
    ClassDB::bind_method(D_METHOD("get_biome_bitmap"), &GeneratedMap::get_biome_bitmap);
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_BYTE_ARRAY, "biome_bitmap"), "set_biome_bitmap", "get_biome_bitmap");

    ClassDB::bind_method(D_METHOD("set_raw_biome_sdfs", "raw_biome_sdfs"), &GeneratedMap::set_raw_biome_sdfs);
    ClassDB::bind_method(D_METHOD("get_raw_biome_sdfs"), &GeneratedMap::get_raw_biome_sdfs);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "raw_biome_sdfs", PROPERTY_HINT_ARRAY_TYPE, "PackedByteArray"),
                 "set_raw_biome_sdfs", "get_raw_biome_sdfs");

    ClassDB::bind_method(D_METHOD("set_blurred_biome_sdfs", "blurred_biome_sdfs"), &GeneratedMap::set_blurred_biome_sdfs);
    ClassDB::bind_method(D_METHOD("get_blurred_biome_sdfs"), &GeneratedMap::get_blurred_biome_sdfs);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "blurred_biome_sdfs", PROPERTY_HINT_TYPE_STRING,
                              String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":Texture2D"),
                 "set_blurred_biome_sdfs", "get_blurred_biome_sdfs");

    ClassDB::bind_method(D_METHOD("set_clip_mask", "clip_mask"), &GeneratedMap::set_clip_mask);
    ClassDB::bind_method(D_METHOD("get_clip_mask"), &GeneratedMap::get_clip_mask);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "clip_mask", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
        "set_clip_mask", "get_clip_mask");

    ClassDB::bind_method(D_METHOD("set_nonland_sdf", "nonland_sdf"), &GeneratedMap::set_nonland_sdf);
    ClassDB::bind_method(D_METHOD("get_nonland_sdf"), &GeneratedMap::get_nonland_sdf);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "nonland_sdf", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
        "set_nonland_sdf", "get_nonland_sdf");

    ClassDB::bind_method(D_METHOD("set_shard_base_texture", "shard_base_texture"), &GeneratedMap::set_shard_base_texture);
    ClassDB::bind_method(D_METHOD("get_shard_base_texture"), &GeneratedMap::get_shard_base_texture);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "shard_base_texture", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
                 "set_shard_base_texture", "get_shard_base_texture");

    ClassDB::bind_method(D_METHOD("set_distance_to_land_texture", "distance_to_land_texture"), &GeneratedMap::set_distance_to_land_texture);
    ClassDB::bind_method(D_METHOD("get_distance_to_land_texture"), &GeneratedMap::get_distance_to_land_texture);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "distance_to_land_texture", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
                 "set_distance_to_land_texture", "get_distance_to_land_texture");

    ClassDB::bind_method(D_METHOD("set_land_depth_texture", "land_depth_texture"), &GeneratedMap::set_land_depth_texture);
    ClassDB::bind_method(D_METHOD("get_land_depth_texture"), &GeneratedMap::get_land_depth_texture);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "land_depth_texture", PROPERTY_HINT_RESOURCE_TYPE, "Texture2D"),
                 "set_land_depth_texture", "get_land_depth_texture");

    ClassDB::bind_method(D_METHOD("set_starting_point", "starting_point"), &GeneratedMap::set_starting_point);
    ClassDB::bind_method(D_METHOD("get_starting_point"), &GeneratedMap::get_starting_point);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2I, "starting_point"), "set_starting_point", "get_starting_point");

    ClassDB::bind_method(D_METHOD("set_edge_cloud_points", "edge_cloud_points"), &GeneratedMap::set_edge_cloud_points);
    ClassDB::bind_method(D_METHOD("get_edge_cloud_points"), &GeneratedMap::get_edge_cloud_points);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "edge_cloud_points", PROPERTY_HINT_ARRAY_TYPE, "Vector2"),
                 "set_edge_cloud_points", "get_edge_cloud_points");

    ClassDB::bind_method(D_METHOD("set_sprites", "sprites"), &GeneratedMap::set_sprites);
    ClassDB::bind_method(D_METHOD("get_sprites"), &GeneratedMap::get_sprites);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "sprites", PROPERTY_HINT_TYPE_STRING,
                              String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpritePlacement"),
                 "set_sprites", "get_sprites");

    ClassDB::bind_method(D_METHOD("set_sprites_quad_tree", "sprites_quad_tree"), &GeneratedMap::set_sprites_quad_tree);
    ClassDB::bind_method(D_METHOD("get_sprites_quad_tree"), &GeneratedMap::get_sprites_quad_tree);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sprites_quad_tree", PROPERTY_HINT_RESOURCE_TYPE, "QuadTree"),
                 "set_sprites_quad_tree", "get_sprites_quad_tree");

    ClassDB::bind_method(D_METHOD("set_sprite_placer", "sprite_placer"), &GeneratedMap::set_sprite_placer);
    ClassDB::bind_method(D_METHOD("get_sprite_placer"), &GeneratedMap::get_sprite_placer);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sprite_placer", PROPERTY_HINT_RESOURCE_TYPE, "MapSpritePlacer"),
        "set_sprite_placer", "get_sprite_placer");

    ClassDB::bind_method(D_METHOD("set_road_creator", "road_creator"), &GeneratedMap::set_road_creator);
    ClassDB::bind_method(D_METHOD("get_road_creator"), &GeneratedMap::get_road_creator);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "road_creator", PROPERTY_HINT_RESOURCE_TYPE, "RoadCreator"),
        "set_road_creator", "get_road_creator");
}
