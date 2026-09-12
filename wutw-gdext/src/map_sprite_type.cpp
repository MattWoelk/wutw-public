#include "map_sprite_type.h"
#include <utils.h>

void MapEffectAttachment::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_scene", "scene"), &MapEffectAttachment::set_scene);
    ClassDB::bind_method(D_METHOD("get_scene"), &MapEffectAttachment::get_scene);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "scene", PROPERTY_HINT_RESOURCE_TYPE, "PackedScene"), "set_scene", "get_scene");

    ClassDB::bind_method(D_METHOD("set_offset", "offset"), &MapEffectAttachment::set_offset);
    ClassDB::bind_method(D_METHOD("get_offset"), &MapEffectAttachment::get_offset);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "offset"), "set_offset", "get_offset");

    ClassDB::bind_method(D_METHOD("set_scale", "scale"), &MapEffectAttachment::set_scale);
    ClassDB::bind_method(D_METHOD("get_scale"), &MapEffectAttachment::get_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "scale"), "set_scale", "get_scale");
}

bool MapSpriteType::is_canonically_equal(const Ref<MapSpriteType>& other)
{
    if (other.is_null()) {
        return false;
    } else if (other == this) {
        return true;
    } else {
        String this_path = canonical_path_override.is_empty() ? get_path() : canonical_path_override;
        String other_path = other->canonical_path_override.is_empty() ? other->get_path() : other->canonical_path_override;
        return this_path == other_path;
    }
}

void MapSpriteType::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_map_rect", "rect"), &MapSpriteType::set_map_rect);
    ClassDB::bind_method(D_METHOD("get_map_rect"), &MapSpriteType::get_map_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2, "map_rect"), "set_map_rect", "get_map_rect");

    ClassDB::bind_method(D_METHOD("set_footprint_radius", "radius"), &MapSpriteType::set_footprint_radius);
    ClassDB::bind_method(D_METHOD("get_footprint_radius"), &MapSpriteType::get_footprint_radius);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "footprint_radius"), "set_footprint_radius", "get_footprint_radius");

    ClassDB::bind_method(D_METHOD("set_default_scale", "scale"), &MapSpriteType::set_default_scale);
    ClassDB::bind_method(D_METHOD("get_default_scale"), &MapSpriteType::get_default_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "default_scale"), "set_default_scale", "get_default_scale");

    ClassDB::bind_method(D_METHOD("set_min_scale", "scale"), &MapSpriteType::set_min_scale);
    ClassDB::bind_method(D_METHOD("get_min_scale"), &MapSpriteType::get_min_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_scale"), "set_min_scale", "get_min_scale");

    ClassDB::bind_method(D_METHOD("set_priority_multiplier", "multiplier"), &MapSpriteType::set_priority_multiplier);
    ClassDB::bind_method(D_METHOD("get_priority_multiplier"), &MapSpriteType::get_priority_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "priority_multiplier"), "set_priority_multiplier", "get_priority_multiplier");

    ClassDB::bind_method(D_METHOD("set_must_be_fully_within_clip", "must_be_fully_within_clip"), &MapSpriteType::set_must_be_fully_within_clip);
    ClassDB::bind_method(D_METHOD("get_must_be_fully_within_clip"), &MapSpriteType::get_must_be_fully_within_clip);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "must_be_fully_within_clip"), "set_must_be_fully_within_clip", "get_must_be_fully_within_clip");
    
    ClassDB::bind_method(D_METHOD("set_ignore_clip", "ignore_clip"), &MapSpriteType::set_ignore_clip);
    ClassDB::bind_method(D_METHOD("get_ignore_clip"), &MapSpriteType::get_ignore_clip);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "ignore_clip"), "set_ignore_clip", "get_ignore_clip");

    ClassDB::bind_method(D_METHOD("set_z_index", "z_index"), &MapSpriteType::set_z_index);
    ClassDB::bind_method(D_METHOD("get_z_index"), &MapSpriteType::get_z_index);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "z_index"), "set_z_index", "get_z_index");

    ClassDB::bind_method(D_METHOD("set_sound", "sound"), &MapSpriteType::set_sound);
    ClassDB::bind_method(D_METHOD("get_sound"), &MapSpriteType::get_sound);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sound", PROPERTY_HINT_RESOURCE_TYPE, "WwiseEvent"),
        "set_sound", "get_sound");

    ClassDB::bind_method(D_METHOD("set_effects", "collision"), &MapSpriteType::set_effects);
    ClassDB::bind_method(D_METHOD("get_effects"), &MapSpriteType::get_effects);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "effects",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapEffectAttachment"
        ),
        "set_effects",
        "get_effects"
    );
    ClassDB::bind_method(D_METHOD("get_effects_recursive"), &MapSpriteType::get_effects_recursive);

    ClassDB::bind_method(D_METHOD("get_provided_spot_type"), &MapSpriteType::get_provided_spot_type);
    ClassDB::bind_method(D_METHOD("set_provided_spot_type", "spot_type"), &MapSpriteType::set_provided_spot_type);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "provided_spot_type", PROPERTY_HINT_RESOURCE_TYPE, "SpotType"), "set_provided_spot_type", "get_provided_spot_type");

    ClassDB::bind_method(D_METHOD("set_collision", "collision"), &MapSpriteType::set_collision);
    ClassDB::bind_method(D_METHOD("get_collision"), &MapSpriteType::get_collision);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "collision",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteCollision"
        ),
        "set_collision",
        "get_collision"
    );

    ClassDB::bind_method(D_METHOD("set_removable", "removable"), &MapSpriteType::set_removable);
    ClassDB::bind_method(D_METHOD("get_removable"), &MapSpriteType::get_removable);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "removable"), "set_removable", "get_removable");

    ClassDB::bind_method(D_METHOD("set_canonical_path_override", "canonical_path_override"), &MapSpriteType::set_canonical_path_override);
    ClassDB::bind_method(D_METHOD("get_canonical_path_override"), &MapSpriteType::get_canonical_path_override);
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "canonical_path_override"), "set_canonical_path_override", "get_canonical_path_override");

    ClassDB::bind_method(D_METHOD("get_total_instances"), &MapSpriteType::get_total_instances);
    ClassDB::bind_method(D_METHOD("has_prepass"), &MapSpriteType::has_prepass);

    ClassDB::bind_method(D_METHOD("is_canonically_equal"), &MapSpriteType::is_canonically_equal);

    BIND_ENUM_CONSTANT(InstanceType::FOOTPRINT);
    BIND_ENUM_CONSTANT(InstanceType::TREE);
    BIND_ENUM_CONSTANT(InstanceType::TREE_DAUB_FIR);
    BIND_ENUM_CONSTANT(InstanceType::MOUNTAIN);
    BIND_ENUM_CONSTANT(InstanceType::GRASS);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_DESERT);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_FLOWER_1);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_FLOWER_2);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_FLOWER_3);
    BIND_ENUM_CONSTANT(InstanceType::HILL_PLAINS);
    BIND_ENUM_CONSTANT(InstanceType::GENERIC);
    BIND_ENUM_CONSTANT(InstanceType::RIVER);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_STEPPE);
    BIND_ENUM_CONSTANT(InstanceType::LAKE);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_BRUSHLAND);
    BIND_ENUM_CONSTANT(InstanceType::DAUB_GENERIC);
    BIND_ENUM_CONSTANT(InstanceType::SWAMP_POND);
    BIND_ENUM_CONSTANT(InstanceType::TREE_DAUB_WILLOW);
    BIND_ENUM_CONSTANT(InstanceType::GRASS_DAUB_DRY);
    BIND_ENUM_CONSTANT(InstanceType::HILL_STEPPE);
    BIND_ENUM_CONSTANT(InstanceType::HILL_BRUSHLAND);
    BIND_ENUM_CONSTANT(InstanceType::BUILDING);
    BIND_ENUM_CONSTANT(InstanceType::WATERFALL);
    BIND_ENUM_CONSTANT(InstanceType::TREE_DAUB_DECIDUOUS);
    BIND_ENUM_CONSTANT(InstanceType::TREE_DAUB_SAKURA);
    BIND_ENUM_CONSTANT(InstanceType::GLASS);
}
