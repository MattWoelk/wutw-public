#include "road_creator.h"

#include <vector>
#include <queue>
#include <random>
#include <unordered_map>
#include <cmath>
#include <map_sprite_placer.h>
#include <utils.h>

struct RoadNode {
    Vector2 pos;
    float angle;
    float length;
    float dist_to_dest;
    int parent_idx;

    float f_cost() const { return length / 2.0 + dist_to_dest; }
};

struct NodeCompare {
    const std::vector<RoadNode>& pool;
    NodeCompare(const std::vector<RoadNode>& p) : pool(p) {}

    bool operator()(int a, int b) const {
        return pool[a].f_cost() > pool[b].f_cost();
    }
};

void RoadCreator::initialize(Vector2i map_size, const PackedByteArray& clip_sdf, float sdf_range, Ref<QuadTree> quad_tree)
{
    ERR_FAIL_COND_EDMSG(map_size.x <= 0 || map_size.y <= 0, "Map size must be greater than zero.");
    ERR_FAIL_COND_EDMSG(sdf_range <= 1, "SDF range must be greater than 1.");
    ERR_FAIL_COND_EDMSG(!quad_tree.is_valid(), "Quad tree must be valid.");
    ERR_FAIL_COND_EDMSG(quad_tree->get_boundary() != Rect2(Vector2(0, 0), map_size), "Quad tree must be initialized to the map size.");
    this->map_size = map_size;
    this->clip_sdf = clip_sdf;
    this->sdf_range = sdf_range;
    this->quad_tree = quad_tree;
}

void RoadCreator::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("initialize", "map_size", "clip_sdf", "sdf_range", "quad_tree"), &RoadCreator::initialize);
    ClassDB::bind_method(D_METHOD("find_road", "src_center", "src_radius", "dst_center", "dst_radius"), &RoadCreator::find_road);

    ClassDB::bind_method(D_METHOD("set_min_step", "min_step"), &RoadCreator::set_min_step);
    ClassDB::bind_method(D_METHOD("get_min_step"), &RoadCreator::get_min_step);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_step"), "set_min_step", "get_min_step");

    ClassDB::bind_method(D_METHOD("set_max_step", "max_step"), &RoadCreator::set_max_step);
    ClassDB::bind_method(D_METHOD("get_max_step"), &RoadCreator::get_max_step);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "max_step"), "set_max_step", "get_max_step");

    ClassDB::bind_method(D_METHOD("set_ray_angles", "ray_angles"), &RoadCreator::set_ray_angles);
    ClassDB::bind_method(D_METHOD("get_ray_angles"), &RoadCreator::get_ray_angles);
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_FLOAT32_ARRAY, "ray_angles"), "set_ray_angles", "get_ray_angles");

    ClassDB::bind_method(D_METHOD("set_target_bias", "target_bias"), &RoadCreator::set_target_bias);
    ClassDB::bind_method(D_METHOD("get_target_bias"), &RoadCreator::get_target_bias);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "target_bias"), "set_target_bias", "get_target_bias");

    ClassDB::bind_method(D_METHOD("set_max_node_count", "max_node_count"), &RoadCreator::set_max_node_count);
    ClassDB::bind_method(D_METHOD("get_max_node_count"), &RoadCreator::get_max_node_count);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "max_node_count"), "set_max_node_count", "get_max_node_count");
}

PackedVector2Array RoadCreator::find_road(Vector2 src_center, float src_radius, Vector2 dst_center, float dst_radius) const
{
    std::mt19937 rng;
    rng.seed();
    std::vector<RoadNode> all_nodes;
    NodeCompare comp(all_nodes);
    std::priority_queue<int, std::vector<int>, NodeCompare> open_set(comp);

    // Key: grid cell & quantized angle.
    auto get_spatial_key = [](Vector2 pos, float angle) -> size_t {
        static_assert(sizeof(size_t) >= 6, "This hashing scheme requires size_t to be at least 48 bits.");
        size_t x = static_cast<int16_t>(pos.x);
        size_t y = static_cast<int16_t>(pos.y);
        size_t a = static_cast<int16_t>(fmod(Math::rad_to_deg(angle) + 360.0f, 360.0f) / 20.0f);
        return x | (y << 16) | (a << 32);
    };
    std::unordered_map<size_t, float> visited;

    // Start in all directions.
    for (float angle = -Math_PI; angle < Math_PI; angle += Math_PI / 12.f) {
        all_nodes.push_back({
            src_center,
            angle,
            0.f,
            src_center.distance_to(dst_center) - dst_radius,
            -1
        });
        open_set.push(all_nodes.size() - 1);
    }

    // Exploration loop.
    while (!open_set.empty()) {
        int current_idx = open_set.top();
        open_set.pop();
        const auto current = all_nodes[current_idx];  // Need to copy because all_nodes may reallocate below.

        // Are we there yet?
        auto dist_to_dst = current.pos.distance_to(dst_center);
        if (dist_to_dst <= dst_radius + max_step) {
            auto final_dir = (dst_center - current.pos).normalized();
            auto edge_pos = dst_center - (final_dir * dst_radius);

            if (edge_pos.x < 0 || edge_pos.x >= map_size.x || edge_pos.y < 0 || edge_pos.y >= map_size.y) continue;

            if (_is_segment_pathable(current.pos, edge_pos)) {
                // Reconstruct path.
                PackedVector2Array path; path.push_back(edge_pos);
                auto trace_idx = current_idx;
                while (trace_idx != -1) {
                    auto pos = all_nodes[trace_idx].pos;
                    path.push_back(pos);
                    trace_idx = all_nodes[trace_idx].parent_idx;
                    if (pos.distance_to(src_center) < src_radius) {
                        break;
                    }
                }
                path.reverse();
                return path;
            }
        }

        // Fan expansion.
        float angle_to_dst = (dst_center - current.pos).angle();
        // Heuristic: bias toward destination.
        float search_center_angle = Math::lerp_angle(current.angle, angle_to_dst, target_bias);
        for (auto ray_angle : ray_angles) {
            auto next_angle = search_center_angle + Math::deg_to_rad(ray_angle);

            auto step_len = min_step + utils::uniform_real_distribution(rng, min_step, max_step);
            auto next_pos = current.pos + Vector2::from_angle(next_angle) * step_len;

            if (current.pos.distance_to(src_center) <= src_radius ||
                    _is_segment_pathable(current.pos, next_pos)) {
                float turn_diff = abs(UtilityFunctions::angle_difference(current.angle, next_angle));
                float new_length = current.length + step_len;
                float new_dist_to_dest = next_pos.distance_to(dst_center) - dst_radius;
                float new_cost = new_length / 2.f + new_dist_to_dest;  // Mirrors RoadNode::f_cost().

                size_t key = get_spatial_key(next_pos, next_angle);
                auto existing = visited.find(key);
                if (existing == visited.end() || new_cost < existing->second) {
                    visited[key] = new_cost;
                    all_nodes.push_back({ next_pos, next_angle, new_length, new_dist_to_dest, current_idx });
                    open_set.push(all_nodes.size() - 1);
                }
            }
        }

        if (all_nodes.size() > max_node_count) break;
    }

    return PackedVector2Array();
}

bool RoadCreator::_is_segment_pathable(Vector2 a, Vector2 b) const
{
    if (!_is_on_land(a) || !_is_on_land(b)) {
        return false;
    }

    // TODO: Use width.
    TypedArray<MapSpritePlacement> hits = quad_tree->query_line(a, b, true);
    for (int i = 0; i < hits.size(); ++i) {
        Ref<MapSpritePlacement> placement = hits[i];
        if (placement->get_sprite_type().is_valid() && !placement->get_sprite_type()->get_removable()) {
            return false;
        }
    }

    return true;
}

bool RoadCreator::_is_on_land(Vector2 coord) const
{
    if (coord.x < 0 || coord.x >= map_size.x || coord.y < 0 || coord.y >= map_size.y) return false;
    uint8_t quantized_distance = clip_sdf[static_cast<int>(coord.y) * map_size.x + static_cast<int>(coord.x)];
    return sdf_range * ((float(quantized_distance) - 127.5f) / 127.5f) >= 2.0;
}
