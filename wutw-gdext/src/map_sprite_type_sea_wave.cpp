#include "map_sprite_type_sea_wave.h"

int MapSpriteType_SeaWave::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 wave_rect = get_map_rect();
    wave_rect.position = location + wave_rect.position * scale;
    wave_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, wave_rect.size, 0.0, wave_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(InstanceType::SEA_WAVE, location.x, location.y, 0);
    return 1;
}

void MapSpriteType_SeaWave::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_SeaWave::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_SeaWave::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");
}
