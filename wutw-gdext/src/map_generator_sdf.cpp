#include "map_generator_sdf.h"

#include <godot_cpp/classes/global_constants.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/core/math.hpp>
#include <vector>
#include <cmath>
#include <algorithm>

using namespace godot;

static constexpr float LONG_DISTANCE = 1e6f;

std::pair<PackedByteArray, PackedByteArray> MapGenerator_SDF::generate() {
    // Allocate intermediate and output buffers.
    std::vector<float> inside_dist(size.y * size.x, LONG_DISTANCE);
    std::vector<float> outside_dist(size.y * size.x, LONG_DISTANCE);

    // Precompute inside/outside initial distances.
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            uint8_t v = biome_bitmap[y * size.x + x];
            if (v == biome) {
                inside_dist[y * size.x + x] = 0.0f;
            } else {
                outside_dist[y * size.x + x] = 0.0f;
            }
        }
    }

    // Run 1D EDT vertically then horizontally.
    edtf_2d(inside_dist);
    edtf_2d(outside_dist);

    // Build difference, normalize, and write raw and blurred.
    PackedByteArray raw_output;
    PackedByteArray blurred_output;
    raw_output.resize(size.x * size.y);
    blurred_output.resize(size.x * size.y);
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            // Raw.
            float raw = inside_dist[y * size.x + x] - outside_dist[y * size.x + x];
            float raw_dist = Math::clamp(raw, -max_distance, max_distance);
            raw_output[y * size.x + x] = int((raw_dist / max_distance) * 127.0f + 128.0f);

            // Blurred.
            float sum = 0.0f;
            int count = 0;
            for (int ky = -blur_radius; ky <= blur_radius; ++ky) {
                for (int kx = -blur_radius; kx <= blur_radius; ++kx) {
                    int px = Math::clamp(x + kx, 0, size.x - 1);
                    int py = Math::clamp(y + ky, 0, size.y - 1);
                    sum += inside_dist[py * size.x + px] - outside_dist[py * size.x + px];
                    count += 1;
                }
            }
            float sdf = sum / count;
            float blurred_dist = Math::clamp(sdf, -max_distance, max_distance);
            blurred_output[y * size.x + x] = int((blurred_dist / max_distance) * 127.0f + 128.0f);
        }
    }

    return { raw_output, blurred_output };
}

void MapGenerator_SDF::edtf_2d(std::vector<float>& dist) const {
    // 2D EDT via two 1D passes.
    
    // Vertical pass.
    std::vector<float> column(size.y);;
    std::vector<float> output_v(size.y);
    for (int x = 0; x < size.x; ++x) {
        for (int y = 0; y < size.y; ++y) {
            column[y] = dist[y * size.x + x];
        }
        edtf_1d(column, output_v, size.y);
        for (int y = 0; y < size.y; ++y) {
            dist[y * size.x + x] = output_v[y];
        }
    }

    // Horizontal pass.
    std::vector<float> row(size.x);
    std::vector<float> output_h(size.x);
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            row[x] = dist[y * size.x + x];
        }
        edtf_1d(row, output_h, size.x);
        for (int x = 0; x < size.x; ++x) {
            dist[y * size.x + x] = std::sqrt(output_h[x]);
        }
    }
}

void MapGenerator_SDF::edtf_1d(const std::vector<float>& input, std::vector<float>& output, int length) const {
    // 1D squared distance transform (Felzenszwalb & Huttenlocher). A.k.a. magic.
    std::vector<int> parabola_indices;
    std::vector<float> boundary_positions;

    parabola_indices.reserve(length);
    boundary_positions.reserve(length + 2);

    // Initialize.
    parabola_indices.push_back(0);
    boundary_positions.push_back(-LONG_DISTANCE);
    boundary_positions.push_back(LONG_DISTANCE);

    int curr = 0;
    // Build lower envelope.
    for (int q = 1; q < length; ++q) {
        float s = 0;
        while (true) {
            int  p = parabola_indices[curr];
            float num = (input[q] + q * q) - (input[p] + p * p);
            float den = 2.0f * (q - p);
            s = num / den;
            if (s <= boundary_positions[curr]) {
                // Pop.
                curr--;
                parabola_indices.pop_back();
                boundary_positions.pop_back();
            } else {
                break;
            }
        }
        curr++;
        parabola_indices.push_back(q);
        if (boundary_positions.size() > size_t(curr)) {
            boundary_positions[curr] = s;
        } else {
            boundary_positions.push_back(s);
        }
        boundary_positions.push_back(LONG_DISTANCE);
    }

    // Compute distances.
    curr = 0;
    for (int i = 0; i < length; ++i) {
        while (boundary_positions[curr + 1] < i) {
            curr++;
        }
        int p = parabola_indices[curr];
        float diff = i - p;
        output[i] = diff * diff + input[p];
    }
}
