#pragma once

#include <godot_cpp/classes/multi_mesh_instance2d.hpp>
#include <godot_cpp/classes/quad_mesh.hpp>
#include <godot_cpp/classes/image_texture.hpp>

#include "map_sprite_placer.h"

class MapSpriteRenderer : public MultiMeshInstance2D
{
    GDCLASS(MapSpriteRenderer, MultiMeshInstance2D);

public:
    MapSpriteRenderer() {}
    ~MapSpriteRenderer() {}

    virtual void _ready() override;
    virtual void _process(double p_delta) override;

    void set_placements(const TypedArray<MapSpritePlacement>& placements);
    TypedArray<MapSpritePlacement> get_placements() const { return placements; }

    void add_placement(const Ref<MapSpritePlacement>& placement);
    void remove_placement(const Ref<MapSpritePlacement>& placement);

    void animate_add_placement(const Ref<MapSpritePlacement>& placement);
    void animate_remove_placement(const Ref<MapSpritePlacement>& placement);

    void set_animation_duration(float a) { animation_duration = a; }
    float get_animation_duration() const { return animation_duration; }
    void set_live_debug(bool live_debug);
    bool get_live_debug() const { return live_debug; }
    void set_draw_debug_footprints(bool draw_debug_footprints);
    bool get_draw_debug_footprints() const { return draw_debug_footprints; }
    void set_draw_debug_collision(bool draw_debug_collision);
    bool get_draw_debug_collision() const { return draw_debug_collision; }

protected:
    static void _bind_methods();

private:
    void _update();
    void _update_opacities(float delta);
    void _update_buffer_texture(bool opacities_only);
    int add_footprint_instance(MapInstanceData* output_buffer, const MapSpritePlacement& placement);
    int add_collision_instances(MapInstanceData* output_buffer, const MapSpritePlacement& placement);
    float get_opacity(Ref<MapSpritePlacement> placement) const;
    
    TypedArray<MapSpritePlacement> placements;
    float animation_duration = 1.0;
    bool live_debug = false;
    bool draw_debug_footprints = false;
    bool draw_debug_collision = false;

    // For fade in/out animation support.
    // Keys are placements. Values are {prepass_offset, prepass_count, main_pass_offset, main_pass_count}.
    Dictionary instance_buffer_ptrs;  // <MapSpritePlacement, Vector4i>, but TypedDictionary doesn't support Vector4i.
    TypedDictionary<MapSpritePlacement, float> opacities;
    TypedDictionary<MapSpritePlacement, float> target_opacities;
    bool need_update = false;

    // Need to keep these ref'ed else it crashes on hot reload.
    // TODO: Still unreliable...
    Ref<MultiMesh> multi_mesh;
    Ref<QuadMesh> quad_mesh;

    // Custom instance data isn't supported on older hardware, so we use a texture for custom data instead.
    Ref<Image> custom_data_image;
    Ref<ImageTexture> custom_data_texture;

    // Buffer for instance data. Does not interact with Godot APIs.
    std::vector<MapInstanceData> instance_buffer;
};
