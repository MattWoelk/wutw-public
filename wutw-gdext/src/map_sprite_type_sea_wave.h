#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteType_SeaWave : public MapSpriteType
{
    GDCLASS(MapSpriteType_SeaWave, MapSpriteType);

public:
    MapSpriteType_SeaWave() {}
    ~MapSpriteType_SeaWave() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }

    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
};
