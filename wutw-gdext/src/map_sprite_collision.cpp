#include "map_sprite_collision.h"
#include <utils.h>

void MapSpriteCollision::set_blocking(bool p_blocking) {
    blocking = p_blocking;
}
bool MapSpriteCollision::is_blocking() const {
    return blocking;
}

void MapSpriteCollision::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_blocking", "blocking"), &MapSpriteCollision::set_blocking);
    ClassDB::bind_method(D_METHOD("is_blocking"), &MapSpriteCollision::is_blocking);

    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "blocking"), "set_blocking", "is_blocking");
}

void MapSpriteCollision_Circle::add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const {
    quad_tree->add_circle(object, location + center * scale, radius * scale, blocking);
}

bool MapSpriteCollision_Circle::intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const {
    return quad_tree->intersects_circle(location + center * scale, radius * scale, intersect_blocking);
}

Array MapSpriteCollision_Circle::query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const
{
    return quad_tree->query_circle(location + center * scale, radius * scale, only_blocking);
}

void MapSpriteCollision_Circle::add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const {
    Vector2 size = Vector2(2, 2) * radius * scale;
    output_buffer->transform = Transform2D(0, size, 0.0, location + center * scale);
    output_buffer->vertex_color = Color(1.f, 1.f, 1.f, 1.f);
    output_buffer->custom_data = Color(0, blocking ? 1.f : 2.f, 0, 0);
}

void MapSpriteCollision_Circle::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_center", "center"), &MapSpriteCollision_Circle::set_center);
    ClassDB::bind_method(D_METHOD("get_center"), &MapSpriteCollision_Circle::get_center);
    ClassDB::bind_method(D_METHOD("set_radius", "radius"), &MapSpriteCollision_Circle::set_radius);
    ClassDB::bind_method(D_METHOD("get_radius"), &MapSpriteCollision_Circle::get_radius);

    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "center"), "set_center", "get_center");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "radius"), "set_radius", "get_radius");
}

void MapSpriteCollision_Rect::add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const {
    Rect2 transformed_rect;
    transformed_rect.size = rect.size * scale;
    transformed_rect.position = location + rect.position * scale;
    quad_tree->add_rect(object, transformed_rect, blocking);
}

bool MapSpriteCollision_Rect::intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const {
    Rect2 transformed_rect;
    transformed_rect.size = rect.size * scale;
    transformed_rect.position = location + rect.position * scale;
    return quad_tree->intersects_rect(transformed_rect, intersect_blocking);
}

Array MapSpriteCollision_Rect::query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const
{
    Rect2 transformed_rect;
    transformed_rect.size = rect.size * scale;
    transformed_rect.position = location + rect.position * scale;
    return quad_tree->query_rect(transformed_rect, only_blocking);
}

void MapSpriteCollision_Rect::add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const {
    output_buffer->transform = Transform2D(0, rect.size * scale, 0.0, location + (rect.position + rect.size / 2.f) * scale);
    output_buffer->vertex_color = Color(1.f, 1.f, 1.f, 1.f);
    output_buffer->custom_data = Color(0, blocking ? 1.f : 2.f, 1.f, 0);
}

void MapSpriteCollision_Rect::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_rect", "rect"), &MapSpriteCollision_Rect::set_rect);
    ClassDB::bind_method(D_METHOD("get_rect"), &MapSpriteCollision_Rect::get_rect);

    ADD_PROPERTY(PropertyInfo(Variant::RECT2, "rect"), "set_rect", "get_rect");
}

void MapSpriteCollision_Line::add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const {
    quad_tree->add_line(object, location + p1 * scale, location + p2 * scale, blocking);
}

bool MapSpriteCollision_Line::intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const {
    return quad_tree->intersects_line(location + p1 * scale, location + p2 * scale, intersect_blocking);
}

Array MapSpriteCollision_Line::query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const
{
    return quad_tree->query_line(location + p1 * scale, location + p2 * scale, only_blocking);
}

void MapSpriteCollision_Line::add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const {
    Vector2 tp1(location + p1 * scale);
    Vector2 tp2(location + p2 * scale);

    const Vector2 MIN_SIZE(0.5f, 0.5f);
    Rect2 rect(location, MIN_SIZE);
    rect.expand_to(tp1);
    rect.expand_to(tp2);

    Vector2 uv_p1((tp1 - rect.position) / rect.size);
    Vector2 uv_p2((tp2 - rect.position) / rect.size);

    output_buffer->transform = Transform2D(0, rect.size, 0.0, rect.position + rect.size / 2.f);
    output_buffer->vertex_color = Color(uv_p1.x, uv_p1.y, uv_p2.x, uv_p2.y);
    output_buffer->custom_data = Color(0, blocking ? 1.f : 2.f, 2., 0);
}

void MapSpriteCollision_Line::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_p1", "p1"), &MapSpriteCollision_Line::set_p1);
    ClassDB::bind_method(D_METHOD("get_p1"), &MapSpriteCollision_Line::get_p1);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "p1"), "set_p1", "get_p1");

    ClassDB::bind_method(D_METHOD("set_p2", "p2"), &MapSpriteCollision_Line::set_p2);
    ClassDB::bind_method(D_METHOD("get_p2"), &MapSpriteCollision_Line::get_p2);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "p2"), "set_p2", "get_p2");
}

void MapSpriteCollision_Triangle::add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const {
    quad_tree->add_triangle(object, location + p1 * scale, location + p2 * scale, location + p3 * scale, blocking);
}

bool MapSpriteCollision_Triangle::intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const {
    return quad_tree->intersects_triangle(location + p1 * scale, location + p2 * scale, location + p3 * scale, intersect_blocking);
}

Array MapSpriteCollision_Triangle::query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const
{
    return quad_tree->query_triangle(location + p1 * scale, location + p2 * scale, location + p3 * scale, only_blocking);
}

void MapSpriteCollision_Triangle::add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const {
    Vector2 tp1(location + p1 * scale);
    Vector2 tp2(location + p2 * scale);
    Vector2 tp3(location + p3 * scale);

    const Vector2 MIN_SIZE(0.5f, 0.5f);
    Rect2 rect(location, MIN_SIZE);
    rect.expand_to(tp1);
    rect.expand_to(tp2);
    rect.expand_to(tp3);

    Vector2 uv_p1((tp1 - rect.position) / rect.size);
    Vector2 uv_p2((tp2 - rect.position) / rect.size);
    Vector2 uv_p3((tp3 - rect.position) / rect.size);

    output_buffer->transform = Transform2D(0, rect.size, 0.0, rect.position + rect.size / 2.f);
    output_buffer->vertex_color = Color(utils::pack_vec2(uv_p1), utils::pack_vec2(uv_p2), utils::pack_vec2(uv_p3), 0);
    output_buffer->custom_data = Color(0, blocking ? 1.f : 2.f, 3., 0);
}

void MapSpriteCollision_Triangle::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_p1", "p1"), &MapSpriteCollision_Triangle::set_p1);
    ClassDB::bind_method(D_METHOD("get_p1"), &MapSpriteCollision_Triangle::get_p1);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "p1"), "set_p1", "get_p1");

    ClassDB::bind_method(D_METHOD("set_p2", "p2"), &MapSpriteCollision_Triangle::set_p2);
    ClassDB::bind_method(D_METHOD("get_p2"), &MapSpriteCollision_Triangle::get_p2);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "p2"), "set_p2", "get_p2");

    ClassDB::bind_method(D_METHOD("set_p3", "p3"), &MapSpriteCollision_Triangle::set_p3);
    ClassDB::bind_method(D_METHOD("get_p3"), &MapSpriteCollision_Triangle::get_p3);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "p3"), "set_p3", "get_p3");
}
