#include "map_ambiance_tracker.h"

#include <godot_cpp/core/error_macros.hpp>
#include <godot_cpp/core/math.hpp>

#include <algorithm>
#include <cmath>
#include <numeric>

using namespace godot;

void MapAmbianceTracker::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("initialize", "biome_bitmap", "size"), &MapAmbianceTracker::initialize);
    ClassDB::bind_method(D_METHOD("reset"), &MapAmbianceTracker::reset);
    ClassDB::bind_method(D_METHOD("update", "listener_position"), &MapAmbianceTracker::update);
    ClassDB::bind_method(D_METHOD("get_biome_samples", "biome"), &MapAmbianceTracker::get_biome_samples);

    ClassDB::bind_method(D_METHOD("set_hearing_radius", "r"), &MapAmbianceTracker::set_hearing_radius);
    ClassDB::bind_method(D_METHOD("get_hearing_radius"), &MapAmbianceTracker::get_hearing_radius);

    ClassDB::bind_method(D_METHOD("set_drop_radius", "r"), &MapAmbianceTracker::set_drop_radius);
    ClassDB::bind_method(D_METHOD("get_drop_radius"), &MapAmbianceTracker::get_drop_radius);

    ClassDB::bind_method(D_METHOD("set_min_spacing", "d"), &MapAmbianceTracker::set_min_spacing);
    ClassDB::bind_method(D_METHOD("get_min_spacing"), &MapAmbianceTracker::get_min_spacing);

    ClassDB::bind_method(D_METHOD("set_max_samples_per_biome", "m"), &MapAmbianceTracker::set_max_samples_per_biome);
    ClassDB::bind_method(D_METHOD("get_max_samples_per_biome"), &MapAmbianceTracker::get_max_samples_per_biome);

    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "hearing_radius"), "set_hearing_radius", "get_hearing_radius");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "drop_radius"), "set_drop_radius", "get_drop_radius");
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_spacing"), "set_min_spacing", "get_min_spacing");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "max_samples_per_biome"), "set_max_samples_per_biome", "get_max_samples_per_biome");
}

void MapAmbianceTracker::initialize(const PackedByteArray& p_biome_bitmap, Vector2i p_size)
{
    ERR_FAIL_COND_EDMSG(initialized, "MapAmbianceTracker is already initialized. Call reset() before re-initializing.");
    ERR_FAIL_COND_MSG(p_size.x <= 0 || p_size.y <= 0, "Size must be positive.");
    ERR_FAIL_COND_MSG(p_biome_bitmap.size() < p_size.x * p_size.y, "Biome bitmap size is smaller than width*height.");
    ERR_FAIL_COND_MSG(hearing_radius <= 0.0f, "hearing_radius must be > 0.");
    ERR_FAIL_COND_MSG(drop_radius <= 0.0f, "drop_radius must be > 0.");
    ERR_FAIL_COND_MSG(min_spacing <= 0.0f, "min_spacing must be > 0.");
    ERR_FAIL_COND_MSG(max_samples_per_biome <= 0, "max_samples_per_biome must be > 0.");

    biome_bitmap = p_biome_bitmap;
    size = p_size;
    for (auto& data : biome_data) {
        data.samples.clear();
        data.grid.clear();
    }
    initialized = true;
}

void MapAmbianceTracker::reset()
{
    biome_bitmap = PackedByteArray();
    size = Vector2i();
    for (auto& data : biome_data) {
        data.samples.clear();
        data.grid.clear();
    }
    initialized = false;
}

void MapAmbianceTracker::prune_old_samples(const Vector2& listener)
{
    const float drop_radius_sq = drop_radius * drop_radius;

    for (auto& data : biome_data) {
        if (data.samples.empty()) {
            data.grid.clear();
            continue;
        }

        std::vector<Sample> kept;
        kept.reserve(data.samples.size());

        for (const Sample& s : data.samples) {
            const Vector2 delta = s - listener;
            if (delta.x * delta.x + delta.y * delta.y <= drop_radius_sq) {
                kept.push_back(s);
            }
        }

        data.samples.swap(kept);
        data.grid.clear();
    }
}

void MapAmbianceTracker::rebuild_spatial_grids()
{
    const float inv_cell_size = 1.0f / min_spacing;

    for (auto& data : biome_data) {
        data.grid.clear();
        if (data.samples.empty()) continue;

        for (size_t i = 0; i < data.samples.size(); ++i) {
            const Sample& s = data.samples[i];
            const int gx = (int)std::floor(s.x * inv_cell_size);
            const int gy = (int)std::floor(s.y * inv_cell_size);
            data.grid[CellKey(gx, gy)].push_back(i);
        }
    }
}

bool MapAmbianceTracker::has_neighbor_within_min_spacing(const PerBiomeData& data, const Vector2& pos) const
{
    if (data.samples.empty())  return false;

    const float inv_cell_size = 1.0f / min_spacing;
    const float min_dist_sq = min_spacing * min_spacing;

    const int gx0 = (int)std::floor(pos.x * inv_cell_size);
    const int gy0 = (int)std::floor(pos.y * inv_cell_size);

    for (int dy = -1; dy <= 1; ++dy) {
        for (int dx = -1; dx <= 1; ++dx) {
            CellKey key(gx0 + dx, gy0 + dy);
            auto it = data.grid.find(key);
            if (it == data.grid.end()) continue;

            const std::vector<std::size_t>& indices = it->second;
            for (std::size_t idx : indices) {
                const Sample& s = data.samples[idx];

                const float ddx = s.x - pos.x;
                const float ddy = s.y - pos.y;
                if (ddx * ddx + ddy * ddy < min_dist_sq) {
                    return true;
                }
            }
        }
    }

    return false;
}

void MapAmbianceTracker::clamp_samples_to_max(const Vector2& listener)
{
    const float lx = listener.x;
    const float ly = listener.y;

    for (auto& data : biome_data) {
        const size_t count = data.samples.size();
        if (count <= max_samples_per_biome) continue;

        // Create index list 0..count-1 and sort by distance to listener.
        std::vector<std::size_t> indices(count);
        std::iota(indices.begin(), indices.end(), 0);
        std::sort(indices.begin(), indices.end(), [&](std::size_t a, std::size_t b) {
            const Sample& sa = data.samples[a];
            const Sample& sb = data.samples[b];

            const float dax = sa.x - lx;
            const float day = sa.y - ly;
            const float dbx = sb.x - lx;
            const float dby = sb.y - ly;

            const float da_sq = dax * dax + day * day;
            const float db_sq = dbx * dbx + dby * dby;

            return da_sq < db_sq;
        });

        std::vector<Sample> kept;
        kept.reserve(max_samples_per_biome);
        for (size_t i = 0; i < max_samples_per_biome; ++i) {
            kept.push_back(data.samples[indices[i]]);
        }

        data.samples.swap(kept);
        // Grid will be rebuilt in the next update.
    }
}

void MapAmbianceTracker::update(Vector2 listener_position)
{
    ERR_FAIL_COND_EDMSG(!initialized, "Must be initialized.");

    prune_old_samples(listener_position);
    rebuild_spatial_grids();

    const float hearing_radius_sq = hearing_radius * hearing_radius;

    // Compute tile bounding box around listener.
    const float min_x_f = listener_position.x - hearing_radius;
    const float max_x_f = listener_position.x + hearing_radius;
    const float min_y_f = listener_position.y - hearing_radius;
    const float max_y_f = listener_position.y + hearing_radius;
    const int min_x = std::max(0, (int)std::floor(min_x_f));
    const int max_x = std::min(size.x - 1, (int)std::ceil(max_x_f));
    const int min_y = std::max(0, (int)std::floor(min_y_f));
    const int max_y = std::min(size.y - 1, (int)std::ceil(max_y_f));

    for (int y = min_y; y <= max_y; ++y) {
        for (int x = min_x; x <= max_x; ++x) {
            const Vector2 pos(x, y);
            if (pos.distance_squared_to(listener_position) > hearing_radius_sq) continue;

            auto biome = get_biome(x, y);
            PerBiomeData& data = biome_data[biome_to_index(biome)];

            // Poisson-like condition: no neighbor within min_spacing.
            if (has_neighbor_within_min_spacing(data, pos)) continue;

            std::size_t sample_index = data.samples.size();
            data.samples.push_back(Sample(x, y));

            // Insert into grid so later tiles in this update see it.
            const float inv_cell_size = 1.0f / min_spacing;
            const int gx = (int)std::floor(x * inv_cell_size);
            const int gy = (int)std::floor(y * inv_cell_size);
            data.grid[CellKey(gx, gy)].push_back(sample_index);
        }
    }

    clamp_samples_to_max(listener_position);
}

TypedArray<Vector2i> MapAmbianceTracker::get_biome_samples(MapBiomes::Biome biome) const
{
    ERR_FAIL_COND_V_EDMSG(!initialized, {}, "Must be initialized.");
    TypedArray<Vector2i> result;

    const auto& data = biome_data[biome_to_index(biome)];
    result.resize(data.samples.size());
    for (size_t i = 0; i < data.samples.size(); ++i) {
        result[i] = data.samples[i];
    }

    return result;
}
