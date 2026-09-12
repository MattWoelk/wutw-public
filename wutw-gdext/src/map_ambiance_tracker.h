#pragma once

#include <godot_cpp/classes/ref.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include <array>
#include <unordered_map>
#include <vector>
#include <cstdint>

#include <map_biomes.h>

using namespace godot;

class MapAmbianceTracker : public RefCounted
{
    GDCLASS(MapAmbianceTracker, RefCounted);

public:
    MapAmbianceTracker() {}
    ~MapAmbianceTracker() {}

    void initialize(const PackedByteArray& p_biome_bitmap, Vector2i p_size);
    void reset();
    void update(Vector2 listener_position);
    TypedArray<Vector2i> get_biome_samples(MapBiomes::Biome biome) const;

    void set_hearing_radius(float r) {
        ERR_FAIL_COND_EDMSG(initialized, "Cannot be modified while initialized.");
        hearing_radius = r;
    }
    float get_hearing_radius() const { return hearing_radius; }

    void set_drop_radius(float r) {
        ERR_FAIL_COND_EDMSG(initialized, "Cannot be modified while initialized.");
        drop_radius = r;
    }
    float get_drop_radius() const { return drop_radius; }

    void set_min_spacing(float d) {
        ERR_FAIL_COND_EDMSG(initialized, "Cannot be modified while initialized.");
        ERR_FAIL_COND_MSG(d <= 0.f, "min_spacing must be > 0.");
        min_spacing = d;
    }
    float get_min_spacing() const { return min_spacing; }

    void set_max_samples_per_biome(int m) {
        ERR_FAIL_COND_EDMSG(initialized, "Cannot be modified while initialized.");
        ERR_FAIL_COND_MSG(m <= 0, "max_samples_per_biome must be > 0.");
        max_samples_per_biome = m;
    }
    int get_max_samples_per_biome() const { return max_samples_per_biome; }

protected:
    static void _bind_methods();

private:
    // Runtime config / state.
    bool initialized = false;
    PackedByteArray biome_bitmap;
    Vector2i size;

    // Config.
    float hearing_radius = 80.0f;
    float drop_radius = 120.0f;
    float min_spacing = 5.0f;
    int max_samples_per_biome = 32;

    // Internal data structures.
    using Sample = Vector2i;
    using CellKey = Vector2i;
    struct Vector2iHash {
        std::size_t operator()(const Vector2i& v) const noexcept {
            std::size_t h1 = std::hash<int>()(v.x);
            std::size_t h2 = std::hash<int>()(v.y);
            return h1 ^ (h2 + 0x9e3779b9 + (h1 << 6) + (h1 >> 2));
        }
    };
    struct PerBiomeData {
        std::vector<Sample> samples;
        // Grid cell -> indices into samples.
        std::unordered_map<Vector2i, std::vector<std::size_t>, Vector2iHash> grid;
    };

    std::array<PerBiomeData, MapBiomes::Biome::_NUM_BIOME_TYPES> biome_data;

    void prune_old_samples(const Vector2& listener);
    void rebuild_spatial_grids();
    bool has_neighbor_within_min_spacing(const PerBiomeData& data, const Vector2& pos) const;
    void clamp_samples_to_max(const Vector2& listener);

    inline MapBiomes::Biome get_biome(int x, int y) const {
        return MapBiomes::Biome(biome_bitmap[y * size.x + x]);
    }

    static inline std::uint8_t biome_to_index(MapBiomes::Biome biome) {
        return static_cast<std::uint8_t>(biome);
    }
};
