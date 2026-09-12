#pragma once

#include <vector>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include "quad_tree.h"

class RoadCreator : public Resource
{
    GDCLASS(RoadCreator, Resource);

public:
    RoadCreator() {}
    ~RoadCreator() {}

    void initialize(Vector2i map_size, const PackedByteArray& clip_sdf, float sdf_range, Ref<QuadTree> quad_tree);

    PackedVector2Array find_road(Vector2 src_center, float src_radius, Vector2 dst_center, float dst_radius) const;

    void set_min_step(float s) { min_step = s; }
    float get_min_step() const { return min_step; }
    void set_max_step(float s) { max_step = s; }
    float get_max_step() const { return max_step; }
    void set_ray_angles(PackedFloat32Array s) { ray_angles = s; }
    PackedFloat32Array get_ray_angles() const { return ray_angles; }
    void set_target_bias(float s) { target_bias = s; }
    float get_target_bias() const { return target_bias; }
    void set_max_node_count(int s) { max_node_count = s; }
    int get_max_node_count() const { return max_node_count; }

protected:
    static void _bind_methods();

private:
    bool _is_segment_pathable(Vector2 a, Vector2 b) const;
    bool _is_on_land(Vector2 coord) const;

    // State set in initialize()
    Vector2i map_size;
    PackedByteArray clip_sdf;  // A copy-on-write reference, which we never write to.
    float sdf_range = -1.f;
    Ref<QuadTree> quad_tree;

    // Tunable constants.
    float min_step = 1.5f;
    float max_step = 5.f;
    PackedFloat32Array ray_angles = { -18.f, -9.f, -5.f, 6.f, 11.f, 17.f, };
    float target_bias = 0.25f;
    int max_node_count = 50000;
};
