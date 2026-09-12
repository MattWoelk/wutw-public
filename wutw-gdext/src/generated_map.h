#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <godot_cpp/variant/packed_byte_array.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/classes/texture2d.hpp>

#include "map_biomes.h"
#include "quad_tree.h"
#include "map_sprite_placer.h"
#include "road_creator.h"

using namespace godot;
using Biome = MapBiomes::Biome;

class MapPath : public Resource {
    GDCLASS(MapPath, Resource)

private:
    TypedArray<Vector2> points;

protected:
    static void _bind_methods();

public:
    void set_points(const TypedArray<Vector2>& p) { points = p; }
    TypedArray<Vector2> get_points() const { return points; }
};

class GeneratedMap : public Resource {
    GDCLASS(GeneratedMap, Resource)

public:
    void set_size(const Vector2i& v) { size = v; }
    Vector2i get_size() const { return size; }

    void set_biome_bitmap(const PackedByteArray& b) { biome_bitmap = b; }
    PackedByteArray get_biome_bitmap() const { return biome_bitmap; }

    void set_raw_biome_sdfs(const TypedArray<PackedByteArray>& a) { raw_biome_sdfs = a; }
    TypedArray<PackedByteArray> get_raw_biome_sdfs() const { return raw_biome_sdfs; }

    void set_blurred_biome_sdfs(const TypedArray<Texture2D>& a) { blurred_biome_sdfs = a; }
    TypedArray<Texture2D> get_blurred_biome_sdfs() const { return blurred_biome_sdfs; }

    void set_clip_mask(const Ref<Texture2D>& t) { clip_mask = t; }
    Ref<Texture2D> get_clip_mask() const { return clip_mask; }

    void set_nonland_sdf(const Ref<Texture2D>& b) { nonland_sdf = b; }
    Ref<Texture2D> get_nonland_sdf() const { return nonland_sdf; }

    void set_shard_base_texture(const Ref<Texture2D>& t) { shard_base_texture = t; }
    Ref<Texture2D> get_shard_base_texture() const { return shard_base_texture; }

    void set_distance_to_land_texture(const Ref<Texture2D>& t) { distance_to_land_texture = t; }
    Ref<Texture2D> get_distance_to_land_texture() const { return distance_to_land_texture; }

    void set_land_depth_texture(const Ref<Texture2D>& t) { land_depth_texture = t; }
    Ref<Texture2D> get_land_depth_texture() const { return land_depth_texture; }

    void set_starting_point(const Vector2i& v) { starting_point = v; }
    Vector2i get_starting_point() const { return starting_point; }

    void set_edge_cloud_points(const Array& a) { edge_cloud_points = a; }
    Array get_edge_cloud_points() const { return edge_cloud_points; }

    void set_sprites(const TypedArray<MapSpritePlacement>& a) { sprites = a; }
    TypedArray<MapSpritePlacement> get_sprites() const { return sprites; }

    void set_sprites_quad_tree(const Ref<QuadTree>& q) { sprites_quad_tree = q; }
    Ref<QuadTree> get_sprites_quad_tree() const { return sprites_quad_tree; }

    void set_sprite_placer(const Ref<MapSpritePlacer>& p) { sprite_placer = p; }
    Ref<MapSpritePlacer> get_sprite_placer() const { return sprite_placer; }

    void set_road_creator(const Ref<RoadCreator>& p) { road_creator = p; }
    Ref<RoadCreator> get_road_creator() const { return road_creator; }

protected:
    static void _bind_methods();

private:
    Vector2i size;
    Vector2i starting_point;

    PackedByteArray biome_bitmap;
    TypedArray<PackedByteArray> raw_biome_sdfs;
    TypedArray<Texture2D> blurred_biome_sdfs;
    Ref<Texture2D> clip_mask;
    Ref<Texture2D> nonland_sdf;

    Ref<Texture2D> shard_base_texture;
    Ref<Texture2D> distance_to_land_texture;
    Ref<Texture2D> land_depth_texture;
    TypedArray<Vector2> edge_cloud_points;

    TypedArray<MapSpritePlacement> sprites;
    Ref<QuadTree> sprites_quad_tree;
    Ref<MapSpritePlacer> sprite_placer;
    Ref<RoadCreator> road_creator;
};
