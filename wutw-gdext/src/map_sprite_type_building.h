#pragma once

#include <godot_cpp/classes/resource.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteType_Building : public MapSpriteType
{
    GDCLASS(MapSpriteType_Building, MapSpriteType);

public:
    MapSpriteType_Building() {}
    ~MapSpriteType_Building() {}

    void set_atlas_rect(const Rect2i& rect) { atlas_rect = rect; }
    Rect2i get_atlas_rect() const { return atlas_rect; }

    void set_roof_color(const Color& color) { roof_color = color; }
    Color get_roof_color() const { return roof_color; }

    virtual int get_total_instances() const override;
    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2i atlas_rect;
    Color roof_color = Color(0.671, 0.341, 0.22, 1.0);
};
