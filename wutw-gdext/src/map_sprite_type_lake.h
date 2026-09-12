#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"
#include <map_sprite_type_composite.h>

using namespace godot;

class MapSpriteType_Lake : public MapSpriteType
{
    GDCLASS(MapSpriteType_Lake, MapSpriteType);

public:
    MapSpriteType_Lake() {}
    ~MapSpriteType_Lake() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }
    void set_slots(const TypedArray<MapSpriteComponent>& s) { slots = s; }
    TypedArray<MapSpriteComponent> get_slots() const { return slots; }

    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
    TypedArray<MapSpriteComponent> slots;
};
