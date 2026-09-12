#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"
#include <map_sprite_type_composite.h>

using namespace godot;

class MapSpriteType_River : public MapSpriteType
{
    GDCLASS(MapSpriteType_River, MapSpriteType);

public:
    enum DirectionType {
        HORIZONTAL,
        VERTICAL,
        CORNER_AROUND_NW,
        CORNER_AROUND_NE,
        CORNER_AROUND_SW,
        CORNER_AROUND_SE,
    };

    MapSpriteType_River() {}
    ~MapSpriteType_River() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }
    void set_direction_type(DirectionType d) { direction_type = d; }
    DirectionType get_direction_type() const { return direction_type; }
    void set_instance_type(InstanceType type) { instance_type = type; }
    InstanceType get_instance_type() const { return instance_type; }
    void set_slots(const TypedArray<MapSpriteComponent>& s) { slots = s; }
    TypedArray<MapSpriteComponent> get_slots() const { return slots; }

    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
    DirectionType direction_type = DirectionType::HORIZONTAL;
    InstanceType instance_type = InstanceType::RIVER;
    TypedArray<MapSpriteComponent> slots;
};

VARIANT_ENUM_CAST(MapSpriteType_River::DirectionType);
