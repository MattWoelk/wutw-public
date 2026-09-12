#pragma once

#include <godot_cpp/classes/image.hpp>
#include <godot_cpp/classes/curve.hpp>
#include <godot_cpp/variant/color.hpp>
#include <godot_cpp/core/math.hpp>
#include <vector>
#include <cmath>

#include "map_generation_config.h"

using namespace godot;

class MapGenerator_ShardBase {
public:
    MapGenerator_ShardBase(Vector2i size,
        const PackedByteArray& biome_bitmap,
        const PackedByteArray& clouds_sdf,
        const Ref<MapShardBottomConfig> config)
        : size(size), biome_bitmap(biome_bitmap), clouds_sdf(clouds_sdf), config(config) {}

    struct OutlineSection {
        std::vector<Vector2i> points;
        int min_y;
        int max_y;

        OutlineSection(const std::vector<Vector2i>& points) : points(points) {
            min_y = max_y = points.front().y;
            for (auto& p : points) {
                min_y = std::min(min_y, p.y);
                max_y = std::max(max_y, p.y);
            }
        }

        Vector2i start() const { return points.front(); }
        Vector2i end() const { return points.back(); }
        float find_closest_y(float x) const;
    };

    std::vector<OutlineSection> get_shard_outline_sections();
    Ref<Image> draw_shard_outline_sections(const std::vector<OutlineSection>& sections);
    PackedByteArray generate_distance_to_land(const Ref<Image>& shard_base_image);
    Ref<Image> generate_land_depth(const std::vector<OutlineSection>& sections, const Ref<Image>& shard_base_image);
    TypedArray<Vector2> generate_edge_clouds(const std::vector<OutlineSection>& sections);

private:
    const Vector2i size;
    const PackedByteArray biome_bitmap;
    const PackedByteArray clouds_sdf;
    const Ref<MapShardBottomConfig> config;

    float signed_distance_point_to_line(const Vector2& point, const Vector2& line_start, const Vector2& line_end) const;
    bool is_land(int x, int y) const;
};
