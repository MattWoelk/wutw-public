uvec2 _decode_xy(float f) {
	uint v = floatBitsToUint(f);
	uint x = v >> 16u;
	uint y = v & 0xFFFFu;
	return uvec2(x, y);
}

float _dequantize(uint q, float min, float max) {
	return min + (float(q) / 65535.0) * (max - min);
}

vec2 unpack_vec2(float f) {
    uvec2 q = _decode_xy(f);
    return vec2(_dequantize(q.x, 0, 1), _dequantize(q.y, 0, 1));
}
