#include "utils.h"

#include <algorithm>
#include <utility>
#include <random>
#include <cstdint>
#include <vector>

float utils::sample_aa(const PackedByteArray& sdf, const Vector2& coord, const Vector2i& size)
{
    // Clamp coordinates to valid range.
    float x = std::clamp(coord.x, 0.f, size.x - 1.001f);
    float y = std::clamp(coord.y, 0.f, size.y - 1.001f);

    // Integer coordinates for the 4 relevant texels.
    int x0 = int(floor(x));
    int y0 = int(floor(y));
    int x1 = std::min(x0 + 1, size.x - 1);
    int y1 = std::min(y0 + 1, size.y - 1);

    // Fractional part (used for weighting).
    float fx = x - x0;
    float fy = y - y0;

    // Sample the relevant texels.
    float r00 = sdf[y0 * size.x + x0];
    float r10 = sdf[y0 * size.x + x1];
    float r01 = sdf[y1 * size.x + x0];
    float r11 = sdf[y1 * size.x + x1];

    // Weights for bilinear interpolation.
    float w00 = (1.0 - fx) * (1.0 - fy);
    float w10 = fx * (1.0 - fy);
    float w01 = (1.0 - fx) * fy;
    float w11 = fx * fy;

    // Bilinear interpolation.
    return r00 * w00 + r10 * w10 + r01 * w01 + r11 * w11;
}

float utils::pack_vec2(Vector2 v) {
    ERR_FAIL_COND_V_EDMSG(v.x < 0 || v.x > 1, 0.f, "Packed coordinates must be normalized. X is not.");
    ERR_FAIL_COND_V_EDMSG(v.y < 0 || v.y > 1, 0.f, "Packed coordinates must be normalized. Y is not.");
    // HACK: Some floating point weirdness happens when we pack zeroes.
    if (v.x == 0.f) v.x = 0.01;
    if (v.y == 0.f) v.y = 0.01;
    if (v.x == 1.f) v.x = 0.99;
    if (v.y == 1.f) v.y = 0.99;
    uint16_t xq = std::round(v.x * 65535.0f);
    uint16_t yq = std::round(v.y * 65535.0f);
    uint32_t packed = (uint32_t(xq) << 16) | uint32_t(yq);
    float f;
    std::memcpy(&f, &packed, sizeof(float));
    return f;
}

int utils::uniform_int_distribution(std::mt19937& rng, int min, int max) {
    // Hack: the ranges are the same in unsigned, but we guarantee wrapround.
    uint32_t umin = static_cast<uint32_t>(min);
    uint32_t umax = static_cast<uint32_t>(max);
    uint32_t range = umax - umin + 1;

    if (range == 0) return static_cast<int>(rng());

    // Highest multiple of range that fits in 32 bits.
    uint32_t limit = 0xFFFFFFFF - (0xFFFFFFFF % range);

    uint32_t val;
    do {
        val = rng();
    } while (val >= limit); // Reject values that cause modulo bias.

    return static_cast<int>(umin + (val % range));
}

float utils::uniform_real_distribution(std::mt19937& rng, float min, float max) {
    constexpr uint32_t FLOAT_MANTISSA_MAX = 1u << 24;
    // Take the top 24 bits.
    uint32_t r = rng() >> 8;
    // Division by a power of 2 is exact in floats.
    float normalized = static_cast<float>(r) / static_cast<float>(FLOAT_MANTISSA_MAX); // [0.0, 1.0)
    return min + normalized * (max - min);
}

size_t utils::discrete_distribution(std::mt19937& rng, const std::vector<float>& weights) {
    if (weights.empty()) return 0;

    float sum = 0.f;
    for (float w : weights) {
        sum += w;
    }

    uint32_t random_24_bits = rng() >> 8;  // 24-bit mantissa
    float normalized = static_cast<float>(random_24_bits) / static_cast<float>(1 << 24);
    float target = normalized * sum;
    float current_sum = 0.f;
    for (size_t i = 0; i < weights.size(); ++i) {
        current_sum += weights[i];
        if (target < current_sum) {
            return i;
        }
    }

    return weights.size() - 1;  // Safeguard
}
