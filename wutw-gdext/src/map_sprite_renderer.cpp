#include "map_sprite_renderer.h"

#include <vector>
#include <algorithm>
#include <godot_cpp/classes/shader_material.hpp>

static constexpr int BUFFER_WIDTH = 512;

void MapSpriteRenderer::_ready()
{
    multi_mesh.instantiate();
    multi_mesh->set_use_colors(true);
    multi_mesh->set_use_custom_data(false);
    set_multimesh(multi_mesh);
    // HACK: Without this, the extension crashes on reload. See: https://github.com/godotengine/godot/issues/105802
    auto signals = multi_mesh->get_signal_connection_list("changed");
    multi_mesh->disconnect("changed", signals[0].get("callable"));

    quad_mesh.instantiate();
    quad_mesh->set_subdivide_width(5);
    quad_mesh->set_subdivide_depth(5);
    get_multimesh()->set_mesh(quad_mesh);

    _update();
    set_process(true);
}

void MapSpriteRenderer::_process(double p_delta)
{
    if (live_debug) {
        _update_opacities(p_delta);
        _update();
    } else if (need_update) {
        need_update = false;
        _update();
    } else if (!target_opacities.is_empty()) {
        _update_opacities(p_delta);
    }
}

inline void MapSpriteRenderer::set_placements(const TypedArray<MapSpritePlacement>& placements)
{
    this->placements = placements;
    need_update = true;
}

void MapSpriteRenderer::add_placement(const Ref<MapSpritePlacement>& placement)
{
    placements.append(placement);
    need_update = true;
    emit_signal("placement_added", placement);
}

void MapSpriteRenderer::remove_placement(const Ref<MapSpritePlacement>& placement)
{
    placements.erase(placement);
    need_update = true;
    emit_signal("placement_removed", placement);
}

void MapSpriteRenderer::animate_add_placement(const Ref<MapSpritePlacement>& placement)
{
    if (animation_duration <= 0.0f) {
        add_placement(placement);
        return;
    }
    ERR_FAIL_COND_EDMSG(placements.find(placement) != -1, "Can't add existing placement.");
    placements.append(placement);
    opacities[placement] = 0.0f;
    target_opacities[placement] = 1.0f;
    need_update = true;
    emit_signal("placement_added", placement);
}

void MapSpriteRenderer::animate_remove_placement(const Ref<MapSpritePlacement>& placement)
{
    if (animation_duration <= 0.0f) {
        remove_placement(placement);
        return;
    }
    ERR_FAIL_COND_EDMSG(placements.find(placement) == -1, "Can't remove placement not already in the list.");
    opacities[placement] = 1.0f;
    target_opacities[placement] = 2.0f;
    // Actual removal will happen in _process once opacity reaches 0.
    need_update = true;
    emit_signal("placement_removed", placement);
}

inline void MapSpriteRenderer::set_live_debug(bool live_debug)
{
    this->live_debug = live_debug;
}

inline void MapSpriteRenderer::set_draw_debug_footprints(bool draw_debug_footprints)
{
    this->draw_debug_footprints = draw_debug_footprints;
    _update();
}

void MapSpriteRenderer::set_draw_debug_collision(bool draw_debug_collision)
{
    this->draw_debug_collision = draw_debug_collision;
    _update();
}

void MapSpriteRenderer::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_placements", "placements"), &MapSpriteRenderer::set_placements);
    ClassDB::bind_method(D_METHOD("get_placements"), &MapSpriteRenderer::get_placements);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "placements",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpritePlacement"),
        "set_placements", "get_placements");

    ClassDB::bind_method(D_METHOD("add_placement", "placement"), &MapSpriteRenderer::add_placement);
    ClassDB::bind_method(D_METHOD("remove_placement", "placement"), &MapSpriteRenderer::remove_placement);
    ClassDB::bind_method(D_METHOD("animate_add_placement", "placement"), &MapSpriteRenderer::animate_add_placement);
    ClassDB::bind_method(D_METHOD("animate_remove_placement", "placement"), &MapSpriteRenderer::animate_remove_placement);

    ClassDB::bind_method(D_METHOD("set_animation_duration", "duration"), &MapSpriteRenderer::set_animation_duration);
    ClassDB::bind_method(D_METHOD("get_animation_duration"), &MapSpriteRenderer::get_animation_duration);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "animation_duration"), "set_animation_duration", "get_animation_duration");

    ClassDB::bind_method(D_METHOD("set_live_debug", "live_debug"), &MapSpriteRenderer::set_live_debug);
    ClassDB::bind_method(D_METHOD("get_live_debug"), &MapSpriteRenderer::get_live_debug);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "live_debug"), "set_live_debug", "get_live_debug");

    ClassDB::bind_method(D_METHOD("set_draw_debug_footprints", "draw_debug_footprints"), &MapSpriteRenderer::set_draw_debug_footprints);
    ClassDB::bind_method(D_METHOD("get_draw_debug_footprints"), &MapSpriteRenderer::get_draw_debug_footprints);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "draw_debug_footprints"), "set_draw_debug_footprints", "get_draw_debug_footprints");

    ClassDB::bind_method(D_METHOD("set_draw_debug_collision", "draw_debug_collision"), &MapSpriteRenderer::set_draw_debug_collision);
    ClassDB::bind_method(D_METHOD("get_draw_debug_collision"), &MapSpriteRenderer::get_draw_debug_collision);
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "draw_debug_collision"), "set_draw_debug_collision", "get_draw_debug_collision");

    ADD_SIGNAL(MethodInfo("placement_added", PropertyInfo(Variant::OBJECT, "placement", PROPERTY_HINT_RESOURCE_TYPE, "MapSpritePlacement")));
    ADD_SIGNAL(MethodInfo("placement_removed", PropertyInfo(Variant::OBJECT, "placement", PROPERTY_HINT_RESOURCE_TYPE, "MapSpritePlacement")));
}

void MapSpriteRenderer::_update()
{
    Ref<MultiMesh> multimesh = get_multimesh();
    if (!multimesh.is_valid()) return;

    if (placements.is_empty()) {
        multimesh->set_instance_count(0);
        return;
    }

    // Sort instances by Y coordinate.
    std::vector<MapSpritePlacement*> sorted_placements;
    for (int i = 0; i < placements.size(); ++i) {
        Ref<MapSpritePlacement> placement = placements[i];
        ERR_CONTINUE_EDMSG(!placement.is_valid(), "Invalid sprite placement at index " + String::num(i) + ".");
        ERR_CONTINUE_EDMSG(!placement->get_sprite_type().is_valid(), "Invalid sprite at index " + String::num(i) + ".");
        sorted_placements.push_back(*placement);
    }
    if (sorted_placements.empty()) return;

    std::sort(sorted_placements.begin(), sorted_placements.end(), [](const auto* a, const auto* b) {
        if (a->get_sprite_type()->get_z_index() != b->get_sprite_type()->get_z_index()) {
            return a->get_sprite_type()->get_z_index() < b->get_sprite_type()->get_z_index();
        } else {
            return a->get_location().y < b->get_location().y;
        }
    });

    // Count total instances.
    int count = 0;
    for (auto* placement : sorted_placements) {
        count += placement->get_sprite_type()->get_total_instances();
        if (draw_debug_footprints) {
            count += 1;
        }
        if (draw_debug_collision) {
            count += placement->get_sprite_type()->get_collision().size();
        }
    }
    multimesh->set_instance_count(count);
    instance_buffer.resize(count);

    // Separate prepass groups.
    std::vector<std::pair<int, int>> batches;
    int next_placement_index = 0;
    int cur_batch_start = 0;
    bool cur_batch_has_prepass = Ref<MapSpritePlacement>(sorted_placements[0])->get_sprite_type()->has_prepass();
    for (auto* placement : sorted_placements) {
        if (placement->get_sprite_type()->has_prepass() != cur_batch_has_prepass) {
            ERR_FAIL_COND_EDMSG(cur_batch_start >= next_placement_index, "Invalid batch start index.");
            batches.push_back({ cur_batch_start, next_placement_index - cur_batch_start });
            cur_batch_start = next_placement_index;
            cur_batch_has_prepass = !cur_batch_has_prepass;
        }
        next_placement_index += 1;
    }
    if (cur_batch_start < next_placement_index) {
        batches.push_back({ cur_batch_start, next_placement_index - cur_batch_start });
        cur_batch_start = next_placement_index;
    }

    instance_buffer_ptrs.clear();
    for (int i = 0; i < placements.size(); ++i) {
        instance_buffer_ptrs[placements[i]] = Vector4i(-1, -1 ,-1, -1);
    }

    // Add instances.
    MapInstanceData* buffer_ptr = instance_buffer.data();
    MapInstanceData* cur_buffer_ptr = buffer_ptr;
    for (auto& batch : batches) {
        // Prepass.
        for (int i = batch.first; i < batch.first + batch.second; ++i) {
            auto* placement = sorted_placements[i];
            int count = placement->get_sprite_type()->add_prepass_instances(
                cur_buffer_ptr, placement->get_location(), placement->get_scale());
            instance_buffer_ptrs[Ref<MapSpritePlacement>(placement)] =
                Vector4i(cur_buffer_ptr - buffer_ptr, count, -1, -1);
            cur_buffer_ptr += count;
        }
        // Main pass.
        for (int i = batch.first; i < batch.first + batch.second; ++i) {
            auto* placement = sorted_placements[i];
            int count = placement->get_sprite_type()->add_instances(
                cur_buffer_ptr, placement->get_location(), placement->get_scale());
            Vector4i existing = instance_buffer_ptrs[Ref<MapSpritePlacement>(placement)];
            instance_buffer_ptrs[Ref<MapSpritePlacement>(placement)] =
                Vector4i(existing.x, existing.y, cur_buffer_ptr - buffer_ptr, count);
            cur_buffer_ptr += count;
        }
    }
    // Debug pass.
    if (draw_debug_footprints) {
        for (int i = 0; i < sorted_placements.size(); ++i) {
            cur_buffer_ptr += add_footprint_instance(cur_buffer_ptr, *sorted_placements[i]);
        }
    }
    if (draw_debug_collision) {
        for (int i = 0; i < sorted_placements.size(); ++i) {
            cur_buffer_ptr += add_collision_instances(cur_buffer_ptr, *sorted_placements[i]);
        }
    }

    ERR_FAIL_COND_EDMSG(cur_buffer_ptr - buffer_ptr != count, "Instance count mismatch: expected " + String::num(count) + ", got " + String::num(cur_buffer_ptr - buffer_ptr) + ".");

    _update_buffer_texture(false);

    queue_redraw();
}

void MapSpriteRenderer::_update_opacities(float delta)
{
    Ref<MultiMesh> multimesh = get_multimesh();
    if (!multimesh.is_valid()) return;

    auto updating_placements = target_opacities.keys();
    for (auto it = updating_placements.begin(); it != updating_placements.end(); ++it) {
        Ref<MapSpritePlacement> placement = *it;

        if (!instance_buffer_ptrs.has(placement)) {
            // Has been removed.
            opacities.erase(placement);
            target_opacities.erase(placement);
            continue;
        }

        float current_opacity = opacities[placement];
        float target_opacity = target_opacities[placement];
        float opacity_diff = target_opacity - current_opacity;
        if (Math::is_zero_approx(opacity_diff)) {
            // Reached target opacity; remove.
            if (Math::is_equal_approx(target_opacity, 2.f)) {  // 2 means end of fade out
                placements.erase(placement);
            }
            opacities.erase(placement);
            target_opacities.erase(placement);
            need_update = true;
        } else {
            // Update opacity.
            float step = delta / animation_duration;
            if (std::abs(opacity_diff) <= step) {
                current_opacity = target_opacity;
            } else {
                current_opacity += Math::sign(opacity_diff) * step;
            }
            opacities[placement] = current_opacity;
        }
    }

    _update_buffer_texture(true);
}

void MapSpriteRenderer::_update_buffer_texture(bool opacities_only)
{
    // Ensure the texture is large enough.
    int instance_count = instance_buffer.size();
    int pixel_count = instance_count * 2;
    int height = (pixel_count / BUFFER_WIDTH) + 1;
    if (!custom_data_image.is_valid() || pixel_count > custom_data_image->get_width() * custom_data_image->get_height()) {
        ERR_FAIL_COND_EDMSG(opacities_only && custom_data_image.is_valid(), "Opacities-only change found size mismatch.");
        custom_data_image = Image::create_empty(BUFFER_WIDTH, height, false, Image::FORMAT_RGBAF);
        custom_data_texture = ImageTexture::create_from_image(custom_data_image);
        Ref<ShaderMaterial> mat = get_material();
        if (mat.is_valid()) {
            mat = mat->duplicate();
            mat->set_shader_parameter("custom_data_texture", custom_data_texture);
            set_material(mat);
        }
    }

    PackedByteArray img_data = custom_data_image->get_data();
    float* img_ptr = reinterpret_cast<float*>(img_data.ptrw());

    // Write base data.
    const int stride = 8;  // 2 pixels per instance, 4 channels per pixel
    if (!opacities_only) {
        for (int i = 0; i < instance_count; ++i) {
            const MapInstanceData& data = instance_buffer[i];
            multi_mesh->set_instance_transform_2d(i, data.transform);
            multi_mesh->set_instance_color(i, data.vertex_color);
            int tex_idx = i * stride;
            img_ptr[tex_idx + 0] = data.custom_data.r;
            img_ptr[tex_idx + 1] = data.custom_data.g;
            img_ptr[tex_idx + 2] = data.custom_data.b;
            img_ptr[tex_idx + 3] = data.custom_data.a;
        }
    }

    // Write opacities.
    Array placements_to_update;
    if (opacities_only) {
        placements_to_update = opacities.keys();
    } else {
        placements_to_update = placements;
    }
    for (int i = 0; i < placements_to_update.size(); ++i) {
        Ref<MapSpritePlacement> placement = placements_to_update[i];
        float opacity = get_opacity(placement);
        Vector4i indices = instance_buffer_ptrs[placement];
        if (indices.y > 0) {
            for (int j = indices.x; j < indices.x + indices.y; ++j) {
                img_ptr[j * stride + 4] = opacity;
            }
        }
        if (indices.w > 0) {
            for (int j = indices.z; j < indices.z + indices.w; ++j) {
                img_ptr[j * stride + 4] = opacity;
            }
        }
    }

    // Push to GPU.
    custom_data_image->set_data(custom_data_image->get_width(), custom_data_image->get_height(), false, Image::FORMAT_RGBAF, img_data);
    custom_data_texture->update(custom_data_image);
}

int MapSpriteRenderer::add_footprint_instance(MapInstanceData* output_buffer, const MapSpritePlacement& placement)
{
    float radius = placement.get_sprite_type()->get_footprint_radius();
    Vector2 footprint_size = Vector2(2, 2) * radius * placement.get_scale();
    output_buffer->transform = Transform2D(0, footprint_size, 0.0, placement.get_location());
    output_buffer->vertex_color = Color(1.f, 1.f, 1.f, 1.f);
    output_buffer->custom_data = Color(0, 0, 0, 0);
    return 1;
}

int MapSpriteRenderer::add_collision_instances(MapInstanceData* output_buffer, const MapSpritePlacement& placement)
{
    auto collision = placement.get_sprite_type()->get_collision();
    for (int i = 0; i < collision.size(); ++i) {
        Ref<MapSpriteCollision> shape = collision[i];
        ERR_CONTINUE_EDMSG(!shape.is_valid(), "Invalid sprite collision at index " + String::num(i) + ".");
        shape->add_mesh_instance(output_buffer, placement.get_location(), placement.get_scale());
        output_buffer++;
    }

    return collision.size();
}

float MapSpriteRenderer::get_opacity(Ref<MapSpritePlacement> placement) const
{
    return opacities.get(placement, 1.f);
}
