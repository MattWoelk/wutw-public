#include "map_sprite_type_river.h"

int MapSpriteType_River::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 river_rect = get_map_rect();
    river_rect.position = location + river_rect.position * scale;
    river_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, river_rect.size, 0.0, river_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(instance_type, float(direction_type), location.x, location.y);
    return 1;
}

void MapSpriteType_River::_bind_methods()
{
    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_River, instance_type);

    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_River::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_River::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_direction_type", "direction_type"), &MapSpriteType_River::set_direction_type);
    ClassDB::bind_method(D_METHOD("get_direction_type"), &MapSpriteType_River::get_direction_type);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "direction_type", PROPERTY_HINT_ENUM, "HORIZONTAL,VERTICAL,CORNER_AROUND_NW,CORNER_AROUND_NE, CORNER_AROUND_SW, CORNER_AROUND_SE"), "set_direction_type", "get_direction_type");

    ClassDB::bind_method(D_METHOD("set_slots", "slots"), &MapSpriteType_River::set_slots);
    ClassDB::bind_method(D_METHOD("get_slots"), &MapSpriteType_River::get_slots);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "slots",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteComponent"
        ),
        "set_slots", "get_slots");
}
