#pragma once

#include <random>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>

using namespace godot;

namespace utils {
    float sample_aa(const PackedByteArray& sdf, const Vector2& coord, const Vector2i& size);
    inline float remap(float value, float inMin, float inMax, float outMin, float outMax) {
        if (inMax == inMin) return inMax;
        return (value - inMin) * (outMax - outMin) / (inMax - inMin) + outMin;
    }

    float pack_vec2(Vector2 v);

    // Portable versions of std::*_distribution.
    int uniform_int_distribution(std::mt19937& rng, int min, int max);
    float uniform_real_distribution(std::mt19937& rng, float min, float max);
    size_t discrete_distribution(std::mt19937& rng, const std::vector<float>& weights);
    template<class RandomIt, class URBG>
    void shuffle(RandomIt first, RandomIt last, URBG&& g) {
        using diff_t = typename std::iterator_traits<RandomIt>::difference_type;
        diff_t n = last - first;
        for (diff_t i = n - 1; i > 0; --i) {
            diff_t j = uniform_int_distribution(g, 0, static_cast<int>(i));
            std::swap(first[i], first[j]);
        }
    }
}
