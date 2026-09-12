#include "map_sprite_type_grass.h"

int MapSpriteType_Grass::get_total_instances() const
{
    return 1 + daubs.size();
}

bool MapSpriteType_Grass::has_prepass() const
{
    return !daubs.is_empty();
}

int MapSpriteType_Grass::add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    if (use_prepass) {
        return add_daubs(output_buffer, location, scale);
    } else {
        return 0;
    }
}

int MapSpriteType_Grass::add_daubs(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 grass_rect = get_map_rect();
    Vector2 grass_position = location + grass_rect.position * scale;
    for (int i = 0; i < daubs.size(); ++i) {
        Rect2 daub_rect = daubs[i];
        float y_offset = 0.5f + daub_rect.position.y / grass_rect.size.y;
        daub_rect.position = grass_position + daub_rect.position * scale;
        daub_rect.size *= scale;
        output_buffer->transform = Transform2D(0.f, daub_rect.size, 0.0, daub_rect.position);
        output_buffer->vertex_color = Color(wind_multiplier, 0, atlas_rect.size.x, atlas_rect.size.y);
        output_buffer->custom_data = Color(daub_instance_type, location.x, location.y, y_offset);
        output_buffer++;
    }
    return daubs.size();
}

int MapSpriteType_Grass::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    int count = 0;
    if (!use_prepass) {
        count += add_daubs(output_buffer, location, scale);
        output_buffer += count;
    }
    Rect2 grass_rect = get_map_rect();
    grass_rect.position = location + grass_rect.position * scale;
    grass_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, grass_rect.size, 0.0, grass_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(instance_type, location.x, location.y, wind_multiplier);
    return count + 1;
}

void MapSpriteType_Grass::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Grass::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Grass::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_daubs", "daubs"), &MapSpriteType_Grass::set_daubs);
    ClassDB::bind_method(D_METHOD("get_daubs"), &MapSpriteType_Grass::get_daubs);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "daubs", PROPERTY_HINT_ARRAY_TYPE, "Rect2"), "set_daubs", "get_daubs");

    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Grass, instance_type);
    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Grass, daub_instance_type);

    ClassDB::bind_method(D_METHOD("set_wind_multiplier", "wind_multiplier"), &MapSpriteType_Grass::set_wind_multiplier);
    ClassDB::bind_method(D_METHOD("get_wind_multiplier"), &MapSpriteType_Grass::get_wind_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "wind_multiplier"), "set_wind_multiplier", "get_wind_multiplier");

    ClassDB::bind_method(D_METHOD("set_use_prepass", "use_prepass"), &MapSpriteType_Grass::set_use_prepass);
    ClassDB::bind_method(D_METHOD("get_use_prepass"), &MapSpriteType_Grass::get_use_prepass);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "use_prepass"), "set_use_prepass", "get_use_prepass");
}
