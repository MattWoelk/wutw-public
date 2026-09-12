#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteType_Generic : public MapSpriteType
{
    GDCLASS(MapSpriteType_Generic, MapSpriteType);

public:
    enum AtlasType {
        VEGETATION,
        BUILDINGS,
        MOUNTAIN,
        WATER_FEATURES,
    };

    MapSpriteType_Generic() {}
    ~MapSpriteType_Generic() {}

    void set_instance_type(InstanceType type) { instance_type = type; }
    InstanceType get_instance_type() const { return instance_type; }
    void set_daub_instance_type(InstanceType type) { daub_instance_type = type; }
    InstanceType get_daub_instance_type() const { return daub_instance_type; }
    void set_atlas_type(MapSpriteType_Generic::AtlasType type) { atlas_type = type; }
    MapSpriteType_Generic::AtlasType get_atlas_type() const { return atlas_type; }
    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }
    void set_use_line_noise(const bool& use) { use_line_noise = use; }
    bool get_use_line_noise() const { return use_line_noise; }
    void set_daubs(const TypedArray<Rect2>& daubs) { this->daubs = daubs; }
    TypedArray<Rect2> get_daubs() const { return daubs; }
    void set_daub_color(const Color& color) { daub_color = color; }
    Color get_daub_color() const { return daub_color; }
    void set_use_prepass(bool p) { use_prepass = p; }
    bool get_use_prepass() const { return use_prepass; }

    virtual int get_total_instances() const override;
    virtual bool has_prepass() const override;
    virtual int add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;
    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    InstanceType instance_type = InstanceType::GENERIC;
    InstanceType daub_instance_type = InstanceType::DAUB_GENERIC;
    MapSpriteType_Generic::AtlasType atlas_type = MapSpriteType_Generic::VEGETATION;
    Rect2i atlas_rect;
    bool use_line_noise = false;
    TypedArray<Rect2> daubs;
    Color daub_color;
    bool use_prepass = true;

    int add_daubs(MapInstanceData* output_buffer, const Vector2& location, const float scale) const;
};

VARIANT_ENUM_CAST(MapSpriteType_Generic::AtlasType);
