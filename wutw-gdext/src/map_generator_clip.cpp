#include "map_generator_clip.h"

#include "utils.h"

Ref<ImageTexture> MapGenerator_Clip::generate()
{
    const float min_threshold = 127.5f - clip_width / 2.0f;
    const float max_threshold = 127.5f + clip_width / 2.0f;
    auto scaled_size = size * resolution_multiplier;
	Ref<Image> clip_image = Image::create_empty(scaled_size.x, scaled_size.y, false, Image::FORMAT_LA8);
    for (int y = 0; y < scaled_size.y; ++y) {
        for (int x = 0; x < scaled_size.x; ++x) {
            auto p0 = Vector2(x, y) / resolution_multiplier;
            auto p1 = p0 - Vector2(x + 0.5, y + 0.5);
            float distance1 = utils::sample_aa(clouds_sdf, p0, size);
            float distance2 = utils::sample_aa(clouds_sdf, p1, size);
            float distance = std::max(distance1, distance2);
			clip_image->set_pixel(x, y, Color(1, 0, 0, Math::smoothstep(min_threshold, max_threshold, distance)));
        }
    }

    return ImageTexture::create_from_image(clip_image);
}
