#include "map_generator_shard_base.h"
#include <algorithm>
#include "generated_map.h"
#include "utils.h"

static constexpr float DISTANCE_RANGE = 10.f;

std::vector<MapGenerator_ShardBase::OutlineSection> MapGenerator_ShardBase::get_shard_outline_sections() {
    // Find first land pixel from top-center.
    Vector2i center = size / 2;
    int start_y = -1;
    for (int y = 0; y < size.y; ++y) {
        if (is_land(center.x, y)) {
            start_y = y;
            break;
        }
    }
    ERR_FAIL_COND_V_EDMSG(start_y < 0, {}, "Can't find shard center.");

    // Walk boundary.
    // Set up 8-neighbour directions in CCW order.
    static const Vector2i DIRS[8] = {
        { 1,  0}, // East
        { 1, -1}, // North-east
        { 0, -1}, // North
        {-1, -1}, // North-west
        {-1,  0}, // West
        {-1,  1}, // South-west
        { 0,  1}, // South
        { 1,  1}, // South-east
    };
    // Start on the boundary facing west.
    Vector2i start_pt(center.x, start_y);
    Vector2i curr_pt = start_pt;
    int prev_dir = 5; // south-west
    // Run builder state.
    std::vector<OutlineSection> sections;
    std::vector<Vector2i> run_points;
    Vector2i run_start;
    int steps = 0, max_steps = size.x * size.y;  // Safety guard.
    while (steps++ < max_steps) {
        bool found = false;
        int next_dir = -1;
        for (int offset = -3; offset < 5; ++offset) {
            int d = (prev_dir + offset + 8) % 8;
            Vector2i nb = curr_pt + DIRS[d];
            if (is_land(nb.x, nb.y)) {
                found = true;
                next_dir = d;
                break;
            }
        }
        ERR_FAIL_COND_V_EDMSG(!found, {}, "Can't find shard outline step.");

        Vector2i step = DIRS[next_dir];
        // Approximate outward normal of this edge is (step.y, -step.x).
        // We only care about its Y component.
        int normal_y = -step.x;

        constexpr int MIN_POINTS_TO_FLUSH = 4;
        if (normal_y >= 0) {
            // Above-horizon or flat edge: flush any active run if long enough.
            if (!run_points.empty()) {
                run_points.push_back(curr_pt + step);
                if (run_points.size() >= MIN_POINTS_TO_FLUSH) {
                    sections.emplace_back(run_points);
                    run_points.clear();
                }
            }
        } else {
            // Below-horizon edge: accumulate into the current run.
            if (run_points.empty()) {
                run_points.push_back(curr_pt);
                run_start = curr_pt;
                if (!sections.empty()) {
                    auto& last = sections.back();
                    if (last.end().x == curr_pt.x && last.end().y != curr_pt.y) {
                        // Include missed vertical edge.
                        run_start = last.end();
                        run_points.insert(run_points.begin(), run_start);
                    }
                }
            } else {
                run_points.push_back(curr_pt + step);
            }
        }

        // Advance.
        prev_dir = next_dir;
        curr_pt += step;
        // When we return to start, we are done.
        if (curr_pt == start_pt) break;
    }

    // Blur each raw section and split where Y direction changes.
    constexpr int BLUR_NEIGHBORHOOD = 4;
    constexpr float MIN_SPLIT_LENGTH = 10.f;
    std::vector<Vector2i> leftover_points;
    std::vector<OutlineSection> split_sections;
    for (auto& sec : sections) {
        if ((sec.end() - sec.start()).length() < MIN_SPLIT_LENGTH) {
            split_sections.push_back(sec);
            continue;
        }

        // Merge leftover + current.
        std::vector<Vector2i> raw_pts = leftover_points;
        raw_pts.insert(raw_pts.end(), sec.points.begin(), sec.points.end());
        leftover_points.clear();

        // Blur the points to approximate the smooth SDF boundary.
        int n = raw_pts.size();
        std::vector<Vector2> blurred;
        blurred.reserve(n);
        for (int i = 0; i < n; ++i) {
            float sum_y = 0;
            int count = 0;
            for (int j = i - BLUR_NEIGHBORHOOD; j <= i + BLUR_NEIGHBORHOOD; ++j) {
                if (j >= 0 && j < n) {
                    sum_y += raw_pts[j].y;
                    count++;
                }
            }
            blurred.emplace_back(float(raw_pts[i].x), sum_y / count);
        }

        // Walk blurred points and split on Y-direction flips.
        int seg_start = 0;
        float last_three_dy[3] = { 0, 0, 0 };
        for (int k = 1; k < n; ++k) {
            float last_dy = (last_three_dy[0] + last_three_dy[1] + last_three_dy[2]) / 3.0;
            float dy = blurred[k].y - blurred[k - 1].y;
            float length = (blurred[seg_start] - blurred[k]).length();
            if (dy * last_dy < 0 || abs(dy - last_dy) > (1.1 - length * 0.03)) {
                split_sections.emplace_back(std::vector<Vector2i>(raw_pts.begin() + seg_start, raw_pts.begin() + k));
                seg_start = k - 1;
            }
            last_three_dy[0] = last_three_dy[1];
            last_three_dy[1] = last_three_dy[2];
            last_three_dy[2] = dy;
        }
        if (n > seg_start) {
            split_sections.emplace_back(std::vector<Vector2i>(raw_pts.begin() + seg_start, raw_pts.end()));
        }
    }
    if (!leftover_points.empty()) {
        split_sections.emplace_back(leftover_points);
    }

    return split_sections;
}

Ref<Image> MapGenerator_ShardBase::draw_shard_outline_sections(const std::vector<OutlineSection>& sections) {
    int resolution_multiplier = config->get_resolution_multiplier();
    int width = size.x * resolution_multiplier;
    int height = size.y * resolution_multiplier;

    auto shard_base_image = Image::create(width, height, false, Image::FORMAT_RGBA8);

    // Initialize distance to edge with maximum.
    for (int x = 0; x < width; ++x) {
        for (int y = 0; y < height; ++y) {
            shard_base_image->set_pixel(x, y, Color(1, 0, 0, 0));
        }
    }

    // Sort to have lower sections later.
    std::vector<OutlineSection> sorted_sections = sections;
    std::sort(sorted_sections.begin(), sorted_sections.end(), [](auto& a, auto& b) { return a.max_y < b.max_y; });
    
	// Draw each section as a triangle perturbed by a curve.
	// TODO: Can we use actual polygons instead?
    int pyramid_tip_y = Math::round(size.y * 1.5f) * resolution_multiplier - 1;
    constexpr int MIN_LENGTH_TO_DRAW = 6;
    constexpr int DRAW_MARGIN = 5;
    for (auto& section : sorted_sections) {
        if (std::abs(section.start().x - section.end().x) < MIN_LENGTH_TO_DRAW) {
            continue; // Drawing this will just add noise.
        }

        auto section_center = Vector2(section.start() + section.end()) * 0.5f;
        auto dir_around = Vector2(section.end() - section.start());
        Vector2 dir_to_center = section_center - Vector2(size.x, size.y) / 2.0f;
        float angle_around = fmodf(dir_around.angle_to(Vector2(0, -1)) + Math_PI * 1.5f, Math_TAU);
        float angle_to_center = dir_to_center.angle_to(Vector2(0, -1));
        float angle = std::max(angle_around, angle_to_center);
        int angle_remapped = Math::round(Math::remap(angle, float(-Math_PI), float(Math_PI), 0.f, 255.f));
        auto curve = config->get_cliff_curve();
        for (int y = section.min_y * resolution_multiplier; y < height; ++y) {
            float y_t = float(y - section.min_y * resolution_multiplier) / pyramid_tip_y;
            Vector2 bottom_center(size.x / 2.f, size.y * curve->sample(y_t));

            float start_t = Math::clamp(Math::remap(float(y) / resolution_multiplier, float(section.start().y), bottom_center.y, 0, 1), 0.f, 1.f);
            float end_t = Math::clamp(Math::remap(float(y) / resolution_multiplier, float(section.end().y), bottom_center.y, 0, 1), 0.f, 1.f);
            int start_x = Math::floor(start_t * (bottom_center.x - section.start().x) + section.start().x) * resolution_multiplier;
            int end_x = Math::ceil(end_t * (bottom_center.x - section.end().x) + section.end().x) * resolution_multiplier;
            if (start_x > end_x) std::swap(start_x, end_x);

            bool all_land = true;
            for (int x = std::max(0, start_x - DRAW_MARGIN); x < std::min(width, end_x + DRAW_MARGIN); ++x) {
                if (y > section.max_y * resolution_multiplier) {
                    // Hit land. Stop drawing section!
                    if (is_land(x / resolution_multiplier, y / resolution_multiplier)) continue;
                }
                all_land = false;

                Color color = shard_base_image->get_pixel(x, y);
                auto point = Vector2(x, y) / resolution_multiplier;

                float min_dist_to_edge, min_dist_to_area;
                float dist_to_start = signed_distance_point_to_line(point, Vector2(section.start()), bottom_center);
                if (dist_to_start < 0) {
                    min_dist_to_edge = -dist_to_start;
                    min_dist_to_area = -dist_to_start;
                } else {
                    float dist_to_end = -signed_distance_point_to_line(point, Vector2(section.end()), bottom_center);
                    if (dist_to_end < 0) {
                        min_dist_to_edge = -dist_to_end;
                        min_dist_to_area = -dist_to_end;
                    } else {
                        min_dist_to_edge = std::min(dist_to_start, dist_to_end);
                        min_dist_to_area = 0;
                    }
                }

                float existing_dist_to_edge = Math::remap(color.r, 0, 1, 0, DISTANCE_RANGE);
                float existing_dist_to_area = Math::remap(color.a, 1, 0, 0, DISTANCE_RANGE);
                if (min_dist_to_area > 0) {
                    // Outside the area; take into account existing data.
                    min_dist_to_edge = std::min(existing_dist_to_edge, min_dist_to_edge);
                }

                int min_dist_to_edge_remapped = Math::round(Math::remap(min_dist_to_edge, 0, DISTANCE_RANGE, 0, 255));
                int min_dist_to_area_remapped = Math::round(Math::remap(std::min(existing_dist_to_area, min_dist_to_area), 0, DISTANCE_RANGE, 255, 0));

                color.set_r8(min_dist_to_edge_remapped);
                color.set_a8(min_dist_to_area_remapped);
                if (min_dist_to_area <= 0 || existing_dist_to_area > 0) {
                    float x_top_start = section.points.front().x;
                    float x_top_end = section.points.back().x;
                    if (x_top_start > x_top_end) std::swap(x_top_start, x_top_end);
                    float x_top = utils::remap(x, start_x, end_x, x_top_start, x_top_end);
                    float y_section = section.find_closest_y(x_top);
                    int y_dist = point.y - y_section;
                    color.set_g8(y_dist);  // Better color resolution.
                    color.set_b8(angle_remapped);
                }
                shard_base_image->set_pixel(x, y, color);
            }

            if (all_land) break; // Hit land. Give up.
        }
    }

    // Fill gaps created by skipping small sections and curving the outlines.
    for (int y = 1; y < height; ++y) {  // Start from 1 for easy indexing; y=0 is always outside.
		// First, walk from each end to find the start/end of the shard.
        int start_x = -1, end_x = -1;
        for (int x = 0; x < width; ++x) {
            Color c = shard_base_image->get_pixel(x, y);
            float dist_to_area = Math::remap(c.get_a8(), 255, 0, 0, DISTANCE_RANGE);
            if (dist_to_area <= 0 || is_land(x / resolution_multiplier, y / resolution_multiplier)) {
                start_x = x;
                break;
            }
        }
        if (start_x < 0) continue;
        for (int x = width - 1; x >= 0; --x) {
            Color c = shard_base_image->get_pixel(x, y);
            float dist_to_area = Math::remap(c.get_a8(), 255, 0, 0, DISTANCE_RANGE);
            if (dist_to_area <= 0 || is_land(x / resolution_multiplier, y / resolution_multiplier)) {
                end_x = x;
                break;
            }
        }
        ERR_FAIL_COND_V_EDMSG(end_x < 0, nullptr, "Can't find end X when filling shard base gaps.");

        // Now walk from the determined start and end.
        for (int x = start_x; x < end_x; ++x) {
            Color color = shard_base_image->get_pixel(x, y);
            float dist_to_area = Math::remap(color.get_a8(), 255, 0, 0, DISTANCE_RANGE);
            bool should_fill = false;
            if (dist_to_area > 0) {
                Color color_above = shard_base_image->get_pixel(x, y - 1);
                float distance_to_area_above = Math::remap(color_above.get_a8(), 255, 0, 0, DISTANCE_RANGE);
                if (distance_to_area_above <= 0) {
                    should_fill = true;
                } else if (is_land(x / resolution_multiplier, y / resolution_multiplier - 1)
                        && is_land(x / resolution_multiplier - 1, y / resolution_multiplier - 1)
                        && is_land(x / resolution_multiplier + 1, y / resolution_multiplier - 1)) {
                    should_fill = true;
                }
            }
            if (should_fill) {
                Color left = shard_base_image->get_pixel(x - 1, y);
                Color right = shard_base_image->get_pixel(x + 1, y);
                Color out;
                out.r = (left.r + right.r) / 2.f;  // min_dist_to_edge
                out.g = left.g;  // dy
                out.b = 0.0f;  // angle; constant adds variety / visual interest.
                out.a = 1.0f;  // min_dist_to_area
                shard_base_image->set_pixel(x, y, out);
            }
        }
    }

    return shard_base_image;
}

PackedByteArray MapGenerator_ShardBase::generate_distance_to_land(const Ref<Image>& shard_base_image)
{
    // Make a bitmap for the "land", which is the shard surface + top N units of the shard base.
    PackedByteArray land_bitmap;
    land_bitmap.resize(size.y * size.x);
    int resolution_multiplier = config->get_resolution_multiplier();
    int y_dist_threshold = config->get_height_above_clouds();
    for (int y = 0; y < size.y; ++y) {
        for (int x = 0; x < size.x; ++x) {
            if (is_land(x, y)) {
                land_bitmap[y * size.x + x] = 1;
            } else {
                int x_offset = x * resolution_multiplier;
                int y_offset = y * resolution_multiplier;
                int num_samples = resolution_multiplier * resolution_multiplier;
                float sum_y_dist = 0.0;
                bool all_in_area = true;
                for (int dy = 0; dy < resolution_multiplier; ++dy) {
                    for (int dx = 0; dx < resolution_multiplier; ++dx) {
                        int xi = x_offset + dx;
                        int yi = y_offset + dy;
                        Color sample = shard_base_image->get_pixel(xi, yi);
                        sum_y_dist += sample.get_g8();
                        if (sample.a < 1.0) {
                            all_in_area = false;
                            break;
                        }
                    }
                }
                if (all_in_area) {
                    if (sum_y_dist / num_samples <= y_dist_threshold) {
                        land_bitmap[y * size.x + x] = 1;
                    }
                }
            }
        }
    }
    return land_bitmap;
}

Ref<Image> MapGenerator_ShardBase::generate_land_depth(const std::vector<OutlineSection>& sections, const Ref<Image>& shard_base_image)
{
    int resolution_multiplier = config->get_resolution_multiplier();
    int width = size.x * resolution_multiplier;
    int height = size.y * resolution_multiplier;
    PackedByteArray output_packed;
    output_packed.resize(width * height);
    auto output_bitmap = output_packed.ptrw();  // faster access

    // Sort to have lower sections later.
    std::vector<OutlineSection> sorted_sections(sections);
    std::sort(sorted_sections.begin(), sorted_sections.end(), [](const auto& a, const auto& b) { return a.max_y < b.max_y; });

    int pyramid_tip_y = Math::round(size.y * 1.5f) * resolution_multiplier - 1;
    for (auto& section : sorted_sections) {
        auto section_center = Vector2(section.start() + section.end()) * 0.5f;
        auto curve = config->get_cliff_curve();
        for (int y = section.min_y * resolution_multiplier; y < size.y * resolution_multiplier; ++y) {
            // Perturb with a curve. TODO: Share this duplicate logic with draw_shard_outline_sections().
            float y_t = float(y - section.min_y * resolution_multiplier) / pyramid_tip_y;
            Vector2 bottom_center(size.x / 2.f, size.y * curve->sample(y_t));

            float start_t = Math::clamp(Math::remap(float(y) / resolution_multiplier, float(section.start().y), bottom_center.y, 0, 1), 0.f, 1.f);
            float end_t = Math::clamp(Math::remap(float(y) / resolution_multiplier, float(section.end().y), bottom_center.y, 0, 1), 0.f, 1.f);
            int start_x = Math::floor(start_t * (bottom_center.x - section.start().x) + section.start().x) * resolution_multiplier;
            int end_x = Math::ceil(end_t * (bottom_center.x - section.end().x) + section.end().x) * resolution_multiplier;
            if (start_x > end_x) std::swap(start_x, end_x);

            for (int x = std::max(0, start_x); x < std::min(width, end_x); ++x) {
                auto point = Vector2(x, y) / resolution_multiplier;
                float min_dist_to_area;
                float dist_to_start = signed_distance_point_to_line(point, Vector2(section.start()), bottom_center);
                if (dist_to_start < 0) {
                    min_dist_to_area = -dist_to_start;
                } else {
                    float dist_to_end = -signed_distance_point_to_line(point, Vector2(section.end()), bottom_center);
                    if (dist_to_end < 0) {
                        min_dist_to_area = -dist_to_end;
                    } else {
                        // Both positive. Between start and end.
                        min_dist_to_area = 0;
                    }
                }

                if (min_dist_to_area <= 0) {
                    output_bitmap[y * width + x] = section.max_y / float(size.y) * 255;
                }
            }
        }
    }

    for (int y = 1; y < height; ++y) {  // Start from 1 for easy indexing; y=0 is always outside.
        for (int x = 1; x < width; ++x) {
            float distance_to_area = Math::remap(shard_base_image->get_pixel(x, y).get_a8(), 255, 0, 0, DISTANCE_RANGE);
            if (distance_to_area <= 0) {
                uint8_t depth = output_bitmap[y * width + x];
                uint8_t depth_left = output_bitmap[y * width + (x - 1)];
                uint8_t depth_above = output_bitmap[(y - 1) * width + x];
                uint8_t depth_other = std::min(depth_left, depth_above);
                if (depth < depth_other) {
                    output_bitmap[y * width + x] = depth_other;
                }
            } else {
                output_bitmap[y * width + x] = 0;
            }
        }
    }

    // Move the image up and left half a pixel with AA.
    for (int x = 0; x < width; ++x) {
        for (int y = 0; y < height; ++y) {
            float distance = utils::sample_aa(output_packed, Vector2(x - 0.5f, y - 0.5f), Vector2i(width, height));
            output_bitmap[y * width + x] = round(distance);
        }
    }

    // Draw the shard top with AA.
    for (int x = 0; x < width; ++x) {
        for (int y = 0; y < height; ++y) {
            float float_x = float(x) / resolution_multiplier - 0.5f;
            float float_y = float(y) / resolution_multiplier - 0.5f;
            float distance = utils::sample_aa(clouds_sdf, Vector2(float_x, float_y), size);
            if (distance > 127.5f) {  // Match the border to hide the seams.
                output_bitmap[y * width + x] = 255;
            }
        }
    }

    return Image::create_from_data(width, height, false, Image::FORMAT_R8, output_packed);
}

TypedArray<Vector2> MapGenerator_ShardBase::generate_edge_clouds(const std::vector<OutlineSection>& sections)
{
    float spacing = config->get_edge_cloud_spacing();
    float unaccounted_distance = 0.0f;
    TypedArray<Vector2> cloud_points;
    for (const auto& section : sections) {
        Vector2 section_vector(section.end() - section.start());
        float section_length = section_vector.length();
        float cur_pos = spacing - unaccounted_distance;

        while (cur_pos <= section_length) {
            Vector2 point = Vector2(section.start()) + section_vector.normalized() * cur_pos;

            // Replicate the shard base curve logic from draw_shard_outline_sections().
            point.y += config->get_height_above_clouds();
            Ref<Curve> curve = config->get_cliff_curve();
            float y = point.y;
            float y_t = float(y - section.min_y) / size.y;
            Vector2 bottom_center(size.x / 2.f, size.y * curve->sample(y_t));
            point.x = Math::remap(y, point.y, bottom_center.y, point.x, bottom_center.x);

            // Ensure the cloud is clear of land at the top if possible.
            int approx_half_width = 24;
            int approx_half_height = 10;
            int approx_top_of_cloud = point.y - approx_half_height;
            for (int dy = 0; dy < 2 * approx_half_height; ++dy) {
                bool found_clear_line = true;
                for (int dx = -approx_half_width; dx < approx_half_width; ++dx) {
                    if (is_land(point.x + dx, approx_top_of_cloud + dy)) {
                        found_clear_line = false;
                        break;
                    }
                }
                if (found_clear_line) {
                    point.y += dy;
                    break;
                }
            }

            cloud_points.append(point);
            cur_pos += spacing;
        }

        unaccounted_distance = (section_length - (cur_pos - spacing));
    }
    return cloud_points;
}

float MapGenerator_ShardBase::signed_distance_point_to_line(const Vector2& p, const Vector2& a, const Vector2& b) const {
    Vector2 d = b - a;
    return (p - a).cross(d) / d.length();
}

bool MapGenerator_ShardBase::is_land(int x, int y) const
{
    if (unlikely(x < 0 || x >= size.x)) return false;
    if (unlikely(y < 0 || y >= size.y)) return false;
    return clouds_sdf[y * size.x + x] > 127;
    //return biome_bitmap[y * size.x + x] != Biome::CLOUDS;
}

float MapGenerator_ShardBase::OutlineSection::find_closest_y(float x) const {
    // TODO: This could use a binary search for the common case where the points are sorted.
    if (points.size() == 1) return points.front().y;

    const Vector2i* left = nullptr;
    const Vector2i* right = nullptr;
    for (const auto& p : points) {
        if (p.x <= x) {
            if (!left || p.x > left->x) left = &p;
        }
        if (p.x >= x) {
            if (!right || p.x < right->x) right = &p;
        }
    }

    if (!left) return static_cast<float>(right->y);
    if (!right) return static_cast<float>(left->y);
    if (left->x == right->x) return static_cast<float>(left->y);

    float t = (x - left->x) / float(right->x - left->x);
    return left->y + t * (right->y - left->y);
}
