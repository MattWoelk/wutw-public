#pragma once

#include <godot_cpp/classes/image_texture.hpp>
#include "map_generator.h"

using namespace godot;

class MapGenerator_Clip {
public:
    MapGenerator_Clip(Vector2i size,
        const PackedByteArray& clouds_sdf,
        const int clip_width,
        const int resolution_multiplier)
        : size(size), clouds_sdf(clouds_sdf), clip_width(clip_width), resolution_multiplier(resolution_multiplier) {}

    Ref<ImageTexture> generate();

private:
    const Vector2i size;
    const PackedByteArray clouds_sdf;
    const int clip_width;
    const int resolution_multiplier;
};
