#pragma once

#include "map_generator.h"

using namespace godot;

class MapGenerator_SDF {
public:
    MapGenerator_SDF(Vector2i size,
        const PackedByteArray& biome_bitmap,
        Biome biome,
        float max_distance,
        int blur_radius,
        int height_override = 0)
        : size(size), biome_bitmap(biome_bitmap), biome(biome), max_distance(max_distance), blur_radius(blur_radius), height_override(height_override) {}

    // Returns raw and blurred.
    std::pair<PackedByteArray, PackedByteArray> generate();


private:
    const Vector2i size;
    const PackedByteArray& biome_bitmap;
    const Biome biome;
    const float max_distance;
    const int blur_radius;
    const int height_override;

    void edtf_2d(std::vector<float>& dist) const;
    void edtf_1d(const std::vector<float>& input, std::vector<float>& output, int length) const;
};
