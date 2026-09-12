#include "map_generator_river.h"
#define _USE_MATH_DEFINES
#include <math.h>
#include <queue>
#include <algorithm>
#include "utils.h"

TypedArray<MapSpritePlacement> MapGenerator_River::generate()
{
    ERR_FAIL_COND_V_EDMSG(!river_config.is_valid(), {}, "River config must be valid.");
    ERR_FAIL_COND_V_EDMSG(river_config->get_sprite_size() < 4, {}, "River sprite size must be at least 4.");
    ERR_FAIL_COND_V_EDMSG(river_config->get_sprite_size() > 20, {}, "River sprite size must be at most 20.");
    ERR_FAIL_COND_V_EDMSG(river_config->get_sprite_size() % 2 != 0, {}, "River sprite size must be even.");
    block_size = river_config->get_sprite_size();
    precalculate_nodes();
    if (sinks.empty() || sources.empty()) return {};

    auto paths = find_paths();
    if (paths.empty()) return {};
    auto path = choose_path(paths);
    if (paths.size() < 2) return {};

    TypedArray<MapSpritePlacement> result;
    // Place the origin mountain sprite.
    auto coord = path[0] + Vector2(block_size, block_size) / 2.f;
    result.append(placer->place_single(river_config->get_origin_mountain_sprite(get_direction(path[0], path[1])), coord));
    // Place all the segments.
    MapRiverConfig::Direction cur_dir = MapRiverConfig::Direction::ORIGIN;
    for (int i = 0; i < path.size() - 1; ++i) {
        auto next_dir = get_direction(path[i], path[i + 1]);
        auto sprite = river_config->get_sprite_type(cur_dir, next_dir);
        result.append(place_river_segment(path[i], cur_dir, next_dir, i));
        cur_dir = get_opposite_direction(next_dir);
    }
    auto sink_dir = get_sink_direction(path.back());
    result.append(place_river_segment(path.back(), cur_dir, sink_dir, path.size() - 1));

    // Insert waterfalls on south-facing sinks if they are at a shard edge.
    if (sink_dir == MapRiverConfig::Direction::SOUTH) {
        Vector2 waterfall_coord = path.back() + Vector2(0, block_size);
        auto waterfall_biome = get_biome(waterfall_coord.x + block_size / 2.f, waterfall_coord.y);
        if (waterfall_biome == MapBiomes::Biome::CLOUDS) {  // Not a sea sink.
            auto sprite = river_config->get_waterfall_sprite();
            ERR_FAIL_COND_V_EDMSG(!sprite.is_valid(), {}, "Invalid waterfall sprite.");
            // Walk north to line it up with the edge of the shard.
            for (int dy = 0; dy < block_size; ++dy) {
                auto walked_biome = get_biome(waterfall_coord.x + block_size / 2.f, waterfall_coord.y - dy);
            
                if (walked_biome != MapBiomes::Biome::CLOUDS) {
                    waterfall_coord.y -= dy - 0.6f;
                    break;
                }
            }
            waterfall_coord += Vector2(block_size / 2.f, block_size);  // Center pivot and double height.
            result.append(placer->place_single(sprite, waterfall_coord));
        }
    }

    return result;
}

void MapGenerator_River::precalculate_nodes()
{
    nodes.resize(size.x * size.y);
    sources.reserve(2000);
    sinks.reserve(300);
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            auto type = calculate_node_type({ x, y });
            nodes[y * size.x + x] = type;
            if (type == RiverNodeType::SOURCE) {
                sources.emplace_back(x, y);
            } else if (type >= RiverNodeType::SINK_EAST && type <= RiverNodeType::SINK_WEST) {
                sinks.emplace_back(x, y);
            }
        }
    }
}

std::vector<std::vector<Vector2i>> MapGenerator_River::find_paths()
{
    constexpr int INF = 1e9;
    constexpr int MAX_PATHS = 500;

    // Multi-source BFS from all sinks.
    std::vector<int> dist(size.x * size.y, INF);
    std::queue<Vector2i> q;
    for (auto sink : sinks) {
        dist[sink.y * size.x + sink.x] = 0;
        q.push(sink);
    }
    while (!q.empty()) {
        Vector2i cur = q.front();
        q.pop();
        int cd = dist[cur.y * size.x + cur.x];
        for (auto& n : get_neighbors(cur)) {
            if (unlikely(n.x < 0 || n.y < 0 || n.x >= size.x || n.y >= size.y)) continue;
            int idx = n.y * size.x + n.x;
            if (dist[idx] == INF && get_node_type(n) != RiverNodeType::IMPASSABLE) {
                dist[idx] = cd + 1;
                q.push(n);
            }
        }
    }

    std::vector<std::vector<Vector2i>> result;
    result.reserve(MAX_PATHS);

    // Attempt good then fallback lengths.
    Vector2i good_lengths(river_config->get_min_good_length(), river_config->get_max_good_length());
    Vector2i fallback_lengths(river_config->get_min_length(), good_lengths.x);
    for (auto lengths : { good_lengths, fallback_lengths }) {
        auto min_length = lengths.x, max_length = lengths.y;
        // Filter sources whose shortest path is in range.
        std::vector<Vector2i> cand;
        cand.reserve(sources.size());
        for (auto& s : sources) {
            auto d = dist[s.y * size.x + s.x];
            if (d >= min_length && d <= max_length) {
                cand.push_back(s);
            }
        }
        if (use_legacy_distribution) {
            std::shuffle(cand.begin(), cand.end(), rng);
        } else {
            utils::shuffle(cand.begin(), cand.end(), rng);
        }

        // Set up scratch storage.
        std::vector<Vector2i> path;
        path.reserve(max_length + 1);
        std::vector<Vector2i> downs;
        downs.reserve(4);
        // Extract up to MAX_PATHS paths.
        for (auto& start : cand) {
            // Walk downhill in distance for up to max_length steps.
            path.clear();
            path.push_back(start);
            Vector2i cur = start;
            for (int step = 0; step <= max_length; ++step) {
                int cd = dist[cur.y * size.x + cur.x];
                if (cd == 0) {
                    if (is_valid_sink(path[path.size() - 2], cur)) {
                        result.push_back(std::move(path));
                        if (result.size() >= MAX_PATHS) break;
                    }
                }
                // Collect all neighbors at cd-1.
                downs.clear();
                for (auto& n : get_neighbors(cur)) {
                    if (n.x < 0 || n.x >= size.x || n.y < 0 || n.y >= size.y) {
                        continue;
                    }
                    if (dist[n.y * size.x + n.x] == cd - 1) {
                        downs.push_back(n);
                    }
                }
                if (downs.empty()) {
                    path.clear();
                    break;
                }
                // Pick one at random.
                if (use_legacy_distribution) {
                    cur = downs[std::uniform_int_distribution<int>(0, downs.size() - 1)(rng)];
                } else {
                    cur = downs[utils::uniform_int_distribution(rng, 0, downs.size() - 1)];
                }
                path.push_back(cur);
            }
        }
    }

    return result;
}

bool MapGenerator_River::is_valid_sink(Vector2i point, Vector2i sink) const
{
    auto sink_type = get_node_type(sink);
    auto direction = get_direction(point, sink);
    if (sink_type == RiverNodeType::SINK_SOUTH && direction == MapRiverConfig::Direction::NORTH) return false;
    if (sink_type == RiverNodeType::SINK_NORTH && direction == MapRiverConfig::Direction::SOUTH) return false;
    if (sink_type == RiverNodeType::SINK_EAST && direction == MapRiverConfig::Direction::WEST) return false;
    if (sink_type == RiverNodeType::SINK_WEST && direction == MapRiverConfig::Direction::EAST) return false;
    return true;
}

std::vector<Vector2i> MapGenerator_River::choose_path(std::vector<std::vector<Vector2i>>& paths)
{
    std::vector<float> weights;
    weights.reserve(paths.size());
    float total = 0.0;
    for (auto& p : paths) {
        float w = score_path(p);
        weights.push_back(w);
        total += w;
    }
    if (total == 0.0) {
        if (use_legacy_distribution) {
            return paths[std::uniform_int_distribution<size_t>(0, paths.size() - 1)(rng)];
        } else {
            return paths[utils::uniform_int_distribution(rng, 0, paths.size() - 1)];
        }
    }

    if (use_legacy_distribution) {
        return paths[std::discrete_distribution<size_t>(weights.begin(), weights.end())(rng)];
    } else {
        return paths[utils::discrete_distribution(rng, weights)];
    }
}

float MapGenerator_River::score_path(const std::vector<Vector2i>& path) const
{
    Vector2i good_lengths(river_config->get_min_good_length(), river_config->get_max_good_length());
    auto length = path.size() - 1;
    float length_score;
    if (length < good_lengths.x) {
        length_score = 0.f;
    } else {
        length_score = utils::remap(length, good_lengths.x, (good_lengths.x + good_lengths.y) / 2.f, 0.5f, 1.f);
    }
    auto twistiness_score = compute_twistiness(path);
    // TODO: Maybe include biome diversity?
    return length_score + 2.f * twistiness_score;
}

MapRiverConfig::Direction MapGenerator_River::get_opposite_direction(MapRiverConfig::Direction d) const
{
    switch (d) {
    case MapRiverConfig::Direction::NORTH: return MapRiverConfig::Direction::SOUTH;
    case MapRiverConfig::Direction::SOUTH: return MapRiverConfig::Direction::NORTH;
    case MapRiverConfig::Direction::EAST: return MapRiverConfig::Direction::WEST;
    case MapRiverConfig::Direction::WEST: return MapRiverConfig::Direction::EAST;
    case MapRiverConfig::Direction::ORIGIN: return MapRiverConfig::Direction::ORIGIN;
    default:
        // assert(false);
        return MapRiverConfig::Direction::NORTH;
    }
}

MapRiverConfig::Direction MapGenerator_River::get_direction(Vector2i src, Vector2i dst) const
{
    if (src.x < dst.x) return MapRiverConfig::Direction::EAST;
    else if (src.x > dst.x) return MapRiverConfig::Direction::WEST;
    else if (src.y < dst.y) return MapRiverConfig::Direction::SOUTH;
    else if (src.y > dst.y) return MapRiverConfig::Direction::NORTH;
    ERR_FAIL_COND_V_EDMSG(true, MapRiverConfig::Direction::ORIGIN, "Invalid river path direction.");
}

MapRiverConfig::Direction MapGenerator_River::get_sink_direction(Vector2i coord) const
{
    switch (get_node_type(coord)) {
    case RiverNodeType::SINK_NORTH: return MapRiverConfig::Direction::NORTH;
    case RiverNodeType::SINK_SOUTH: return MapRiverConfig::Direction::SOUTH;
    case RiverNodeType::SINK_WEST: return MapRiverConfig::Direction::WEST;
    case RiverNodeType::SINK_EAST: return MapRiverConfig::Direction::EAST;
    default:
        // assert(false);
        return MapRiverConfig::Direction::ORIGIN;
    }
}

Ref<MapSpritePlacement> MapGenerator_River::place_river_segment(Vector2i coord, MapRiverConfig::Direction from, MapRiverConfig::Direction to, int node_index)
{
    auto sprite = river_config->get_sprite_type(from, to);
    ERR_FAIL_COND_V_EDMSG(!sprite.is_valid(), {}, "Invalid river sprite.");
    coord += Vector2(block_size, block_size) / 2.f;
    return placer->place_single(sprite, coord);
}

std::array<Vector2i, 4> MapGenerator_River::get_neighbors(Vector2i coord) const
{
    return {
        coord + Vector2(block_size, 0),
        coord - Vector2(block_size, 0),
        coord + Vector2(0, block_size),
        coord - Vector2(0, block_size),
    };
}

RiverNodeType MapGenerator_River::get_node_type(const Vector2i coord) const
{
    return nodes[coord.y * size.x + coord.x];
}

RiverNodeType MapGenerator_River::calculate_node_type(const Vector2i coord) const
{
    if (unlikely(coord.x < 0)) return RiverNodeType::IMPASSABLE;
    if (unlikely(coord.y < 0)) return RiverNodeType::IMPASSABLE;
    if (unlikely(coord.x + block_size >= size.x)) return RiverNodeType::IMPASSABLE;
    if (unlikely(coord.y + block_size >= size.y)) return RiverNodeType::IMPASSABLE;

    int num_sinks = 0;
    std::vector<Vector2i> sinks;  // TODO: In practice, this could be optimized into a stack array, since block size never changes.
    for (int by = coord.y; by < coord.y + block_size; ++by) {
        for (int bx = coord.x; bx < coord.x + block_size; ++bx) {
            if (is_sink(bx, by)) {
                if (bx > coord.x && by > coord.y && bx < coord.x + block_size - 1 && by > coord.y + block_size - 1) {
                    // A non-edge sink invalidates the whole block.
                    return RiverNodeType::IMPASSABLE;
                }
                num_sinks++;
                if (num_sinks > block_size) return RiverNodeType::IMPASSABLE;
                sinks.emplace_back(bx, by);
            }
        }
    }

    if (num_sinks == 0) {
        bool can_be_source = get_biome(coord + Vector2i(block_size / 3 - 1, block_size / 3 - 1)) == MapBiomes::Biome::MOUNTAIN
                          && get_biome(coord + Vector2i(block_size / 3, block_size / 3 - 1)) == MapBiomes::Biome::MOUNTAIN
                          && get_biome(coord + Vector2i(block_size / 3 - 1, block_size / 3)) == MapBiomes::Biome::MOUNTAIN
                          && get_biome(coord + Vector2i(block_size / 3, block_size / 3)) == MapBiomes::Biome::MOUNTAIN;
        return can_be_source ? RiverNodeType::SOURCE : RiverNodeType::PASSABLE;
    } else {
        bool is_horizontal = true;
        bool is_vertical = true;
        auto first = sinks[0];
        for (auto& sink : sinks) {
            if (sink.x != first.x) is_vertical = false;
            if (sink.y != first.y) is_horizontal = false;
            if (!is_horizontal && !is_vertical) return RiverNodeType::IMPASSABLE;
        }
        if (is_horizontal) {
            // assert(!is_vertical);
            if (first.y == coord.y) {
                if (is_sink(coord.x + block_size / 2 - 1, first.y) && is_sink(coord.x + block_size / 2, first.y)) {
                    return RiverNodeType::SINK_NORTH;
                }
                else {
                    return RiverNodeType::IMPASSABLE;
                }
            }
            else {
                if (is_sink(coord.x + block_size / 2 - 1, first.y) && is_sink(coord.x + block_size / 2, first.y)) {
                    return RiverNodeType::SINK_SOUTH;
                }
                else {
                    return RiverNodeType::IMPASSABLE;
                }
            }
        } else {
            // assert(is_vertical);
            if (first.x == coord.x) {
                if (is_sink(coord.x, coord.y + block_size / 2 - 1) && is_sink(coord.x, coord.y + block_size / 2)) {
                    return RiverNodeType::SINK_WEST;
                }
                else {
                    return RiverNodeType::IMPASSABLE;
                }
            }
            else {
                if (is_sink(coord.x, coord.y + block_size / 2 - 1) && is_sink(coord.x, coord.y + block_size / 2)) {
                    return RiverNodeType::SINK_EAST;
                }
                else {
                    return RiverNodeType::IMPASSABLE;
                }
            }
        }
    }
}

bool MapGenerator_River::is_sink(int x, int y) const
{
    auto biome = get_biome(x, y);
    return biome == MapBiomes::Biome::CLOUDS || biome == MapBiomes::Biome::SEA;
}

MapBiomes::Biome MapGenerator_River::get_biome(const Vector2i coord) const
{
    return get_biome(coord.x, coord.y);
}

MapBiomes::Biome MapGenerator_River::get_biome(int x, int y) const
{
    return MapBiomes::Biome(biome_bitmap[y * size.x + x]);
}

float MapGenerator_River::compute_twistiness(const std::vector<Vector2i>& path) const {
    int n = path.size();
    if (n < 3) {
        return 0.0f;
    }

    // Overall source -> sink direction.
    Vector2 delta(path.back() - path.front());
    float theta0 = std::atan2(delta.y, delta.x);

    // Angle-wrap into [-PI, PI].
    auto wrap = [&](float a) {
        while (a <= -M_PI) a += 2 * M_PI;
        while (a > M_PI) a -= 2 * M_PI;
        return a;
    };

    // Bin each segment: -1=right, 0=forward, +1=left
    auto get_bin = [&](float dtheta) {
        if (dtheta > M_PI / 4.0f)  return  1;
        if (dtheta < -M_PI / 4.0f)  return -1;
        return 0;
    };

    std::vector<int> bins;
    bins.reserve(n - 1);
    for (int i = 0; i < n - 1; ++i) {
        float dx = float(path[i + 1].x - path[i].x);
        float dy = float(path[i + 1].y - path[i].y);
        float theta = std::atan2(dy, dx);
        float dtheta = wrap(theta - theta0);
        bins.push_back(get_bin(dtheta));
    }

    // Count how often the bin flips.
    int flips = 0;
    int bcount = int(bins.size());
    for (int i = 0; i + 1 < bcount; ++i) {
        if (bins[i] != bins[i + 1]) {
            ++flips;
        }
    }

    // Normalize by the maximum possible flips.
    int max_flips = bcount - 1;
    return (max_flips <= 0) ? 0.f : float(flips) / float(max_flips);
}
