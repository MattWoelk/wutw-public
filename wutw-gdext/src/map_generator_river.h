#pragma once
#include "map_generator.h"

using namespace godot;

enum class RiverNodeType {
    IMPASSABLE,
    PASSABLE,
    SOURCE,
    SINK_NORTH,
    SINK_EAST,
    SINK_SOUTH,
    SINK_WEST
};

class MapGenerator_River {
public:
    MapGenerator_River(Vector2i size, const PackedByteArray& biome_bitmap, const Ref<MapRiverConfig> river_config,
                       Ref<MapSpritePlacer> placer, const std::mt19937& rng, bool use_legacy_distribution)
        : size(size), biome_bitmap(biome_bitmap), river_config(river_config),
          placer(placer), rng(rng), use_legacy_distribution(use_legacy_distribution) {
    }

    TypedArray<MapSpritePlacement> generate();

private:
    const Vector2i size;
    const PackedByteArray biome_bitmap;
    const Ref<MapRiverConfig> river_config;
    Ref<MapSpritePlacer> placer;
    const bool use_legacy_distribution;
    std::mt19937 rng;

    void precalculate_nodes();
    std::array<Vector2i, 4> get_neighbors(Vector2i coord) const;
    RiverNodeType get_node_type(const Vector2i coord) const;
    RiverNodeType calculate_node_type(const Vector2i coord) const;
    bool is_sink(int x, int y) const;
    MapBiomes::Biome get_biome(const Vector2i coord) const;
    MapBiomes::Biome get_biome(int x, int y) const;

    std::vector<std::vector<Vector2i>> find_paths();
    bool is_valid_sink(Vector2i point, Vector2i sink) const;

    MapRiverConfig::Direction get_opposite_direction(MapRiverConfig::Direction d) const;
    MapRiverConfig::Direction get_direction(Vector2i src, Vector2i dst) const;
    MapRiverConfig::Direction get_sink_direction(Vector2i coord) const;
    Ref<MapSpritePlacement> place_river_segment(Vector2i coord, MapRiverConfig::Direction from, MapRiverConfig::Direction to, int node_index);

    std::vector<Vector2i> choose_path(std::vector<std::vector<Vector2i>>& paths);
    float score_path(const std::vector<Vector2i>& path) const;
    float compute_twistiness(const std::vector<Vector2i>& path) const;

    std::vector<RiverNodeType> nodes;
    int block_size = -1;
    std::vector<Vector2i> sources;
    std::vector<Vector2i> sinks;
};
