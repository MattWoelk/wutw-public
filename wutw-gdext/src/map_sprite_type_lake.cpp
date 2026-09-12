#include "map_sprite_type_lake.h"

int MapSpriteType_Lake::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 lake_rect = get_map_rect();
    lake_rect.position = location + lake_rect.position * scale;
    lake_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, lake_rect.size, 0.0, lake_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(InstanceType::LAKE, 0, 0, 0);
    return 1;
}

void MapSpriteType_Lake::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Lake::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Lake::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_slots", "slots"), &MapSpriteType_Lake::set_slots);
    ClassDB::bind_method(D_METHOD("get_slots"), &MapSpriteType_Lake::get_slots);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "slots",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteComponent"
        ),
        "set_slots", "get_slots");
}
