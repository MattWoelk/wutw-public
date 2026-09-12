#include "map_generator.h"

#include "map_generator_basemap.h"
#include "map_generator_sdf.h"
#include "map_generator_clip.h"
#include "map_generator_stamps.h"
#include "map_generator_river.h"
#include "utils.h"

Ref<GeneratedMap> MapGenerator::generate(const Ref<MapGenerationConfig>& config, const int seed, bool use_legacy_distribution)
{
    ERR_FAIL_COND_V_EDMSG(!config.is_valid(), {}, "Config must be valid.");
    ERR_FAIL_COND_V_EDMSG(!config->get_biome_config().is_valid(), {}, "Config biome_config must be valid.");
    ERR_FAIL_COND_V_EDMSG(!config->get_input_textures().is_valid(), {}, "Config input_textures must be valid.");
    ERR_FAIL_COND_V_EDMSG(!config->get_shard_bottom_config().is_valid(), {}, "Config shard_bottom_config must be valid.");

    this->use_legacy_distribution = use_legacy_distribution;
    this->config = config;
    rng.seed(seed);

    // Initialize output.
    generated_map.instantiate();
    generated_map->set_size(config->get_size());

    // Choose a basemap config.
    auto basemap_configs = config->get_input_textures()->get_basemap_configs();
    auto basemap_index = use_legacy_distribution
        ? std::uniform_int_distribution<int>(0, basemap_configs.size() - 1)(rng)
        : utils::uniform_int_distribution(rng, 0, basemap_configs.size() - 1);
    basemap_config = basemap_configs[basemap_index];
    generated_map->set_starting_point(basemap_config->get_starting_point());

    // Generate basemap.
    MapGenerator_Basemap basemap_generator(
        config->get_size(), config->get_biome_config(), config->get_input_textures(),
        basemap_config, rng, config->get_despeckle_max_tiles(), use_legacy_distribution);
    biome_bitmap = basemap_generator.generate();
    generated_map->set_biome_bitmap(biome_bitmap);

    // Generate SDFs.
    {  // To make sure we don't leave threads behind.
        raw_sdfs.resize(Biome::_NUM_BIOME_TYPES);
        blurred_sdfs.resize(Biome::_NUM_BIOME_TYPES);
        blurred_sdf_textures.resize(Biome::_NUM_BIOME_TYPES);
        std::vector<Ref<Thread>> sdf_gen_threads;
        for (int biome = 0; biome < Biome::_NUM_BIOME_TYPES; ++biome) {
            Ref<Thread> thread;
            thread.instantiate();
            sdf_gen_threads.push_back(thread);
            thread->start(callable_mp(this, &MapGenerator::_generate_sdf).bind(biome));
        }
        for (auto& thread : sdf_gen_threads) {
            thread->wait_to_finish();
        }
        generated_map->set_raw_biome_sdfs(raw_sdfs);
        generated_map->set_blurred_biome_sdfs(blurred_sdf_textures);
        
        // Generate a non-land SDF out of min(clouds, sea).
        nonland_sdf = raw_sdfs[Biome::CLOUDS].duplicate();
        PackedByteArray sea_sdf = raw_sdfs[Biome::SEA];
        for (int i = 0; i < nonland_sdf.size(); ++i) {
            nonland_sdf[i] = std::min(nonland_sdf[i], sea_sdf[i]);
        }
        Ref<Image> nonland_sdf_image = Image::create_from_data(config->get_size().x, config->get_size().y, false, Image::FORMAT_R8, nonland_sdf);
        generated_map->set_nonland_sdf(ImageTexture::create_from_image(nonland_sdf_image));
    }

    // Set up background threads that can all run in parallel and whose result is only used for the final return.
    std::vector<Ref<Thread>> background_threads;

    // Generate clip mask.
    Ref<Thread> clip_thread;
    clip_thread.instantiate();
    background_threads.push_back(clip_thread);
    clip_thread->start(callable_mp(this, &MapGenerator::_generate_clip));

    // Generate shard base.
    Ref<Thread> shard_base_thread;
    shard_base_thread.instantiate();
    background_threads.push_back(shard_base_thread);
    shard_base_thread->start(callable_mp(this, &MapGenerator::_generate_shard_base_image));

    // Setup the sprites.
    quad_tree.instantiate();
    quad_tree->initialize(Rect2(Vector2(0, 0), config->get_size()));
    placer.instantiate();
    placer->initialize(config->get_size(), nonland_sdf, config->get_sdf_max_distance(),
                       quad_tree, config->get_sprite_dupe_decay(), seed, use_legacy_distribution);
    Ref<RoadCreator> road_creator;
    road_creator.instantiate();
    road_creator->initialize(config->get_size(), nonland_sdf, config->get_sdf_max_distance(), quad_tree);

    // Add sprites: rivers, stamps, and cosmetics.
    Ref<Thread> sprites_thread;
    sprites_thread.instantiate();
    background_threads.push_back(sprites_thread);
    sprites_thread->start(callable_mp(this, &MapGenerator::_generate_sprites));

    // Collect the background thread results.
    for (auto& thread : background_threads) {
        thread->wait_to_finish();
    }
    generated_map->set_clip_mask(clip_mask_texture);
    generated_map->set_shard_base_texture(ImageTexture::create_from_image(shard_base_image));
    generated_map->set_distance_to_land_texture(distance_to_land_sdf);
    generated_map->set_land_depth_texture(land_depth_texture);
    generated_map->set_edge_cloud_points(edge_cloud_points);
    generated_map->set_sprites_quad_tree(quad_tree);
    generated_map->set_sprite_placer(placer);
    generated_map->set_road_creator(road_creator);
    generated_map->set_sprites(sprite_placements);

    // Cleanup.
    this->config = Ref<MapGenerationConfig>();
    mask_bitmap = PackedByteArray();
    altitude_bitmap = PackedByteArray();
    basemap_config = Ref<MapBaseConfig>();
    quad_tree = Ref<QuadTree>();
    placer = Ref<MapSpritePlacer>();
    biome_bitmap = PackedByteArray();
    raw_sdfs = TypedArray<PackedByteArray>();
    blurred_sdfs = TypedArray<PackedByteArray>();
    blurred_sdf_textures = TypedArray<ImageTexture>();
    clip_mask_texture = Ref<ImageTexture>();
    sprite_placements = TypedArray<MapSpritePlacement>();
    shard_outline_sections.clear();
    shard_base_image = Ref<Image>();
    distance_to_land_sdf = Ref<ImageTexture>();
    land_depth_texture = Ref<ImageTexture>();
    edge_cloud_points = TypedArray<Vector2>();

    return generated_map;
}

void MapGenerator::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("generate", "config", "seed", "use_legacy_distribution"), &MapGenerator::generate, DEFVAL(false));
}

void MapGenerator::_generate_sdf(Biome biome)
{
    MapGenerator_SDF sdf_generator(
        config->get_size(), biome_bitmap, biome,
        config->get_sdf_max_distance(), config->get_sdf_blur_radius());
    auto [raw_sdf, blurred_sdf] = sdf_generator.generate();
    raw_sdfs[biome] = raw_sdf;
    blurred_sdfs[biome] = blurred_sdf;

    // Encode the blurred one as a texture as well.
    Ref<Image> blurred_image = Image::create_from_data(config->get_size().x, config->get_size().y, false, Image::FORMAT_R8, blurred_sdf);
    blurred_sdf_textures[biome] = ImageTexture::create_from_image(blurred_image);
}

void MapGenerator::_generate_clip()
{
    MapGenerator_Clip clip_generator(
        config->get_size(), blurred_sdfs[Biome::CLOUDS],
        config->get_clip_width(),
        config->get_clip_resolution_multiplier());
    clip_mask_texture = clip_generator.generate();
}

void MapGenerator::_generate_sprites()
{
    sprite_placements.append(placer->place_single(config->get_torii_sprite(), basemap_config->get_starting_point()));

    MapGenerator_River river_generator(config->get_size(), biome_bitmap, config->get_river_config(), placer, rng, use_legacy_distribution);
    sprite_placements.append_array(river_generator.generate());

    MapGenerator_Stamps stamp_generator(config->get_size(), biome_bitmap, config->get_stamp_configs(), placer, rng, use_legacy_distribution);
    sprite_placements.append_array(stamp_generator.generate());

    // Add cosmetic sprites.
    auto biome_sprite_configs = config->get_biome_sprite_configs();
    Array keys = biome_sprite_configs.keys();
    for (int i = 0; i < keys.size(); ++i) {
        Biome biome = (Biome)(int)keys[i];
        Ref<MapSpritePlacerConfig> placer_config = biome_sprite_configs[keys[i]];
        sprite_placements.append_array(placer->fill_biome(raw_sdfs[biome], placer_config));
    }
}

void MapGenerator::_generate_shard_base_image()
{
    MapGenerator_ShardBase shard_base_generator(
        config->get_size(), biome_bitmap, blurred_sdfs[Biome::CLOUDS], config->get_shard_bottom_config());
    shard_outline_sections = shard_base_generator.get_shard_outline_sections();
    shard_base_image = shard_base_generator.draw_shard_outline_sections(shard_outline_sections);

    // Generate distance to land.
    Ref<Thread> distance_to_land_thread;
    distance_to_land_thread.instantiate();
    distance_to_land_thread->start(callable_mp(this, &MapGenerator::_generate_distance_to_land));

    // Generate land depth.
    Ref<Thread> land_depth_thread;
    land_depth_thread.instantiate();
    land_depth_thread->start(callable_mp(this, &MapGenerator::_generate_land_depth));
    
    // Generate edge clouds.
    edge_cloud_points = shard_base_generator.generate_edge_clouds(shard_outline_sections);

    distance_to_land_thread->wait_to_finish();
    land_depth_thread->wait_to_finish();
}

void MapGenerator::_generate_distance_to_land()
{
    MapGenerator_ShardBase shard_base_generator(
        config->get_size(), biome_bitmap, blurred_sdfs[Biome::CLOUDS], config->get_shard_bottom_config());
    auto land_bitmap = shard_base_generator.generate_distance_to_land(shard_base_image);

    // Now generate an SDF for it.
    MapGenerator_SDF sdf_generator(
        config->get_size(), land_bitmap, (Biome)0,  // Not really a biome, but doesn't matter.
        config->get_sdf_max_distance(), config->get_sdf_blur_radius());
    auto land_sdf = sdf_generator.generate().second;
    Ref<Image> land_sdf_image = Image::create_from_data(
        config->get_size().x, config->get_size().y, false, Image::FORMAT_R8, land_sdf);
    distance_to_land_sdf = ImageTexture::create_from_image(land_sdf_image);
}

void MapGenerator::_generate_land_depth()
{
    MapGenerator_ShardBase shard_base_generator(
        config->get_size(), biome_bitmap, blurred_sdfs[Biome::CLOUDS], config->get_shard_bottom_config());
    auto depth_image = shard_base_generator.generate_land_depth(shard_outline_sections, shard_base_image);
    land_depth_texture = ImageTexture::create_from_image(depth_image);
}
