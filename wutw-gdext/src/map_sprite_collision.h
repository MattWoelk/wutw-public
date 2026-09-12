#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/rect2.hpp>
#include <godot_cpp/classes/multi_mesh.hpp>

#include "quad_tree.h"

using namespace godot;

struct MapInstanceData {
    Transform2D transform;
    Color vertex_color;
    Color custom_data;
};

class MapSpriteCollision : public Resource
{
    GDCLASS(MapSpriteCollision, Resource);

public:
    MapSpriteCollision() {}
    ~MapSpriteCollision() {}

    void set_blocking(bool p_blocking);
    bool is_blocking() const;

    virtual Rect2 get_bbox() const { return Rect2(); }
    virtual void add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const {}
    virtual bool intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const { return false;  }
    virtual Array query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const { return {}; }
    virtual void add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const {}

protected:
    static void _bind_methods();

    bool blocking = false;
};

class MapSpriteCollision_Circle : public MapSpriteCollision
{
    GDCLASS(MapSpriteCollision_Circle, MapSpriteCollision);

public:
    MapSpriteCollision_Circle() {}
    ~MapSpriteCollision_Circle() {}

    void set_center(const Vector2& p_center) { center = p_center; }
    Vector2 get_center() const { return center; }
    void set_radius(float p_radius) { radius = p_radius; }
    float get_radius() const { return radius; }

    virtual Rect2 get_bbox() const override { return Rect2(center, Vector2(radius * 2.f, radius * 2.f)); }
    virtual void add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const override;
    virtual bool intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const override;
    virtual Array query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const override;
    virtual void add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Vector2 center;
    float radius = 0.0f;
};

class MapSpriteCollision_Rect : public MapSpriteCollision
{
    GDCLASS(MapSpriteCollision_Rect, MapSpriteCollision);

public:
    MapSpriteCollision_Rect() {}
    ~MapSpriteCollision_Rect() {}

    void set_rect(const Rect2& p_rect) { rect = p_rect; }
    Rect2 get_rect() const { return rect; }

    virtual Rect2 get_bbox() const override { return get_rect(); }
    virtual void add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const override;
    virtual bool intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const override;
    virtual Array query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const override;
    virtual void add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Rect2 rect;
};

class MapSpriteCollision_Line : public MapSpriteCollision
{
    GDCLASS(MapSpriteCollision_Line, MapSpriteCollision);

public:
    MapSpriteCollision_Line() {}
    ~MapSpriteCollision_Line() {}

    void set_p1(const Vector2& p_p1) { p1 = p_p1; }
    Vector2 get_p1() const { return p1; }
    void set_p2(const Vector2& p_p2) { p2 = p_p2; }
    Vector2 get_p2() const { return p2; }

    virtual Rect2 get_bbox() const override {
        Rect2 result(p1, Vector2(0.f, 0.f));
        result.expand_to(p2);
        return result;
    }
    virtual void add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const override;
    virtual bool intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const override;
    virtual Array query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const override;
    virtual void add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Vector2 p1;
    Vector2 p2;
};

class MapSpriteCollision_Triangle : public MapSpriteCollision
{
    GDCLASS(MapSpriteCollision_Triangle, MapSpriteCollision);

public:
    MapSpriteCollision_Triangle() {}
    ~MapSpriteCollision_Triangle() {}

    void set_p1(const Vector2& p_p1) { p1 = p_p1; }
    Vector2 get_p1() const { return p1; }
    void set_p2(const Vector2& p_p2) { p2 = p_p2; }
    Vector2 get_p2() const { return p2; }
    void set_p3(const Vector2& p_p3) { p3 = p_p3; }
    Vector2 get_p3() const { return p3; }

    virtual Rect2 get_bbox() const override {
        Rect2 result(p1, Vector2(0.f, 0.f));
        result.expand_to(p2);
        result.expand_to(p3);
        return result;
    }
    virtual void add_to_quad_tree(Variant object, Ref<QuadTree> quad_tree, Vector2 location, float scale) const override;
    virtual bool intersects_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool intersect_blocking) const override;
    virtual Array query_quad_tree(Ref<QuadTree> quad_tree, Vector2 location, float scale, bool only_blocking) const override;
    virtual void add_mesh_instance(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    Vector2 p1;
    Vector2 p2;
    Vector2 p3;
};
