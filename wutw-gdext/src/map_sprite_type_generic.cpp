#include "map_sprite_type_generic.h"

int MapSpriteType_Generic::get_total_instances() const
{
    return 1 + daubs.size();
}

bool MapSpriteType_Generic::has_prepass() const
{
    return !daubs.is_empty();
}

int MapSpriteType_Generic::add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    if (use_prepass) {
        return add_daubs(output_buffer, location, scale);
    } else {
        return 0;
    }
}

int MapSpriteType_Generic::add_daubs(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 map_rect = get_map_rect();
    Vector2 map_position = location + map_rect.position * scale;
    for (int i = 0; i < daubs.size(); ++i) {
        Rect2 daub_rect = daubs[i];
        float y_offset = 0.5f + daub_rect.position.y / map_rect.size.y;
        daub_rect.position = map_position + daub_rect.position * scale;
        daub_rect.size *= scale;
        output_buffer->transform = Transform2D(0.f, daub_rect.size, 0.0, daub_rect.position);
        output_buffer->vertex_color = daub_color;
        output_buffer->custom_data = Color(daub_instance_type, 0, 0, 0);
        output_buffer++;
    }
    return daubs.size();
}

int MapSpriteType_Generic::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    int count = 0;
    if (!use_prepass) {
        count += add_daubs(output_buffer, location, scale);
        output_buffer += count;
    }
    Rect2 map_rect = get_map_rect();
    map_rect.position = location + map_rect.position * scale;
    map_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, map_rect.size, 0.0, map_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(instance_type, float(atlas_type), use_line_noise ? 1.f : 0.f, 0);
    return count + 1;
}

void MapSpriteType_Generic::_bind_methods()
{
    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Generic, instance_type);
    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Generic, daub_instance_type);

    ClassDB::bind_method(D_METHOD("set_atlas_type", "atlas_type"), &MapSpriteType_Generic::set_atlas_type);
    ClassDB::bind_method(D_METHOD("get_atlas_type"), &MapSpriteType_Generic::get_atlas_type);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "atlas_type", PROPERTY_HINT_ENUM, "VEGETATION,BUILDINGS,MOUNTAIN,WATER_FEATURES"), "set_atlas_type", "get_atlas_type");

    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Generic::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Generic::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_use_line_noise", "use_line_noise"), &MapSpriteType_Generic::set_use_line_noise);
    ClassDB::bind_method(D_METHOD("get_use_line_noise"), &MapSpriteType_Generic::get_use_line_noise);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "use_line_noise"), "set_use_line_noise", "get_use_line_noise");

    ClassDB::bind_method(D_METHOD("set_daubs", "daubs"), &MapSpriteType_Generic::set_daubs);
    ClassDB::bind_method(D_METHOD("get_daubs"), &MapSpriteType_Generic::get_daubs);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "daubs", PROPERTY_HINT_ARRAY_TYPE, "Rect2"), "set_daubs", "get_daubs");

    ClassDB::bind_method(D_METHOD("set_daub_color", "daub_color"), &MapSpriteType_Generic::set_daub_color);
    ClassDB::bind_method(D_METHOD("get_daub_color"), &MapSpriteType_Generic::get_daub_color);
    ADD_PROPERTY(PropertyInfo(Variant::COLOR, "daub_color"), "set_daub_color", "get_daub_color");

    ClassDB::bind_method(D_METHOD("set_use_prepass", "use_prepass"), &MapSpriteType_Generic::set_use_prepass);
    ClassDB::bind_method(D_METHOD("get_use_prepass"), &MapSpriteType_Generic::get_use_prepass);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "use_prepass"), "set_use_prepass", "get_use_prepass");
}
