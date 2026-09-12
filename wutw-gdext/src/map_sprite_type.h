#pragma once

#include <memory>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>
#include <godot_cpp/variant/typed_dictionary.hpp>
#include <godot_cpp/classes/packed_scene.hpp>

#include "map_sprite_collision.h"

using namespace godot;

class MapEffectAttachment : public Resource {
    GDCLASS(MapEffectAttachment, Resource)

private:
    Ref<PackedScene> scene;
    Vector2 offset;
    float scale = 1.0;

protected:
    static void _bind_methods();

public:
    void set_scene(const Ref<PackedScene>& s) { scene = s; }
    Ref<PackedScene> get_scene() const { return scene; }
    void set_offset(const Vector2& p) { offset = p; }
    Vector2 get_offset() const { return offset; }
    void set_scale(const float& s) { scale = s; }
    float get_scale() const { return scale; }
};

class MapSpriteType : public Resource 
{
    GDCLASS(MapSpriteType, Resource);

public:
    enum InstanceType {
        FOOTPRINT,

        TREE,
        TREE_DAUB_FIR,

        MOUNTAIN,

        GRASS,
        GRASS_DAUB_DESERT,
        GRASS_DAUB_FLOWER_1,
        GRASS_DAUB_FLOWER_2,
        GRASS_DAUB_FLOWER_3,

        HILL_PLAINS,
        GENERIC,
        RIVER,
        SEA_WAVE,
        DUNE,
        GRASS_DAUB_STEPPE,
        LAKE,
        GRASS_DAUB_BRUSHLAND,
        DAUB_GENERIC,
        SWAMP_POND,
        TREE_DAUB_WILLOW,
        GRASS_DAUB_DRY,
        HILL_STEPPE,
        HILL_BRUSHLAND,
        BUILDING,
        WATERFALL,

        TREE_DAUB_DECIDUOUS,
        TREE_DAUB_SAKURA,

        GLASS,
    };

    MapSpriteType() {}
    ~MapSpriteType() {}

    Rect2 get_map_rect() const { return map_rect; }
    void set_map_rect(const Rect2& rect) { map_rect = rect; }
    void set_footprint_radius(float radius) { footprint_radius = radius; }
    float get_footprint_radius() const { return footprint_radius; }
    void set_default_scale(float scale) { default_scale = scale; }
    float get_default_scale() const { return default_scale; }
    void set_min_scale(float scale) { min_scale = scale; }
    float get_min_scale() const { return min_scale; }
    void set_priority_multiplier(float multiplier) { priority_multiplier = multiplier; }
    float get_priority_multiplier() const { return priority_multiplier; }
    Variant get_provided_spot_type() const { return provided_spot_type; }
    void set_provided_spot_type(const Variant& spot_type) { provided_spot_type = spot_type; }
    TypedArray<MapSpriteCollision> get_collision() const { return collision; }
    void set_collision(const TypedArray<MapSpriteCollision>& c) { collision = c; }
    void set_must_be_fully_within_clip(bool b) { must_be_fully_within_clip = b; }
    bool get_must_be_fully_within_clip() const { return must_be_fully_within_clip; }
    void set_ignore_clip(bool b) { ignore_clip = b; }
    bool get_ignore_clip() const { return ignore_clip; }
    void set_z_index(int z) { z_index = z; }
    int get_z_index() const { return z_index; }
    void set_sound(const Ref<Resource>& s) { sound = s; }
    Ref<Resource> get_sound() const { return sound; }
    void set_removable(bool b) { removable = b; }
    bool get_removable() const { return removable; }
    void set_effects(const TypedArray<MapEffectAttachment>& e) { effects.assign(e); }
    TypedArray<MapEffectAttachment> get_effects() const { return effects; }
    virtual TypedArray<MapEffectAttachment> get_effects_recursive() const { return effects; }
    String get_canonical_path_override() const { return canonical_path_override; }
    void set_canonical_path_override(const String& path) { canonical_path_override = path; }

    bool is_canonically_equal(const Ref<MapSpriteType>& other);
    
    virtual int get_total_instances() const { return 1; }
    virtual bool has_prepass() const { return false; }
    virtual int add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const { return 0; }
    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const { return 0;  }

protected:
    static void _bind_methods();

    Rect2 map_rect;
    float footprint_radius = 50.0;
    float default_scale = 1.0;
    float min_scale = 1.0;
    float priority_multiplier = 1.0;
    bool must_be_fully_within_clip = false;
    bool ignore_clip = false;
    int z_index = 0;
    Ref<Resource> sound = nullptr;  // Really WwiseEvent.
    TypedArray<MapEffectAttachment> effects;
    Variant provided_spot_type = nullptr;
    TypedArray<MapSpriteCollision> collision;

    // For spot upgrade visuals.
    bool removable = false;

    // For e.g. varied roof colors of the same building, this is the resource_path of the original.
    String canonical_path_override;
};

VARIANT_ENUM_CAST(MapSpriteType::InstanceType);
#define ADD_MAP_SPRITE_TYPE_PROPERTY(cls, name)                                \
    ClassDB::bind_method(                                                      \
        D_METHOD("set_" #name, #name),                                         \
        &cls::set_##name                                                       \
    );                                                                          \
    ClassDB::bind_method(                                                      \
        D_METHOD("get_" #name),                                                 \
        &cls::get_##name                                                       \
    );                                                                          \
    ADD_PROPERTY(                                                              \
        PropertyInfo(Variant::INT, #name, PROPERTY_HINT_ENUM, "FOOTPRINT,TREE,TREE_DAUB_FIR,MOUNTAIN,GRASS,GRASS_DAUB_DESERT,GRASS_DAUB_FLOWER_1,GRASS_DAUB_FLOWER_2,GRASS_DAUB_FLOWER_3,HILL_PLAINS,GENERIC,RIVER,SEA_WAVE,DUNE,GRASS_DAUB_STEPPE,LAKE,GRASS_DAUB_BRUSHLAND,DAUB_GENERIC,SWAMP_POND,TREE_DAUB_WILLOW,GRASS_DAUB_DRY,HILL_STEPPE,HILL_BRUSHLAND,BUILDING,WATERFALL,TREE_DAUB_DECIDUOUS,TREE_DAUB_SAKURA,GLASS"),           \
        "set_" #name,                                                          \
        "get_" #name                                                           \
    );
