#include "map_sprite_type_tree.h"

int MapSpriteType_Tree::get_total_instances() const
{
    return 1 + daubs.size();
}

bool MapSpriteType_Tree::has_prepass() const
{
    return use_prepass && !daubs.is_empty();
}

int MapSpriteType_Tree::add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    if (use_prepass) {
        return add_daubs(output_buffer, location, scale);
    } else {
        return 0;
    }
}

int MapSpriteType_Tree::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    int count = 0;
    if (!use_prepass) {
        count += add_daubs(output_buffer, location, scale);
        output_buffer += count;
    }
    Rect2 tree_rect = get_map_rect();
    tree_rect.position = location + tree_rect.position * scale;
    tree_rect.size *= scale;
    output_buffer->transform = Transform2D(0.f, tree_rect.size, 0.0, tree_rect.position);
    output_buffer->vertex_color = Color(atlas_rect.position.x, atlas_rect.position.y, atlas_rect.size.x, atlas_rect.size.y);
    output_buffer->custom_data = Color(InstanceType::TREE, location.x, location.y, wind_multiplier);
    return count + 1;
}

void MapSpriteType_Tree::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_atlas_rect", "rect"), &MapSpriteType_Tree::set_atlas_rect);
    ClassDB::bind_method(D_METHOD("get_atlas_rect"), &MapSpriteType_Tree::get_atlas_rect);
    ADD_PROPERTY(PropertyInfo(Variant::RECT2I, "atlas_rect"), "set_atlas_rect", "get_atlas_rect");

    ClassDB::bind_method(D_METHOD("set_daubs", "daubs"), &MapSpriteType_Tree::set_daubs);
    ClassDB::bind_method(D_METHOD("get_daubs"), &MapSpriteType_Tree::get_daubs);
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "daubs", PROPERTY_HINT_ARRAY_TYPE, "Rect2"), "set_daubs", "get_daubs");

    ADD_MAP_SPRITE_TYPE_PROPERTY(MapSpriteType_Tree, daub_instance_type);

    ClassDB::bind_method(D_METHOD("set_wind_multiplier", "wind_multiplier"), &MapSpriteType_Tree::set_wind_multiplier);
    ClassDB::bind_method(D_METHOD("get_wind_multiplier"), &MapSpriteType_Tree::get_wind_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "wind_multiplier"), "set_wind_multiplier", "get_wind_multiplier");

    ClassDB::bind_method(D_METHOD("set_use_prepass", "use_prepass"), &MapSpriteType_Tree::set_use_prepass);
    ClassDB::bind_method(D_METHOD("get_use_prepass"), &MapSpriteType_Tree::get_use_prepass);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "use_prepass"), "set_use_prepass", "get_use_prepass");
}

int MapSpriteType_Tree::add_daubs(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    Rect2 tree_rect = get_map_rect();
    Vector2 tree_position = location + tree_rect.position * scale;
    for (int i = 0; i < daubs.size(); ++i) {
        Rect2 daub_rect = daubs[i];
        float y_offset = 0.5f + daub_rect.position.y / tree_rect.size.y;
        daub_rect.position = tree_position + daub_rect.position * scale;
        daub_rect.size *= scale;
        output_buffer->transform = Transform2D(0.f, daub_rect.size, 0.0, daub_rect.position);
        output_buffer->vertex_color = Color(wind_multiplier, 0, atlas_rect.size.x, atlas_rect.size.y);
        output_buffer->custom_data = Color(daub_instance_type, location.x, location.y, y_offset);
        output_buffer++;
    }
    return daubs.size();
}
