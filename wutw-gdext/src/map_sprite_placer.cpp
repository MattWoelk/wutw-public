#include "map_sprite_placer.h"

#define _USE_MATH_DEFINES
#include <algorithm>
#include <math.h>
#include <deque>
#include <vector>
#include <numeric>

#include "utils.h"

void MapSpritePlacement::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_sprite_type", "type"), &MapSpritePlacement::set_sprite_type);
    ClassDB::bind_method(D_METHOD("get_sprite_type"), &MapSpritePlacement::get_sprite_type);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sprite_type", PROPERTY_HINT_RESOURCE_TYPE, "MapSpriteType"), "set_sprite_type", "get_sprite_type");
    
    ClassDB::bind_method(D_METHOD("set_location", "location"), &MapSpritePlacement::set_location);
    ClassDB::bind_method(D_METHOD("get_location"), &MapSpritePlacement::get_location);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "location"), "set_location", "get_location");

    ClassDB::bind_method(D_METHOD("set_scale", "scale"), &MapSpritePlacement::set_scale);
    ClassDB::bind_method(D_METHOD("get_scale"), &MapSpritePlacement::get_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "scale"), "set_scale", "get_scale");

    ClassDB::bind_method(D_METHOD("set_used_by", "used_by"), &MapSpritePlacement::set_used_by);
    ClassDB::bind_method(D_METHOD("get_used_by"), &MapSpritePlacement::get_used_by);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "used_by", PROPERTY_HINT_RESOURCE_TYPE, "MapSpritePlacement"), "set_used_by", "get_used_by");
}

void MapSpritePlacerConfig::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_sprite_types", "types"), &MapSpritePlacerConfig::set_sprite_types);
    ClassDB::bind_method(D_METHOD("get_sprite_types"), &MapSpritePlacerConfig::get_sprite_types);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "sprite_types",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteType"),
        "set_sprite_types", "get_sprite_types");
    
    ClassDB::bind_method(D_METHOD("set_min_distance_from_biome_edge", "distance"), &MapSpritePlacerConfig::set_min_distance_from_biome_edge);
    ClassDB::bind_method(D_METHOD("get_min_distance_from_biome_edge"), &MapSpritePlacerConfig::get_min_distance_from_biome_edge);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "min_distance_from_biome_edge"), "set_min_distance_from_biome_edge", "get_min_distance_from_biome_edge");
    
    ClassDB::bind_method(D_METHOD("set_parallax_factor", "factor"), &MapSpritePlacerConfig::set_parallax_factor);
    ClassDB::bind_method(D_METHOD("get_parallax_factor"), &MapSpritePlacerConfig::get_parallax_factor);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "parallax_factor"), "set_parallax_factor", "get_parallax_factor");

    ClassDB::bind_method(D_METHOD("set_cell_size", "size"), &MapSpritePlacerConfig::set_cell_size);
    ClassDB::bind_method(D_METHOD("get_cell_size"), &MapSpritePlacerConfig::get_cell_size);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "cell_size"), "set_cell_size", "get_cell_size");

    ClassDB::bind_method(D_METHOD("set_spacing_multiplier", "multiplier"), &MapSpritePlacerConfig::set_spacing_multiplier);
    ClassDB::bind_method(D_METHOD("get_spacing_multiplier"), &MapSpritePlacerConfig::get_spacing_multiplier);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "spacing_multiplier"), "set_spacing_multiplier", "get_spacing_multiplier");
}

void MapSpritePlacer::set_max_try_place_samples(int count)
{
    max_try_place_samples = count < 1 ? 1 : count;
}

int MapSpritePlacer::get_max_try_place_samples() const
{
    return max_try_place_samples;
}

void MapSpritePlacer::initialize(IntMapCoordinate map_size, const PackedByteArray& clip_sdf, float sdf_range, Ref<QuadTree> quad_tree, float dupe_decay, int rng_seed, bool use_legacy_distribution)
{
    ERR_FAIL_COND_EDMSG(map_size.x <= 0 || map_size.y <= 0, "Map size must be greater than zero.");
    ERR_FAIL_COND_EDMSG(sdf_range <= 1, "SDF range must be greater than 1.");
    ERR_FAIL_COND_EDMSG(!quad_tree.is_valid(), "Quad tree must be valid.");
    ERR_FAIL_COND_EDMSG(quad_tree->get_boundary() != Rect2(Vector2(0, 0), map_size), "Quad tree must be initialized to the map size.");
    ERR_FAIL_COND_EDMSG(dupe_decay < 0, "Dupe decay must be above zero.");
    this->map_size = map_size;
    this->clip_sdf = clip_sdf;
    this->default_sdf_range = sdf_range;
    this->dupe_decay = dupe_decay;
    this->quad_tree = quad_tree;
    this->use_legacy_distribution = use_legacy_distribution;
    rng.seed(rng_seed);
}

Ref<MapSpritePlacement> MapSpritePlacer::place_single(Ref<MapSpriteType> sprite_type, Vector2 coord, float scale_override)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!sprite_type.is_valid(), {}, "Sprite type can't be empty.");
    auto scale = scale_override < 0.0 ? sprite_type->get_default_scale() : scale_override;
    Ref<MapSpritePlacement> placement;
    placement.instantiate();
    placement->set_sprite_type(sprite_type);
    placement->set_location(coord);
    placement->set_scale(scale);

    auto collision = sprite_type->get_collision();
    for (int i = 0; i < collision.size(); ++i) {
        Ref<MapSpriteCollision> shape = collision[i];
        shape->add_to_quad_tree(placement, quad_tree, coord, scale);
    }

    return placement;
}

Ref<MapSpritePlacement> MapSpritePlacer::place_single_from_pool(TypedArray<MapSpriteType> sprite_types, Vector2 coord)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(sprite_types.is_empty(), {}, "Sprite types can't be empty.");
    auto prioritized_sprites = _prioritize_sprites(sprite_types, true);
    return place_single(_pick_sprite(prioritized_sprites).sprite, coord);
}

TypedArray<MapSpritePlacement> MapSpritePlacer::place_clump(
    TypedArray<MapSpriteType> sprite_types, Vector2 coord, int count, float max_distance,
    float packing_factor, float spacing_multiplier, Ref<MapSpriteType> initial_sprite_type)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(count <= 0, {}, "Count must be valid.");
    ERR_FAIL_COND_V_EDMSG(max_distance <= 0.f, {}, "Distance must be positive.");
    ERR_FAIL_COND_V_EDMSG(sprite_types.is_empty(), {}, "Sprite types can't be empty.");
    ERR_FAIL_COND_V_EDMSG(packing_factor < 0.f, {}, "Packing factor must be above zero.");

    // Initialize.
    TypedArray<MapSpritePlacement> result;
    std::deque<std::pair<Ref<MapSpriteType>, MapCoordinate>> active;

    // Distributions.
    auto prioritized_sprites = _prioritize_sprites(sprite_types, true);
    std::uniform_real_distribution<float> angle_dist(0.f, 2 * static_cast<float>(M_PI));
    std::uniform_real_distribution<float> unit_dist(0.f, 1.f);

    // Seed initial placement.
    constexpr int MAX_ATTEMPTS = 100;
    MapCoordinate init_pos = coord;
    auto init_picked_default = PrioritizedSprite{ initial_sprite_type, 0 };
    auto& init_picked = initial_sprite_type.is_valid() ? init_picked_default : _pick_sprite(prioritized_sprites);
    int attempts = 0;
    while ((init_pos - coord).length() > max_distance
        || !_can_place(init_pos, **init_picked.sprite, init_picked.sprite->get_default_scale(), nullptr, -1.f, 1.f)) {
        float theta = use_legacy_distribution
            ? angle_dist(rng)
            : utils::uniform_real_distribution(rng, 0.f, 2 * static_cast<float>(M_PI));
        float r = max_distance * std::sqrt(use_legacy_distribution
            ? unit_dist(rng)
            : utils::uniform_real_distribution(rng, 0.f, 1.f));
        init_pos = coord + MapCoordinate(r * std::cos(theta), r * std::sin(theta));
        init_picked = initial_sprite_type.is_valid() ? PrioritizedSprite{initial_sprite_type, 0} : _pick_sprite(prioritized_sprites);
        attempts++;
        if (attempts > MAX_ATTEMPTS) {
            WARN_PRINT_ED("Exhausted all attempts for initial placement.");
            return {};
        }
    }
    result.append(place_single(init_picked.sprite, init_pos));
    active.push_back({ init_picked.sprite, init_pos });
    init_picked.priority *= dupe_decay;

    // Poisson-disk style sampling.
    while (!active.empty() && result.size() < count) {
        auto current = active.front();
        active.pop_front();
        for (int i = 0; i < MAX_ATTEMPTS && result.size() < count; ++i) {
            auto& picked = _pick_sprite(prioritized_sprites);
            float theta = use_legacy_distribution
                ? angle_dist(rng)
                : utils::uniform_real_distribution(rng, 0.f, 2 * static_cast<float>(M_PI));
            float current_radius = current.first->get_footprint_radius() * current.first->get_default_scale() * spacing_multiplier;
            float picked_radius = picked.sprite->get_footprint_radius() * picked.sprite->get_default_scale();
            float rand_unit = std::sqrt(use_legacy_distribution
                ? unit_dist(rng)
                : utils::uniform_real_distribution(rng, 0.f, 1.f));
            float dist = (current_radius + picked_radius) * (1 + rand_unit * packing_factor);
            MapCoordinate candidate = current.second + MapCoordinate(dist * std::cos(theta), dist * std::sin(theta));
            // Stay within max distance.
            if ((candidate - coord).length() > max_distance) {
                continue;
            }

            float radius = picked.sprite->get_footprint_radius() * current.first->get_default_scale();
            if (_can_place(candidate, **picked.sprite, picked.sprite->get_default_scale(), nullptr, 0.f, spacing_multiplier)) {
                result.append(place_single(picked.sprite, candidate));
                active.push_back({ picked.sprite, candidate });
                picked.priority *= dupe_decay;
            }
        }
    }

    return result;
}

TypedArray<MapSpritePlacement> MapSpritePlacer::fill_biome(const PackedByteArray& biome_sdf, Ref<MapSpritePlacerConfig> config)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!config.is_valid(), {}, "Config cannot be empty.");
    ERR_FAIL_COND_V_EDMSG(config->get_sprite_types().is_empty(), {}, "Sprite types array cannot be empty.");
    ERR_FAIL_COND_V_EDMSG(config->get_cell_size() <= 0.0, {}, "Cell size must be greater than zero.");

    float biome_sdf_range = default_sdf_range - config->get_min_distance_from_biome_edge();
    auto patches = _get_biome_patches(biome_sdf);
    TypedArray<MapSpritePlacement> result;
    for (auto& patch : patches)
    {
        // Split into cells.
        std::vector<CandidateCell> cells;
        MapUnit cell_size = config->get_cell_size();
        for (MapUnit y = patch.rect.position.y; y < patch.rect.position.y + patch.rect.size.y; y += cell_size) {
            for (MapUnit x = patch.rect.position.x; x < patch.rect.position.x + patch.rect.size.x; x += cell_size) {
                MapCoordinate coord(x, y);
                MapUnit size_x = std::min(cell_size, patch.rect.get_end().x - x);
                MapUnit size_y = std::min(cell_size, patch.rect.get_end().y - y);
                MapCoordinate cell_rect_size = { size_x, size_y };
                MapUnit distance = _distance_to_boundary(biome_sdf, biome_sdf_range, coord + cell_rect_size / 2.f);
                if (distance < 0.0) {  // TODO: This can be the negative min footprint radius.
                    cells.push_back(CandidateCell{ Rect2(coord, {size_x, size_y}), distance });
                }
            }
        }
        std::stable_sort(cells.begin(), cells.end());  // Do inner cells first.

        // First pass: go from the center out, prioritizing large sprites.
        auto prioritized_sprites = _prioritize_sprites(config->get_sprite_types(), true);
        std::vector<CandidateCell> failed_cells;
        for (auto& cell : cells) {
            if (!_try_place_sprite(prioritized_sprites, cell, &biome_sdf, config, result, false)) {
                failed_cells.push_back(cell);
            }
        }

        // Second pass: try to fill failed cells with small sprites.
        prioritized_sprites = _prioritize_sprites(config->get_sprite_types(), false);
        
        if (use_legacy_distribution) {
            std::shuffle(failed_cells.begin(), failed_cells.end(), rng);
        } else {
            utils::shuffle(failed_cells.begin(), failed_cells.end(), rng);
        }
        for (auto& cell : failed_cells) {
            _try_place_sprite(prioritized_sprites, cell, &biome_sdf, config, result, true);
        }
    }

    return result;
}

TypedArray<MapSpritePlacement> MapSpritePlacer::fill_circle(Ref<MapSpritePlacerConfig> config, Vector2 center, float radius)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!config.is_valid(), {}, "Config cannot be empty.");
    ERR_FAIL_COND_V_EDMSG(config->get_sprite_types().is_empty(), {}, "Sprite types array cannot be empty.");
    ERR_FAIL_COND_V_EDMSG(config->get_cell_size() <= 0.0, {}, "Cell size must be greater than zero.");
    ERR_FAIL_COND_V_EDMSG(radius <= 0.0f, {}, "Radius must be greater than zero.");

    float biome_sdf_range = default_sdf_range - config->get_min_distance_from_biome_edge();
    TypedArray<MapSpritePlacement> result;

    MapCoordinate center_coord(center.x, center.y);
    MapUnit cell_size = config->get_cell_size();

    MapUnit min_x = std::max(0.0f, center.x - radius);
    MapUnit max_x = std::min(static_cast<MapUnit>(map_size.x), center.x + radius);
    MapUnit min_y = std::max(0.0f, center.y - radius);
    MapUnit max_y = std::min(static_cast<MapUnit>(map_size.y), center.y + radius);

    std::vector<CandidateCell> cells;

    for (MapUnit y = min_y; y < max_y; y += cell_size) {
        for (MapUnit x = min_x; x < max_x; x += cell_size) {
            MapCoordinate coord(x, y);
            MapUnit size_x = std::min(cell_size, max_x - x);
            MapUnit size_y = std::min(cell_size, max_y - y);
            if (size_x <= 0.f || size_y <= 0.f) {
                continue;
            }

            MapCoordinate cell_rect_size(size_x, size_y);
            MapCoordinate mid = coord + cell_rect_size / 2.f;

            // Restrict to circle.
            MapUnit distance = mid.distance_to(center_coord);
            if (distance > radius) {
                continue;
            }

            cells.push_back(CandidateCell{ Rect2(coord, { size_x, size_y }), distance });
        }
    }

    if (cells.empty()) {
        return result;
    }

    std::stable_sort(cells.begin(), cells.end());  // Do inner cells first.

    // First pass: center out, prioritizing large sprites.
    auto prioritized_sprites = _prioritize_sprites(config->get_sprite_types(), true);
    std::vector<CandidateCell> failed_cells;
    for (auto& cell : cells) {
        if (!_try_place_sprite(prioritized_sprites, cell, nullptr, config, result, false, true)) {
            failed_cells.push_back(cell);
        }
    }

    // Second pass: try to fill failed cells with small sprites.
    prioritized_sprites = _prioritize_sprites(config->get_sprite_types(), false);

    if (use_legacy_distribution) {
        std::shuffle(prioritized_sprites.begin(), prioritized_sprites.end(), rng);
    } else {
        utils::shuffle(prioritized_sprites.begin(), prioritized_sprites.end(), rng);
    }
    for (auto& cell : failed_cells) {
        _try_place_sprite(prioritized_sprites, cell, nullptr, config, result, true, true);
    }

    return result;
}


Ref<MapSpritePlacement> MapSpritePlacer::try_place_single(Ref<MapSpriteType> sprite_type, const PackedByteArray& biome_sdf, MapCoordinate search_origin, float max_distance, TypedArray<MapSpriteType> extra_removable, bool skip_clip, float clip_margin)
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), nullptr, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!sprite_type.is_valid(), nullptr, "Sprite type can't be empty.");
    ERR_FAIL_COND_V_EDMSG(max_distance <= 0.f, nullptr, "Max distance must be non-zero.");
    ERR_FAIL_COND_V_EDMSG(!biome_sdf.is_empty() && biome_sdf.size() != map_size.x * map_size.y, nullptr, "Biome SDF size mismatch.");

    const bool check_sdf = !biome_sdf.is_empty();

    const MapSpriteType& sprite = **sprite_type;
    float scale = sprite.get_default_scale();
    MapCoordinate origin(search_origin.x, search_origin.y);

    auto is_within_bounds = [this](const MapCoordinate& coord) {
        return coord.x >= 0.f && coord.y >= 0.f && coord.x < map_size.x && coord.y < map_size.y;
    };
    auto is_within_biome = [this, &check_sdf, &biome_sdf, &sprite_type](const MapCoordinate& coord) {
        if (check_sdf) {
            auto dist_to_boundary = _distance_to_boundary(biome_sdf, default_sdf_range, coord);
            return sprite_type->get_footprint_radius() <= -dist_to_boundary;
        } else {
            return true;
        }
     };

    bool found_any = false;
    MapCoordinate best_coord;
    float best_score = -1e10f;
    if (is_within_bounds(origin) &&
        is_within_biome(origin) &&
        (skip_clip || _passes_clip(sprite, origin, scale, clip_margin)) &&
        !_intersects_non_removable(**sprite_type, origin, scale, extra_removable)) {
        found_any = true;
        best_coord = origin;
        best_score = _evaluate_candidate(sprite_type, origin, biome_sdf, origin, max_distance);
    }

    std::uniform_real_distribution<float> angle_dist(0.f, 2.f * static_cast<float>(M_PI));
    std::uniform_real_distribution<float> unit_dist(0.f, 1.f);

    for (int i = 0; i < max_try_place_samples; ++i) {
        float theta = use_legacy_distribution
            ? angle_dist(rng)
            : utils::uniform_real_distribution(rng, 0.f, 2 * static_cast<float>(M_PI));
        float r = max_distance * std::sqrt(use_legacy_distribution
            ? unit_dist(rng)
            : utils::uniform_real_distribution(rng, 0.f, 1.f));
        MapCoordinate coord(origin.x + r * std::cos(theta), origin.y + r * std::sin(theta));

        if (!is_within_bounds(coord)) continue;
        if (!is_within_biome(coord)) continue;
        if (check_sdf && !_is_in_biome(&biome_sdf, default_sdf_range, coord)) continue;
        if (!skip_clip && !_passes_clip(sprite, coord, scale, clip_margin)) continue;
        if (_intersects_non_removable(**sprite_type, coord, scale, extra_removable)) continue;

        float score = _evaluate_candidate(sprite_type, coord, biome_sdf, origin, max_distance);
        if (!found_any || score > best_score) {
            found_any = true;
            best_score = score;
            best_coord = coord;
        }
    }

    if (found_any) {
        return place_single(sprite_type, best_coord, scale);
    } else {
        return nullptr;
    }
}

TypedArray<MapSpritePlacement> MapSpritePlacer::get_intersecting_sprites(Ref<MapSpriteType> sprite_type, MapCoordinate coord, float scale_override) const
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!sprite_type.is_valid(), {}, "Sprite type can't be empty.");
    ERR_FAIL_COND_V_EDMSG(!quad_tree.is_valid(), {}, "Quad tree must be set.");

    TypedArray<MapSpritePlacement> result;

    float scale = scale_override < 0 ? sprite_type->get_default_scale() : scale_override;
    auto collision = sprite_type->get_collision();
    for (int i = 0; i < collision.size(); ++i) {
        Ref<MapSpriteCollision> shape = collision[i];
        ERR_CONTINUE_EDMSG(!shape.is_valid(), "Invalid collision shape type at index " + String::num(i) + ".");
        if (!shape->is_blocking()) continue;

        TypedArray<MapSpritePlacement> hits = shape->query_quad_tree(quad_tree, coord, scale, true);
        for (int j = 0; j < hits.size(); ++j) {
            Ref<MapSpritePlacement> placement = hits[j];
            ERR_CONTINUE_EDMSG(!placement.is_valid(), "Invalid placement from QT query.");
            if (result.find(placement) == -1) {
                result.append(placement);
            }
        }
    }

    return result;
}

bool MapSpritePlacer::debug_passes_clip(Ref<MapSpriteType> sprite_type, MapCoordinate coord, float scale, float margin) const
{
    ERR_FAIL_COND_V_EDMSG(map_size == Vector2i(0, 0), {}, "Must be initialized.");
    ERR_FAIL_COND_V_EDMSG(!sprite_type.is_valid(), {}, "Sprite type can't be empty.");
    ERR_FAIL_COND_V_EDMSG(!quad_tree.is_valid(), {}, "Quad tree must be set.");
    return _passes_clip(**sprite_type, coord, scale, margin);
}

void MapSpritePlacer::reseed_random(int seed)
{
    rng.seed(seed);
}

void MapSpritePlacer::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("initialize", "map_size", "clip_sdf", "sdf_range", "quad_tree", "dupe_decay", "rng_seed", "use_legacy_distribution"), &MapSpritePlacer::initialize);
    ClassDB::bind_method(D_METHOD("place_single", "sprite_type", "coord", "scale"), &MapSpritePlacer::place_single, DEFVAL(-1.f));
    ClassDB::bind_method(D_METHOD("place_single_from_pool", "sprite_types", "coord"), &MapSpritePlacer::place_single_from_pool);
    ClassDB::bind_method(D_METHOD("place_clump", "sprite_types", "coord", "count", "max_distance", "packing_factor", "spacing_multiplier", "seed_sprite_type"), &MapSpritePlacer::place_clump, DEFVAL(0.2f), DEFVAL(1.0f), DEFVAL(Ref<MapSpriteType>()));
    ClassDB::bind_method(D_METHOD("fill_biome", "biome_sdf", "config"), &MapSpritePlacer::fill_biome);
    ClassDB::bind_method(D_METHOD("fill_circle", "config", "center", "radius"), &MapSpritePlacer::fill_circle);
    ClassDB::bind_method(D_METHOD("try_place_single", "sprite_type", "biome_sdf", "search_origin", "max_distance", "extra_removable", "skip_clip", "clip_margin"), &MapSpritePlacer::try_place_single, DEFVAL(TypedArray<MapSpriteType>()), DEFVAL(false), DEFVAL(1.f));
    ClassDB::bind_method(D_METHOD("get_intersecting_sprites", "sprite_type", "coord", "scale_override"), &MapSpritePlacer::get_intersecting_sprites, DEFVAL(-1.f));
    ClassDB::bind_method(D_METHOD("debug_passes_clip", "sprite_type", "coord", "scale", "margin"), &MapSpritePlacer::debug_passes_clip, DEFVAL(1.f));
    ClassDB::bind_method(D_METHOD("reseed_random", "seed"), &MapSpritePlacer::reseed_random);
    
    ClassDB::bind_method(D_METHOD("set_max_try_place_samples", "count"), &MapSpritePlacer::set_max_try_place_samples);
    ClassDB::bind_method(D_METHOD("get_max_try_place_samples"), &MapSpritePlacer::get_max_try_place_samples);
    ADD_PROPERTY(PropertyInfo(Variant::INT, "max_try_place_samples"), "set_max_try_place_samples", "get_max_try_place_samples");
}

std::vector<PrioritizedSprite> MapSpritePlacer::_prioritize_sprites(const TypedArray<MapSpriteType>& sprite_types, bool prefer_large)
{
    std::vector<PrioritizedSprite> result;
    for (int i = 0; i < sprite_types.size(); ++i) {
        Ref<MapSpriteType> sprite_type = sprite_types[i];
        ERR_CONTINUE_EDMSG(!sprite_type.is_valid(), "Invalid sprite type at index " + String::num(i) + ".");
        PrioritizedSprite ps;
        ps.sprite = sprite_type;
        MapUnit radius = sprite_type->get_footprint_radius() * sprite_type->get_default_scale();
        ps.priority = (prefer_large ? radius : (1.f / radius)) * sprite_type->get_priority_multiplier();
        result.push_back(ps);
    }
    return result;
}

std::vector<BiomePatch> MapSpritePlacer::_get_biome_patches(const PackedByteArray& biome_sdf) const
{
    const int w = map_size.x;
    const int h = map_size.y;

    // 1D visited array to mark which tiles we've already flood-filled.
    std::vector<bool> visited(w * h, false);

    std::deque<IntMapCoordinate> queue;
    const IntMapCoordinate dirs[4] = { {1,0}, {-1,0}, {0,1}, {0,-1} };

    std::vector<BiomePatch> result;
    for (int y = 0; y < h; ++y) {
        for (int x = 0; x < w; ++x) {
            int idx = y * w + x;
            IntMapCoordinate start(x, y);

            // Skip non-biome or already visited.
            if (visited[idx] || !_is_tile_in_biome(biome_sdf, start)) {
                continue;
            }

            // New region: initialize bounds.
            int min_x = x, max_x = x;
            int min_y = y, max_y = y;
            float area = 0.f;

            // Flood-fill.
            queue.clear();
            queue.push_back(start);
            visited[idx] = true;

            while (!queue.empty()) {
                IntMapCoordinate cur = queue.front();
                queue.pop_front();
                area += 1.f;

                min_x = std::min(min_x, cur.x);
                max_x = std::max(max_x, cur.x);
                min_y = std::min(min_y, cur.y);
                max_y = std::max(max_y, cur.y);

                // Explore neighbors.
                for (auto& d : dirs) {
                    int nx = cur.x + d.x;
                    int ny = cur.y + d.y;
                    if (nx < 0 || nx >= w || ny < 0 || ny >= h) continue;

                    int nidx = ny * w + nx;
                    IntMapCoordinate nb(nx, ny);
                    if (visited[nidx] || !_is_tile_in_biome(biome_sdf, nb)) {
                        continue;
                    }
                    visited[nidx] = true;
                    queue.push_back(nb);
                }
            }

            IntMapCoordinate origin(min_x, min_y);
            IntMapCoordinate size((max_x - min_x + 1), (max_y - min_y + 1));
            result.emplace_back(BiomePatch{ Rect2i(origin, size), area });
        }
    }

    return result;
}

bool MapSpritePlacer::_try_place_sprite(std::vector<PrioritizedSprite>& prioritized_sprites, const CandidateCell& cell,
    const PackedByteArray* biome_sdf, Ref<MapSpritePlacerConfig> config, TypedArray<MapSpritePlacement>& output, bool allow_min_scale, bool ignore_removable)
{
    auto& candidate_sprite = _pick_sprite(prioritized_sprites);
    // Randomly select a coordinate within the cell.
    MapCoordinate coord = cell.get_random_coord(rng, use_legacy_distribution);
    // Check if the sprite can be placed at the coordinate.
    const auto& sprite = **candidate_sprite.sprite;
    float effective_scale = _get_effective_scale(sprite, coord, config->get_parallax_factor(), false);
    float biome_sdf_range = default_sdf_range - config->get_min_distance_from_biome_edge();
    bool can_place = _can_place(coord, sprite, effective_scale, biome_sdf, biome_sdf_range, config->get_spacing_multiplier(), ignore_removable);
    if (!can_place && allow_min_scale && candidate_sprite.sprite->get_min_scale() < candidate_sprite.sprite->get_default_scale())
    {
        // Try again with the minimum scale.
        // TODO: Handle values between the two extremes.
        effective_scale = _get_effective_scale(sprite, coord, config->get_parallax_factor(), true);
        can_place = _can_place(coord, sprite, effective_scale, biome_sdf, biome_sdf_range, config->get_spacing_multiplier(), ignore_removable);
    }

    if (can_place) {
        output.append(place_single(candidate_sprite.sprite, coord, effective_scale));
        candidate_sprite.priority *= dupe_decay;
        return true;
    } else {
        return false;
    }
}

PrioritizedSprite& MapSpritePlacer::_pick_sprite(std::vector<PrioritizedSprite>& prioritized)
{
    std::vector<float> weights;
    weights.reserve(prioritized.size());
    float total = 0.0;
    for (auto& item : prioritized) {
        weights.push_back(item.priority);
        total += item.priority;
    }

    ;
    return prioritized[use_legacy_distribution
        ? std::discrete_distribution<size_t>(weights.begin(), weights.end())(rng)
        : utils::discrete_distribution(rng, weights)];
}

bool MapSpritePlacer::_can_place(const MapCoordinate& coord, const MapSpriteType& sprite, float scale,
    const PackedByteArray* biome_sdf, float biome_sdf_range, float spacing_multiplier, bool ignore_removable) const
{
    // Check distance to edge of biome.
    MapUnit radius = sprite.get_footprint_radius() * scale;
    if (biome_sdf) {
        MapUnit distance = _distance_to_boundary(*biome_sdf, biome_sdf_range, coord);
        if (radius > -distance) {
            return false;
        }
    }

    // Check intersection with existing sprites.
    if (ignore_removable) {
        TypedArray<MapSpritePlacement> hits = quad_tree->query_circle(coord, radius * spacing_multiplier, true);
        for (int j = 0; j < hits.size(); ++j) {
            Ref<MapSpritePlacement> placement = hits[j];
            ERR_CONTINUE_EDMSG(!placement.is_valid(), "Invalid placement from QT query.");
            Ref<MapSpriteType> other_type = placement->get_sprite_type();
            ERR_CONTINUE_EDMSG(!other_type.is_valid(), "Invalid sprite type in placement from QT query.");
            if (!other_type->get_removable()) {
                return false;
            }
        }
        if (_intersects_non_removable(sprite, coord, scale, TypedArray<MapSpriteType>())) {
            return false;
        }
    } else {
        if (quad_tree->intersects_circle(coord, radius * spacing_multiplier, true)) {
            return false;
        }
        auto collision = sprite.get_collision();
        for (int i = 0; i < collision.size(); ++i) {
            Ref<MapSpriteCollision> shape = collision[i];
            if (shape->is_blocking() && shape->intersects_quad_tree(quad_tree, coord, scale, true)) {
                return false;
            }
        }
    }

    // Ensure the bottom of the sprite is in the clip area.
    if (!_passes_clip(sprite, coord, scale)) {
        return false;
    }

    return true;
}

bool MapSpritePlacer::_passes_clip(const MapSpriteType& sprite, const MapCoordinate& coord, float scale, float margin) const
{
    if (sprite.get_ignore_clip()) {
        return true;
    }

    auto map_rect = sprite.get_map_rect();
    map_rect.position -= map_rect.size / 2.0;  // Centered by default.
    // Include collision. Mainly important for composites, which have no map rect.
    auto collision = sprite.get_collision();
    for (int i = 0; i < collision.size(); ++i) {
        Ref<MapSpriteCollision> shape = collision[i];
        map_rect = map_rect.merge(shape->get_bbox());
    }
    MapCoordinate half_size = (map_rect.size / 2.0f) * scale;
    MapCoordinate center = coord + map_rect.position * scale + half_size;
    if (half_size.x <= 0.01) {
        WARN_PRINT_ED(String("Using footprint for clip test for sprite: ") + sprite.get_name());
        half_size.x = sprite.get_footprint_radius();
        half_size.y = sprite.get_footprint_radius();
    }

    MapUnit bottom_y = center.y + half_size.y;
    if (!_is_in_clip(MapCoordinate(center.x - half_size.x, bottom_y), margin) ||
        !_is_in_clip(MapCoordinate(center.x, bottom_y), margin) ||
        !_is_in_clip(MapCoordinate(center.x + half_size.x, bottom_y), margin) ||
        !_is_in_clip(MapCoordinate(center.x - half_size.x, center.y), margin) ||
        !_is_in_clip(MapCoordinate(center.x + half_size.x, center.y), margin)) {
        return false;
    }

    // If requested, check the top of the sprite against the clip.
    if (sprite.get_must_be_fully_within_clip()) {
        MapUnit top_y = center.y - half_size.y;
        if (!_is_in_clip(MapCoordinate(center.x - half_size.x, top_y), margin) ||
            !_is_in_clip(MapCoordinate(center.x, top_y), margin) ||
            !_is_in_clip(MapCoordinate(center.x + half_size.x, top_y), margin)) {
            return false;
        }
    }

    return true;
}

float MapSpritePlacer::_get_effective_scale(const MapSpriteType& sprite, const MapCoordinate& coord, const Vector2& parallax_factor, bool use_min_scale) const
{
    auto effective_parallax_factor = utils::remap(coord.y, 0.f, map_size.y, parallax_factor.y, parallax_factor.x);
    auto base_scale = use_min_scale ? sprite.get_min_scale() : sprite.get_default_scale();
    auto effective_scale = base_scale / effective_parallax_factor;
    return effective_scale;
}

bool MapSpritePlacer::_is_in_biome(const PackedByteArray* biome_sdf, float biome_sdf_range, const MapCoordinate& coord) const
{
    return _distance_to_boundary(*biome_sdf, biome_sdf_range, coord) < 0.f;
}

bool MapSpritePlacer::_is_in_clip(const MapCoordinate& coord, float cutoff) const
{
    return _distance_to_boundary(clip_sdf, default_sdf_range, coord) > cutoff;
}

MapUnit MapSpritePlacer::_distance_to_boundary(const PackedByteArray& sdf, float sdf_range, const MapCoordinate& coord) const
{
    float normalized = utils::sample_aa(sdf, coord, map_size);
    return sdf_range * ((normalized - 127.5f) / 127.5f);
}

bool MapSpritePlacer::_is_tile_in_biome(const PackedByteArray& biome_sdf, const IntMapCoordinate& coord) const
{
    constexpr int DISTANCE_THRESHOLD = 127;
    ERR_FAIL_INDEX_V_MSG(coord.x, map_size.x, false, "X index out of range.");
    ERR_FAIL_INDEX_V_MSG(coord.y, map_size.y, false, "Y index out of range.");
    uint8_t quantized_distance = biome_sdf[coord.y * map_size.x + coord.x];
    return quantized_distance <= DISTANCE_THRESHOLD;
}

MapUnit MapSpritePlacer::_tile_distance_to_boundary(const PackedByteArray& sdf, float sdf_range, const IntMapCoordinate& coord) const
{
    ERR_FAIL_INDEX_V_MSG(coord.x, map_size.x, 1e6, "X index out of range.");
    ERR_FAIL_INDEX_V_MSG(coord.y, map_size.y, 1e6, "Y index out of range.");
    uint8_t quantized_distance = sdf[coord.y * map_size.x + coord.x];
    return sdf_range * ((float(quantized_distance) - 127.5f) / 127.5f);
}

MapCoordinate CandidateCell::get_random_coord(std::mt19937& rng, bool use_legacy_distribution) const
{
    MapUnit x = rect.position.x + (use_legacy_distribution
        ? std::uniform_real_distribution<float>(0.0, rect.size.x)(rng)
        : utils::uniform_real_distribution(rng, 0.0, rect.size.x));
    MapUnit y = rect.position.y + (use_legacy_distribution
        ? std::uniform_real_distribution<float>(0.0, rect.size.y)(rng)
        : utils::uniform_real_distribution(rng, 0.0, rect.size.y));
    return MapCoordinate(x, y);
}

bool MapSpritePlacer::_intersects_non_removable(const MapSpriteType& sprite_type, const MapCoordinate& coord, float scale, const TypedArray<MapSpriteType>& extra_removable) const
{
    ERR_FAIL_COND_V_EDMSG(!quad_tree.is_valid(), false, "Quad tree must be set.");

    auto collision = sprite_type.get_collision();
    for (int i = 0; i < collision.size(); ++i) {
        Ref<MapSpriteCollision> shape = collision[i];
        ERR_CONTINUE_EDMSG(!shape.is_valid(), "Invalid collision shape type at index " + String::num(i) + ".");
        if (!shape->is_blocking()) continue;

        TypedArray<MapSpritePlacement> hits = shape->query_quad_tree(quad_tree, coord, scale, true);
        for (int j = 0; j < hits.size(); ++j) {
            Ref<MapSpritePlacement> placement = hits[j];
            ERR_CONTINUE_EDMSG(!placement.is_valid(), "Invalid placement from QT query.");
            Ref<MapSpriteType> other_type = placement->get_sprite_type();
            ERR_CONTINUE_EDMSG(!other_type.is_valid(), "Invalid sprite type in placement from QT query.");
            if (!other_type->get_removable() && !extra_removable.has(other_type)) {
                return true;
            }
        }
    }

    return false;
}

float MapSpritePlacer::_evaluate_candidate(Ref<MapSpriteType> sprite_type, const MapCoordinate& coord, const PackedByteArray& biome_sdf, const MapCoordinate& search_origin, float max_distance) const
{
    float dist = coord.distance_to(search_origin);
    float norm_dist = Math::clamp(dist / std::max(max_distance, 1e-3f), 0.f, 1.f);
    float proximity_score = 1.f - norm_dist;

    float enclosure_score = 0;
    if (!biome_sdf.is_empty()) {
        float boundary_dist = -_distance_to_boundary(biome_sdf, default_sdf_range, coord);
        enclosure_score = Math::clamp(boundary_dist / std::max(default_sdf_range, 1e-3f), 0.f, 1.f);
    }

    auto intersecting_sprites = get_intersecting_sprites(sprite_type, coord);
    float removed_sprites_cost = 0.f;
    for (int i = 0; i < intersecting_sprites.size(); ++i) {
        Ref<MapSpritePlacement> placement = intersecting_sprites[i];
        removed_sprites_cost += 1 + placement->get_sprite_type()->get_footprint_radius();
    }
    float removal_score = 1.f - Math::clamp(removed_sprites_cost / 10.f, 0.f, 1.f);

    return 0.4f * proximity_score + 0.4f * enclosure_score + 0.2f * removal_score;
}
