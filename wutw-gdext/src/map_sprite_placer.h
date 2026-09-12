#pragma once

#include <vector>
#include <random>
#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/classes/texture2d.hpp>
#include <godot_cpp/variant/typed_array.hpp>

#include "map_sprite_type.h"
#include "quad_tree.h"

// Not type-safe, but easier to track which units are used.
typedef float MapUnit;
typedef float MapUnitSquare;
typedef Vector2 MapCoordinate;
typedef Vector2i IntMapCoordinate;

struct BiomePatch {
    Rect2i rect;
    MapUnitSquare area;
};

struct PrioritizedSprite {
    Ref<MapSpriteType> sprite;
    float priority;
};

struct CandidateCell {
    Rect2 rect;
    MapUnit min_signed_distance;

    MapCoordinate get_random_coord(std::mt19937& rng, bool use_legacy_distribution) const;
    bool operator<(const CandidateCell& other) const {
        return min_signed_distance < other.min_signed_distance;
    }
};

class MapSpritePlacement : public Resource
{
    GDCLASS(MapSpritePlacement, Resource);

public:
    MapSpritePlacement() {}
    MapSpritePlacement(const Ref<MapSpriteType>& sprite_type, const MapCoordinate& location, float scale = 1.0)
        : sprite_type(sprite_type), location(location), scale(scale) {}
    ~MapSpritePlacement() {}

    void set_sprite_type(const Ref<MapSpriteType>& type) { sprite_type = type; }
    Ref<MapSpriteType> get_sprite_type() const { return sprite_type; }
    void set_location(const MapCoordinate& loc) { location = loc; }
    MapCoordinate get_location() const { return location; }
    void set_scale(float s) { scale = s; }
    float get_scale() const { return scale; }
    void set_used_by(const Ref<MapSpritePlacement>& p) { used_by = p; }
    Ref<MapSpritePlacement> get_used_by() const { return used_by; }

protected:
    static void _bind_methods();

private:
    Ref<MapSpriteType> sprite_type = nullptr;
    MapCoordinate location = MapCoordinate(-1.0, -1.0);
    float scale = 1.0;
    Ref<MapSpritePlacement> used_by = nullptr;
};

class MapSpritePlacerConfig : public Resource
{
    GDCLASS(MapSpritePlacerConfig, Resource);

public:
    MapSpritePlacerConfig() {}
    ~MapSpritePlacerConfig() {}

    void set_sprite_types(const TypedArray<MapSpriteType>& types) { sprite_types = types; }
    TypedArray<MapSpriteType> get_sprite_types() const { return sprite_types; }
    void set_min_distance_from_biome_edge(float distance) { min_distance_from_biome_edge = distance; }
    float get_min_distance_from_biome_edge() const { return min_distance_from_biome_edge; }
    void set_parallax_factor(const Vector2& factor) { parallax_factor = factor; }
    Vector2 get_parallax_factor() const { return parallax_factor; }
    void set_cell_size(float size) { cell_size = size; }
    float get_cell_size() const { return cell_size; }
    void set_spacing_multiplier(float multiplier) { spacing_multiplier = multiplier; }
    float get_spacing_multiplier() const { return spacing_multiplier; }

protected:
    static void _bind_methods();

private:
    TypedArray<MapSpriteType> sprite_types;
    float min_distance_from_biome_edge = 0.f;
    Vector2 parallax_factor = Vector2(1.f, 1.f);
    float cell_size = 0.5f;
    float spacing_multiplier = 1.0f;
};

class MapSpritePlacer : public RefCounted
{
    GDCLASS(MapSpritePlacer, RefCounted);

public:
    MapSpritePlacer() {}
    ~MapSpritePlacer() {}

    void initialize(IntMapCoordinate map_size, const PackedByteArray& clip_sdf, float sdf_range, Ref<QuadTree> quad_tree, float dupe_decay, int rng_seed, bool use_legacy_distribution);

    Ref<MapSpritePlacement> place_single(Ref<MapSpriteType> sprite_type, Vector2 coord, float scale_override = -1.f);
    Ref<MapSpritePlacement> place_single_from_pool(TypedArray<MapSpriteType> sprite_types, Vector2 coord);
    TypedArray<MapSpritePlacement> place_clump(TypedArray<MapSpriteType> sprite_types, Vector2 coord, int count, float max_distance, float packing_factor = 0.2f, float spacing_multiplier = 1.f, Ref<MapSpriteType> initial_sprite_type = Ref<MapSpriteType>());
    TypedArray<MapSpritePlacement> fill_biome(const PackedByteArray& biome_sdf, Ref<MapSpritePlacerConfig> config);
    TypedArray<MapSpritePlacement> fill_circle(Ref<MapSpritePlacerConfig> config, Vector2 center, float radius);

    Ref<MapSpritePlacement> try_place_single(Ref<MapSpriteType> sprite_type, const PackedByteArray& biome_sdf, MapCoordinate search_origin, float max_distance, TypedArray<MapSpriteType> extra_removable = TypedArray<MapSpriteType>(), bool skip_clip = false, float clip_margin = 1.f);
    TypedArray<MapSpritePlacement> get_intersecting_sprites(Ref<MapSpriteType> sprite_type, MapCoordinate coord, float scale_override = -1.f) const;

    bool debug_passes_clip(Ref<MapSpriteType> sprite_type, MapCoordinate coord, float scale, float margin = 1.f) const;

    void reseed_random(int seed);

    void set_max_try_place_samples(int count);
    int get_max_try_place_samples() const;

protected:
    static void _bind_methods();

private:
    std::vector<PrioritizedSprite> _prioritize_sprites(const TypedArray<MapSpriteType>& sprite_types, bool prefer_large);
    PrioritizedSprite& _pick_sprite(std::vector<PrioritizedSprite>& prioritized);
    float _get_effective_scale(const MapSpriteType& sprite, const MapCoordinate& coord, const Vector2& parallax_factor, bool use_min_scale) const;
    bool _can_place(const MapCoordinate& coord, const MapSpriteType& sprite, float scale,
        const PackedByteArray* biome_sdf, float biome_sdf_range, float spacing_multiplier, bool ignore_removable = false) const;
    bool _is_in_clip(const MapCoordinate& coord, float cutoff = 1.f) const;
    bool _passes_clip(const MapSpriteType& sprite, const MapCoordinate& coord, float scale, float margin = 1.f) const;

    // For fill_biome().
    std::vector<BiomePatch> _get_biome_patches(const PackedByteArray& biome_sdf) const;
    bool _try_place_sprite(std::vector<PrioritizedSprite>& prioritized_sprites, const CandidateCell& cell,
                           const PackedByteArray* biome_sdf, Ref<MapSpritePlacerConfig> config, TypedArray<MapSpritePlacement>& output,
                           bool allow_min_scale, bool ignore_removable = false);
    bool _is_in_biome(const PackedByteArray* biome_sdf, float biome_sdf_range, const MapCoordinate& coord) const;
    bool _is_tile_in_biome(const PackedByteArray& biome_sdf, const IntMapCoordinate& coord) const;
    MapUnit _distance_to_boundary(const PackedByteArray& sdf, float sdf_range, const MapCoordinate& coord) const;
    MapUnit _tile_distance_to_boundary(const PackedByteArray& sdf, float sdf_range, const IntMapCoordinate& coord) const;
    
    // For try_palce_single().
    bool _intersects_non_removable(const MapSpriteType& sprite_type, const MapCoordinate& coord, float scale, const TypedArray<MapSpriteType>& extra_removable) const;
    float _evaluate_candidate(Ref<MapSpriteType> sprite_type, const MapCoordinate& coord, const PackedByteArray& biome_sdf, const MapCoordinate& search_origin, float max_distance) const;

    // State set in initialize()
    IntMapCoordinate map_size;
    PackedByteArray clip_sdf;  // A copy-on-write reference, which we never write to.
    float default_sdf_range = -1.f;
    float dupe_decay = -1.f;
    Ref<QuadTree> quad_tree;
    bool use_legacy_distribution;
    std::mt19937 rng;

    int max_try_place_samples = 256;
};
