#include "map_generator_stamps.h"
#include <algorithm>
#include "utils.h"

TypedArray<MapSpritePlacement> MapGenerator_Stamps::generate()
{
    TypedArray<MapSpritePlacement> placements;

	for (auto [config, coord] : choose_stamp_centers()) {
		auto count_range = config->get_sprite_count_range();
		auto count = use_legacy_distribution
			? std::uniform_int_distribution(count_range.x, count_range.y)(rng)
			: utils::uniform_int_distribution(rng, count_range.x, count_range.y);
		placements.append_array(placer->place_clump(
			config->get_sprite_types(), coord, count, config->get_radius(),
			config->get_sprite_clumping_factor(), config->get_sprite_spacing_multiplier(), config->get_seed_sprite_type()));
	}
	
	return placements;
}

std::vector<std::pair<Ref<MapStampConfig>, Vector2>> MapGenerator_Stamps::choose_stamp_centers()
{
	struct StampScratch {
		Ref<MapStampConfig> config;
		int count;
		std::vector<bool> allowed_bitmap;
		std::vector<Vector2i> valid_centers;
	};

	// Choose stamp counts.
	std::vector<StampScratch> stamp_scratches;
	for (int i = 0; i < stamp_configs.size(); ++i) {
		Ref<MapStampConfig> stamp_config = stamp_configs[i];
		auto count_range = stamp_config->get_stamp_count_range();
		auto count = use_legacy_distribution
			? std::uniform_int_distribution(count_range.x, count_range.y)(rng)
			: utils::uniform_int_distribution(rng, count_range.x, count_range.y);
		if (count > 0) {
			stamp_scratches.push_back(StampScratch {
				stamp_config,
				count,
				std::vector<bool>(biome_bitmap.size())
			});
		}
	}

	// Create initial tile validity bitmaps, to be eroded.
	for (auto& scratch : stamp_scratches) {
		for (int i = 0; i < scratch.allowed_bitmap.size(); ++i) {
			scratch.allowed_bitmap[i] = scratch.config->get_allowed_biomes().has(biome_bitmap[i]);
		}
	}

	// Erode each validity bitmap. For `radius` iterations, set neighbors of invalid tiles to invalid.
	std::vector<bool> erosion_buffer(biome_bitmap.size());
	for (auto& scratch : stamp_scratches) {
		erosion_buffer = scratch.allowed_bitmap;
		auto radius = scratch.config->get_radius();
		for (int _r = 0; _r < radius; ++_r) {
			for (int y = 1; y < size.y - 1; ++y) {
				for (int x = 1; x < size.x - 1; ++x) {
					if (!scratch.allowed_bitmap[y * size.x + x]) {
						erosion_buffer[y * size.x + (x - 1)] = false;
						erosion_buffer[y * size.x + (x + 1)] = false;

						erosion_buffer[(y - 1) * size.x + x] = false;
						erosion_buffer[(y - 1) * size.x + (x - 1)] = false;
						erosion_buffer[(y - 1) * size.x + (x + 1)] = false;

						erosion_buffer[(y + 1) * size.x + x] = false;
						erosion_buffer[(y + 1) * size.x + (x - 1)] = false;
						erosion_buffer[(y + 1) * size.x + (x + 1)] = false;
					}
				}
			}
			scratch.allowed_bitmap = erosion_buffer;
		}
	}

	// Generate lists of valid centers.
	for (auto& scratch : stamp_scratches) {
		auto radius = scratch.config->get_radius();
		for (int y = radius; y < size.y - radius; ++y) {
			for (int x = radius; x < size.x - radius; ++x) {
				if (scratch.allowed_bitmap[y * size.x + x]) {
					scratch.valid_centers.emplace_back(x, y);
				}
			}
		}
		if (use_legacy_distribution) {
			std::shuffle(scratch.valid_centers.begin(), scratch.valid_centers.end(), rng);
		} else {
			utils::shuffle(scratch.valid_centers.begin(), scratch.valid_centers.end(), rng);
		}
	}

	// Place stamps in random order.
	std::vector<size_t> scratch_indices;
	for (int i = 0; i < stamp_scratches.size(); ++i) {
		for (int j = 0; j < stamp_scratches[i].count; ++j) {
			scratch_indices.push_back(i);
		}
	}
	if (use_legacy_distribution) {
		std::shuffle(scratch_indices.begin(), scratch_indices.end(), rng);
	} else {
		utils::shuffle(scratch_indices.begin(), scratch_indices.end(), rng);
	}
	std::vector<std::pair<Ref<MapStampConfig>, Vector2>> result;
	std::vector<bool> occupied(biome_bitmap.size(), false);
	for (auto scratch_index : scratch_indices) {
		auto& scratch = stamp_scratches[scratch_index];
		auto& valid_centers = scratch.valid_centers;
		for (int i = valid_centers.size() - 1; i >= 0; --i) {
			auto center = valid_centers[i];
			// Make sure nothing in the radius is occupied.
			if (occupied[center.y * size.x + center.x]) {
				continue;
			}
			bool still_valid = true;
			auto radius = scratch.config->get_radius();
			for (int dy = -radius; dy < radius; ++dy) {
				for (int dx = -radius; dx < radius; ++dx) {
					int sx = center.x + dx;
					int sy = center.y + dy;
					ERR_FAIL_INDEX_V_EDMSG(sx, size.x, {}, "Stamp radius x coord out of range.");
					ERR_FAIL_INDEX_V_EDMSG(sy, size.y, {}, "Stamp radius x coord out of range.");
					if (occupied[sy * size.x + sx]) {
						still_valid = false;
						break;
					}
				}
			}
			if (!still_valid) {
				continue;
			}
			// Place.
			result.emplace_back(scratch.config, center);
			valid_centers.resize(i);  // Remove already examined centers.
			for (int dy = -radius; dy < radius; ++dy) {
				for (int dx = -radius; dx < radius; ++dx) {
					int sx = center.x + dx;
					int sy = center.y + dy;
					occupied[sy * size.x + sx] = true;
				}
			}
			break;
		}
	}

    return result;
}
