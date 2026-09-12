#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteType_Mountain : public MapSpriteType
{
    GDCLASS(MapSpriteType_Mountain, MapSpriteType);

public:
    MapSpriteType_Mountain() {}
    ~MapSpriteType_Mountain() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }
    void set_instance_type(InstanceType type) { instance_type = type; }
    InstanceType get_instance_type() const { return instance_type; }

    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
    InstanceType instance_type = InstanceType::MOUNTAIN;
};
