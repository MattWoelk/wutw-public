#include "map_sprite_type_building.h"

int MapSpriteType_Building::get_total_instances() const
{
    return 1;
}

int MapSpriteType_Building::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 map_rect = get_map_rect();
    map_rect.position = location + map_rect.position * scale;
    map_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, map_rect.size, 0.0, map_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(InstanceType::BUILDING, roof_color.r, roof_color.g, roof_color.b);
    return 1;
}

void MapSpriteType_Building::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Building::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Building::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_roof_color", "color"), &MapSpriteType_Building::set_roof_color);
    ClassDB::bind_method(D_METHOD("get_roof_color"), &MapSpriteType_Building::get_roof_color);
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "roof_color"), "set_roof_color", "get_roof_color");
}
