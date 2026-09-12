/////////////  PRIMITIVES  /////////////

// See: https://iquilezles.org/articles/distfunctions2d/

float sdf_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

float sdf_circle(vec2 p, float r) {
	return length(p) - r;
}

float sdf_ellipse(in vec2 p, in vec2 ab) {
	if (ab.x == ab.y) return sdf_circle(p, ab.x);
	p = abs(p); if( p.x > p.y ) {p=p.yx;ab=ab.yx;}
	float l = ab.y*ab.y - ab.x*ab.x;
	float m = ab.x*p.x/l;      float m2 = m*m;
	float n = ab.y*p.y/l;      float n2 = n*n;
	float c = (m2+n2-1.0)/3.0; float c3 = c*c*c;
	float q = c3 + m2*n2*2.0;
	float d = c3 + m2*n2;
	float g = m + m*n2;
	float co;
	if( d<0.0 )
	{
		float h = acos(q/c3)/3.0;
		float s = cos(h);
		float t = sin(h)*sqrt(3.0);
		float rx = sqrt( -c*(s + t + 2.0) + m2 );
		float ry = sqrt( -c*(s - t + 2.0) + m2 );
		co = (ry+sign(l)*rx+abs(g)/(rx*ry)- m)/2.0;
	}
	else
	{
		float h = 2.0*m*n*sqrt( d );
		float s = sign(q+h)*pow(abs(q+h), 1.0/3.0);
		float u = sign(q-h)*pow(abs(q-h), 1.0/3.0);
		float rx = -s - u - c*4.0 + 2.0*m2;
		float ry = (s - u)*sqrt(3.0);
		float rm = sqrt( rx*rx + ry*ry );
		co = (ry/sqrt(rm-rx)+2.0*g/rm-m)/2.0;
	}
	vec2 r = ab * vec2(co, sqrt(1.0-co*co));
	return length(r-p) * sign(p.y-r.y);
}

float sdf_line(in vec2 p, in vec2 a, in vec2 b) {
    vec2 pa = p - a;
	vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba,ba), 0.0, 1.0);
    return length(pa - ba * h);
}

float sdf_triangle(in vec2 p, in vec2 p0, in vec2 p1, in vec2 p2) {
	vec2 e0 = p1-p0, e1 = p2-p1, e2 = p0-p2;
	vec2 v0 = p -p0, v1 = p -p1, v2 = p -p2;
	vec2 pq0 = v0 - e0*clamp( dot(v0,e0)/dot(e0,e0), 0.0, 1.0 );
	vec2 pq1 = v1 - e1*clamp( dot(v1,e1)/dot(e1,e1), 0.0, 1.0 );
	vec2 pq2 = v2 - e2*clamp( dot(v2,e2)/dot(e2,e2), 0.0, 1.0 );
	float s = sign( e0.x*e2.y - e0.y*e2.x );
	vec2 d = min(min(vec2(dot(pq0,pq0), s*(v0.x*e0.y-v0.y*e0.x)),
	                 vec2(dot(pq1,pq1), s*(v1.x*e1.y-v1.y*e1.x))),
	                 vec2(dot(pq2,pq2), s*(v2.x*e2.y-v2.y*e2.x)));
	return -sqrt(d.x)*sign(d.y);
}

float sdf_star(vec2 p, float r, int n, float w) {
    float m = float(n) + w * (2.0 - float(n));

    float an = PI / float(n);
    float en = PI / m;
    vec2 racs = r * vec2(cos(an), sin(an));
    vec2 ecs = vec2(cos(en), sin(en)); // ecs=vec2(0,1) and simplify, for regular polygon,

    // symmetry (optional)
    p.x = abs(p.x);

    // reduce to first sector
    float bn = mod(atan(p.x, p.y), 2.0 * an) - an;
    p = length(p) * vec2(cos(bn), abs(sin(bn)));

    // line sdf
    p -= racs;
    p += ecs * clamp(-dot(p, ecs), 0.0, racs.y / ecs.y);
    return length(p) * sign(p.x);
}

/////////////  OPERATIONS  /////////////

vec2 translate(vec2 samplePosition, vec2 offset) {
    return samplePosition - offset;
}

// quadratic polynomial
float union( float a, float b)
{
    return min(a, b);
}

// quadratic polynomial
float smooth_union(float d1, float d2, float k)
{
    float h = clamp( 0.5 + 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) - k*h*(1.0-h);
}

float subtract(float d1, float d2)
{
    return max(-d2,d1);
}

float smooth_subtract(float d2, float d1, float k)
{
    float h = clamp( 0.5 - 0.5*(d2+d1)/k, 0.0, 1.0 );
    return mix( d2, -d1, h ) + k*h*(1.0-h);
}

float intersect(float d1, float d2)
{
    return max(d1,d2);
}

float smooth_intersect( float d1, float d2, float k )
{
    float h = clamp( 0.5 - 0.5*(d2-d1)/k, 0.0, 1.0 );
    return mix( d2, d1, h ) + k*h*(1.0-h);
}

float xor(float d1, float d2)
{
    return max(min(d1,d2),-max(d1,d2));
}
