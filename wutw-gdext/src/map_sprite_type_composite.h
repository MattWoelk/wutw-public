#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/typed_dictionary.hpp>
#include "map_sprite_type.h"

using namespace godot;

class MapSpriteComponent : public Resource {
    GDCLASS(MapSpriteComponent, Resource)

private:
    Ref<MapSpriteType> sprite_type;
    Vector2 offset;
    float scale = 1.0f;

protected:
    static void _bind_methods();

public:
    void set_sprite_type(const Ref<MapSpriteType>& p) { sprite_type = p; }
    Ref<MapSpriteType> get_sprite_type() const { return sprite_type; }
    void set_offset(const Vector2& p) { offset = p; }
    Vector2 get_offset() const { return offset; }
    void set_scale(float p) { scale = p; }
    float get_scale() const { return scale; }
};

class MapSpriteType_Composite : public MapSpriteType
{
    GDCLASS(MapSpriteType_Composite, MapSpriteType);

public:
    MapSpriteType_Composite() {}
    ~MapSpriteType_Composite() {}

    void set_components(const TypedArray<MapSpriteComponent>& cs) { components = cs; }
    TypedArray<MapSpriteComponent> get_components() const { return components; }

    virtual TypedArray<MapEffectAttachment> get_effects_recursive() const override;

    virtual int get_total_instances() const override;
    virtual bool has_prepass() const override;
    virtual int add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;
    virtual int add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const override;

protected:
    static void _bind_methods();

private:
    TypedArray<MapSpriteComponent> components;
};
