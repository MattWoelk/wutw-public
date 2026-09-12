#include "map_sprite_type_mountain.h"

int MapSpriteType_Mountain::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 mountain_rect = get_map_rect();
    mountain_rect.position = location + mountain_rect.position * scale;
    mountain_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, mountain_rect.size, 0.0, mountain_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(instance_type, 0, 0, 0);
    return 1;
}

void MapSpriteType_Mountain::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Mountain::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Mountain::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Mountain, instance_type);
}
