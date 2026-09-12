#include "map_generator_basemap.h"
#include <unordered_set>
#include <utils.h>

PackedByteArray MapGenerator_Basemap::generate()
{
    // Setup input images.
    mask_image = basemap_config->get_texture_mask()->get_image();
    if (mask_image->get_width() != size.x || mask_image->get_height() != size.y) {
        mask_image = mask_image->duplicate();
        mask_image->resize(size.x, size.y, Image::INTERPOLATE_LANCZOS);
    }

    auto altitudes = basemap_config->get_texture_altitude();
    auto weights_array = altitudes.values();
    std::vector<float> weights;
    weights.reserve(weights_array.size());
    for (int i = 0; i < weights_array.size(); ++i) {
        weights.push_back(weights_array[i]);
    }
    auto altitude_index = use_legacy_distribution
        ? std::discrete_distribution<std::size_t>(weights.begin(), weights.end())(rng)
        : utils::discrete_distribution(rng, weights);
    altitude_image = Ref<Texture2D>(altitudes.keys()[altitude_index])->get_image();
    if (altitude_image->get_width() != size.x || altitude_image->get_height() != size.y) {
        altitude_image = altitude_image->duplicate();
        altitude_image->resize(size.x, size.y, Image::INTERPOLATE_LANCZOS);
    }

    // Setup noise.
    noise_mask = input_textures->get_noise_mask()->duplicate();
    noise_altitude = input_textures->get_noise_altitude()->duplicate();
    noise_moisture = input_textures->get_noise_moisture()->duplicate();
    noise_temperature = input_textures->get_noise_temperature()->duplicate();

    auto frequency = input_textures->get_noise_frequency() / 1000.0f;
    noise_mask->set_frequency(frequency);
    noise_altitude->set_frequency(frequency);
    noise_moisture->set_frequency(frequency);
    noise_temperature->set_frequency(frequency);

    if (use_legacy_distribution) {
        std::uniform_int_distribution<int> noise_seed_dist(0, 1000);
        noise_mask->set_seed(noise_seed_dist(rng));
        noise_altitude->set_seed(noise_seed_dist(rng));
        noise_moisture->set_seed(noise_seed_dist(rng));
        noise_temperature->set_seed(noise_seed_dist(rng));
    } else {
        noise_mask->set_seed(utils::uniform_int_distribution(rng, 0, 1000));
        noise_altitude->set_seed(utils::uniform_int_distribution(rng, 0, 1000));
        noise_moisture->set_seed(utils::uniform_int_distribution(rng, 0, 1000));
        noise_temperature->set_seed(utils::uniform_int_distribution(rng, 0, 1000));
    }

    // Initialize output.
    biome_bitmap.resize(size.x * size.y);

    // Base layer.
    for (int x = 0; x < size.x; ++x) {
        for (int y = 0; y < size.y; ++y) {
            if (sample_mask(x, y) <= biome_config->get_min_mask_for_land()) {
                set_biome(x, y, Biome::CLOUDS);
            } else {
                float altitude = sample_altitude(x, y);
                if (altitude < biome_config->get_max_altitude_for_sea()) {
                    set_biome(x, y, Biome::SEA);
                } else {
                    float moisture = sample_moisture(x, y);
                    float temperature = sample_temperature(x, y);
                    if (moisture <= biome_config->get_max_moisture_for_dry_biome()) {
                        if (temperature >= biome_config->get_min_temperature_for_desert()) {
                            set_biome(x, y, Biome::DESERT);
                        } else {
                            set_biome(x, y, Biome::WASTELAND);
                        }
                    } else if (moisture <= biome_config->get_max_moisture_for_brushland()
                               && temperature <= biome_config->get_max_temperature_for_brushland()) {
                        set_biome(x, y, Biome::BRUSHLAND);
                    } else if (moisture <= biome_config->get_max_moisture_for_steppe()
                               && altitude <= biome_config->get_max_temperature_for_steppe()) {
                        set_biome(x, y, Biome::STEPPE);
                    } else {
                        set_biome(x, y, Biome::PLAINS);
                    }
                }
            }
        }
    }

    // Area layer.
    for (int x = 0; x < size.x; ++x) {
        for (int y = 0; y < size.y; ++y) {
            Biome base_biome = sample_biome(x, y);
            if (base_biome == Biome::CLOUDS) continue;

            float altitude = sample_altitude(x, y);
            if (base_biome == Biome::SEA) {
                if (altitude >= biome_config->get_min_altitude_for_seashore()) {
                    set_biome(x, y, Biome::SEASHORE);
                } else {
                    continue;
                }
            } else if (altitude >= biome_config->get_min_altitude_for_mountain()) {
                set_biome(x, y, Biome::MOUNTAIN);
            } else {
                float moisture = sample_moisture(x, y);
                if (can_place_swamp(base_biome)
                        && moisture >= biome_config->get_min_moisture_for_swamp()
                        && altitude <= biome_config->get_max_altitude_for_swamp()) {
                    set_biome(x, y, Biome::SWAMP);
                } else if (can_place_forest(base_biome)
                           && moisture >= biome_config->get_min_moisture_for_forest()) {
                    set_biome(x, y, Biome::FOREST);
                }
            }
        }
    }

    if (despeckle_max_tiles > 0) {
        despeckle();
    }

    return biome_bitmap;
}

void MapGenerator_Basemap::despeckle()
{
    auto tile_count = size.x * size.y;

    // Union-find helpers.
    std::vector<int> parent(tile_count);
    for (int i = 0; i < tile_count; ++i) {
        parent[i] = i;
    }
    auto find = [&](int i) {
        while (i != parent[i]) {
            parent[i] = parent[parent[i]];  // Path compression.
            i = parent[i];
        }
        return i;
    };
    auto union_sets = [&](int a, int b) {
        a = find(a);
        b = find(b);
        if (a != b) {
            parent[b] = a;
        }
    };

    // First pass: label & union identical neighbours.
    std::vector<int> comp_id(tile_count);
    const std::array<Vector2i, 4> PREV_OFFSETS = {
        Vector2i(-1,  0),
        Vector2i(0, -1),
        Vector2i(-1, -1),
        Vector2i(1, -1)
    };

    int idx = 0;
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            auto cur_biome = sample_biome(x, y);
            for (auto off : PREV_OFFSETS) {
                int nx = x + off.x;
                int ny = y + off.y;
                if (nx < 0 || ny < 0) continue;
                if (sample_biome(nx, ny) == cur_biome) {
                    union_sets(idx, ny * size.x + nx);
                }
            }
            comp_id[idx] = idx;  // Temporary; final root stored later.
            ++idx;
        }
    }

    // Count component sizes + path-compress.
    std::unordered_map<int, int> comp_size;
    for (int i = 0; i < tile_count; ++i) {
        int root = find(i);
        comp_id[i] = root;
        comp_size[root] += 1;
    }

    // Collect speckle roots.
    std::unordered_set<int> speckle_roots;
    for (auto& kv : comp_size) {
        if (kv.second <= despeckle_max_tiles) {
            speckle_roots.insert(kv.first);
        }
    }
    if (speckle_roots.empty()) {
        return;
    }

    // Gather border statistics for each speckle.
    std::unordered_map<int, std::unordered_map<Biome, int>> border_stats;
    for (int root : speckle_roots) {
        border_stats[root] = {};
    }

    idx = 0;
    const std::array<Vector2i, 4> FOUR_WAY_OFFSETS = {
        Vector2i(-1,  0),
        Vector2i(1,  0),
        Vector2i(0, -1),
        Vector2i(0,  1)
    };
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            int root = comp_id[idx];
            if (!speckle_roots.count(root)) {
                ++idx;
                continue;
            }

            for (auto off : FOUR_WAY_OFFSETS) {
                int nx = x + off.x;
                int ny = y + off.y;
                int nb_root = -1;
                auto nb_biome = sample_biome(nx, ny);

                if (nx >= 0 && nx < size.x && ny >= 0 && ny < size.y) {
                    nb_root = comp_id[ny * size.x + nx];
                }

                if (nb_root != root) {
                    border_stats[root][nb_biome] += 1;
                }
            }
            ++idx;
        }
    }

    // choose replacement biome = majority of the border
    std::unordered_map<int, Biome> replacement;
    for (int root : speckle_roots) {
        Biome best = Biome::_NUM_BIOME_TYPES;  // Invalid.
        int best_cnt = -1;
        for (auto& kv : border_stats[root]) {
            if (kv.second > best_cnt) {
                best_cnt = kv.second;
                best = kv.first;
            }
        }
        replacement[root] = best;
    }

    // Repaint all speckle tiles.
    idx = 0;
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            int root = comp_id[idx];
            if (speckle_roots.count(root)) {
                set_biome(x, y, replacement[root]);
            }
            ++idx;
        }
    }
}

float MapGenerator_Basemap::sample_mask(int x, int y) const
{
    ERR_FAIL_INDEX_V_EDMSG(x, size.x, false, "Mask x index out of range.");
    ERR_FAIL_INDEX_V_EDMSG(y, size.y, false, "Mask y index out of range.");
    float noise = noise_mask->get_noise_2d(x, y);
    return mask_image->get_pixel(x, y).r - noise * 0.3;
}

float MapGenerator_Basemap::sample_altitude(int x, int y) const
{
    ERR_FAIL_INDEX_V_EDMSG(x, size.x, false, "Altitude x index out of range.");
    ERR_FAIL_INDEX_V_EDMSG(y, size.y, false, "Altitude y index out of range.");

    constexpr float MIN_BASE_ALTITUDE = 0.3f;
    float base_altitude = altitude_image->get_pixel(x, y).r;
    if (base_altitude <= MIN_BASE_ALTITUDE) {
        return base_altitude;
    }

    float shard_top_skew = 0;
    auto curve = basemap_config->get_altitude_skew_curve();
    if (curve.is_valid()) {
        shard_top_skew = curve->sample(y / float(size.y));
    }

    float noise = noise_altitude->get_noise_2d(x, y) * 0.5f + 0.5f;
	return Math::clamp(base_altitude * MIN_BASE_ALTITUDE + noise * (1.f - MIN_BASE_ALTITUDE) + shard_top_skew,
                       base_altitude >= 1.f ? 0.5f : 0.3f, 1.f);
}

float MapGenerator_Basemap::sample_moisture(int x, int y) const
{
    ERR_FAIL_INDEX_V_EDMSG(x, size.x, false, "Moisture x index out of range.");
    ERR_FAIL_INDEX_V_EDMSG(y, size.y, false, "Moisture y index out of range.");
    constexpr float ALTITUDE_IMPACT = 0.1f;
    float moisture = noise_moisture->get_noise_2d(x, y) * 0.5f + 0.5f;
    float altitude = noise_altitude->get_noise_2d(x, y) * 0.5f + 0.5f;
    return moisture * (1.f + ALTITUDE_IMPACT) - altitude * ALTITUDE_IMPACT;
}

float MapGenerator_Basemap::sample_temperature(int x, int y) const
{
    ERR_FAIL_INDEX_V_EDMSG(x, size.x, false, "Temperature x index out of range.");
    ERR_FAIL_INDEX_V_EDMSG(y, size.y, false, "Temperature y index out of range.");
    constexpr float ALTITUDE_IMPACT = 0.1f;
    float temperature = noise_temperature->get_noise_2d(x, y) * 0.5f + 0.5f;
    float altitude = noise_altitude->get_noise_2d(x, y) * 0.5f + 0.5f;
    return temperature * (1.f - ALTITUDE_IMPACT) + altitude * ALTITUDE_IMPACT;
}

Biome MapGenerator_Basemap::sample_biome(int x, int y) const
{
    if (unlikely(x < 0 || x >= size.x)) return Biome::CLOUDS;
    if (unlikely(y < 0 || y >= size.y)) return Biome::CLOUDS;
    return static_cast<Biome>(biome_bitmap[y * size.x + x]);
}

void MapGenerator_Basemap::set_biome(int x, int y, Biome biome)
{
    ERR_FAIL_INDEX_EDMSG(x, size.x, "Biome x index out of range.");
    ERR_FAIL_INDEX_EDMSG(y, size.y, "Biome y index out of range.");
    biome_bitmap[y * size.x + x] = biome;
}

bool MapGenerator_Basemap::can_place_forest(Biome biome) const
{
    switch (biome) {
        case Biome::PLAINS:
        case Biome::BRUSHLAND:
            return true;
        default:
            return false;
    }
}

bool MapGenerator_Basemap::can_place_swamp(Biome biome) const
{
    switch (biome) {
    case Biome::PLAINS:
    case Biome::BRUSHLAND:
    case Biome::STEPPE:
        return true;
    default:
        return false;
    }
}
