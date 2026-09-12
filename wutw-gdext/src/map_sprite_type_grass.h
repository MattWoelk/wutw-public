#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteType_Grass : public MapSpriteType
{
    GDCLASS(MapSpriteType_Grass, MapSpriteType);

public:
    MapSpriteType_Grass() {}
    ~MapSpriteType_Grass() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }
    void set_daubs(const TypedArray<Rect2>& daubs) { this->daubs = daubs; }
    TypedArray<Rect2> get_daubs() const { return daubs; }
    void set_instance_type(InstanceType type) { instance_type = type; }
    InstanceType get_instance_type() const { return instance_type; }
    void set_daub_instance_type(InstanceType type) { daub_instance_type = type; }
    InstanceType get_daub_instance_type() const { return daub_instance_type; }
    void set_wind_multiplier(float multiplier) { wind_multiplier = multiplier; }
    float get_wind_multiplier() const { return wind_multiplier; }
    void set_use_prepass(bool p) { use_prepass = p; }
    bool get_use_prepass() const { return use_prepass; }

    virtual int get_total_instances() const override;
    virtual bool has_prepass() const override;
    virtual int add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;
    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
    TypedArray<Rect2> daubs;
    InstanceType instance_type = InstanceType::GRASS;
    InstanceType daub_instance_type = InstanceType::GRASS_DAUB_DESERT;
    float wind_multiplier = 1.0;
    bool use_prepass = true;

    int add_daubs(MapInstanceData* output_buffer, const Vector2& location, const float scale) const;
};
