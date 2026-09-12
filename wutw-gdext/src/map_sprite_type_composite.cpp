#include "map_sprite_type_composite.h"

void MapSpriteComponent::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_sprite_type", "sprite_type"), &MapSpriteComponent::set_sprite_type);
    ClassDB::bind_method(D_METHOD("get_sprite_type"), &MapSpriteComponent::get_sprite_type);
    ADD_PROPERTY(PropertyInfo(Variant::OBJECT, "sprite_type", PROPERTY_HINT_RESOURCE_TYPE, "MapSpriteType"), "set_sprite_type", "get_sprite_type");

    ClassDB::bind_method(D_METHOD("set_offset", "offset"), &MapSpriteComponent::set_offset);
    ClassDB::bind_method(D_METHOD("get_offset"), &MapSpriteComponent::get_offset);
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "offset"), "set_offset", "get_offset");

    ClassDB::bind_method(D_METHOD("set_scale", "scale"), &MapSpriteComponent::set_scale);
    ClassDB::bind_method(D_METHOD("get_scale"), &MapSpriteComponent::get_scale);
    ADD_PROPERTY(PropertyInfo(Variant::FLOAT, "scale"), "set_scale", "get_scale");
}

TypedArray<MapEffectAttachment> MapSpriteType_Composite::get_effects_recursive() const {
    TypedArray<MapEffectAttachment> output;
    for (int i = 0; i < components.size(); ++i) {
        Ref<MapSpriteComponent> component = components[i];
        if (!component.is_valid() || !component->get_sprite_type().is_valid()) continue;
        auto child_effects = component->get_sprite_type()->get_effects_recursive();
        for (int j = 0; j < child_effects.size(); ++j) {
            Ref<MapEffectAttachment> attachment = child_effects[j];
            attachment = attachment->duplicate();
            auto effective_offset = component->get_offset() + attachment->get_offset() * component->get_scale() * component->get_sprite_type()->get_default_scale();
            auto effective_scale = attachment->get_scale() * component->get_scale() * component->get_sprite_type()->get_default_scale();
            attachment->set_offset(effective_offset);
            attachment->set_scale(effective_scale);
            output.append(attachment);
        }
    }
    output.append_array(effects);
    return output;
}

int MapSpriteType_Composite::get_total_instances() const
{
    int total = 0;
    for (int i = 0; i < components.size(); ++i) {
        Ref<MapSpriteComponent> component = components[i];
        if (!component.is_valid() || !component->get_sprite_type().is_valid()) continue;
        total += component->get_sprite_type()->get_total_instances();
    }
    return total;
}

bool MapSpriteType_Composite::has_prepass() const
{
    for (int i = 0; i < components.size(); ++i) {
        Ref<MapSpriteComponent> component = components[i];
        if (!component.is_valid() || !component->get_sprite_type().is_valid()) continue;
        if (component->get_sprite_type()->has_prepass()) {
            return true;
        }
    }
    return false;
}

int MapSpriteType_Composite::add_prepass_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    int total = 0;
    for (int i = 0; i < components.size(); ++i) {
        Ref<MapSpriteComponent> component = components[i];
        if (!component.is_valid() || !component->get_sprite_type().is_valid()) continue;
        auto effective_location = location + component->get_offset() * scale / default_scale;
        float effective_scale = scale * component->get_sprite_type()->get_default_scale() * component->get_scale();
        auto count = component->get_sprite_type()->add_prepass_instances(
            output_buffer, effective_location, effective_scale);
        output_buffer += count;
        total += count;
    }
    return total;
}

int MapSpriteType_Composite::add_instances(MapInstanceData* output_buffer, const Vector2& location, const float scale) const
{
    int total = 0;
    for (int i = 0; i < components.size(); ++i) {
        Ref<MapSpriteComponent> component = components[i];
        if (!component.is_valid() || !component->get_sprite_type().is_valid()) continue;
        auto effective_location = location + component->get_offset() * scale / default_scale;
        float effective_scale = scale * component->get_sprite_type()->get_default_scale() * component->get_scale();
        auto count = component->get_sprite_type()->add_instances(
            output_buffer, effective_location, effective_scale);
        output_buffer += count;
        total += count;
    }
    return total;
}

void MapSpriteType_Composite::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("set_components", "components"), &MapSpriteType_Composite::set_components);
    ClassDB::bind_method(D_METHOD("get_components"), &MapSpriteType_Composite::get_components);
    ADD_PROPERTY(
        PropertyInfo(
            Variant::ARRAY,
            "components",
            PROPERTY_HINT_TYPE_STRING,
            String::num(Variant::OBJECT) + "/" + String::num(PROPERTY_HINT_RESOURCE_TYPE) + ":MapSpriteComponent"
        ),
        "set_components", "get_components");
}
