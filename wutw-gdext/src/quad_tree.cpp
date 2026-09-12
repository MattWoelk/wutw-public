#include "quad_tree.h"

#include <vector>
#include <memory>
#include <algorithm>
#include <cmath>

#include <godot_cpp/core/class_db.hpp>
#include <functional>

using namespace godot;

void QuadTree::initialize(const Rect2& boundary, int capacity)
{
    root = std::make_unique<QuadTreeNode>(boundary, capacity);
}

void QuadTree::clear()
{
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);
    root = std::make_unique<QuadTreeNode>(root->boundary, root->capacity);
}

bool QuadTree::is_initialized() const
{
    return root != nullptr;
}

Rect2 QuadTree::get_boundary() const
{
    ERR_FAIL_COND_V_EDMSG(!root, {}, "QuadTree must be initialize()d before being used.");
    return root->boundary;
}

void QuadTree::add_circle(Variant object, Vector2 location, float radius, bool blocking) {
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);
    root->insert({ object, blocking, QuadTreeNode::CircleData{ location, radius } });
}

void QuadTree::add_rect(Variant object, Rect2 rect, bool blocking) {
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);
    root->insert({ object, blocking, QuadTreeNode::RectData{ rect } });
}

void QuadTree::add_line(Variant object, Vector2 p1, Vector2 p2, bool blocking) {
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);
    root->insert({ object, blocking, QuadTreeNode::LineData{ p1, p2 } });
}

void QuadTree::add_triangle(Variant object, Vector2 a, Vector2 b, Vector2 c, bool blocking) {
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);
    root->insert({ object, blocking, QuadTreeNode::TriangleData{ a, b, c } });
}

void QuadTree::remove(Variant object)
{
    ERR_FAIL_COND_EDMSG(!root, "QuadTree must be initialize()d before being used.");
    std::unique_lock<std::shared_mutex> lock(mutex);

    // Does not trim the tree. Just removes entries matching the object.
    std::function<void(std::unique_ptr<QuadTreeNode>&)> remove_recursive = [&](std::unique_ptr<QuadTreeNode>& node) -> void {
        auto& entries = node->entries;
        entries.erase(
            std::remove_if(entries.begin(), entries.end(), [&](const auto& e) { return e.object == object; }),
            entries.end()
        );
        if (node->divided) {
            for (auto& child : node->children) {
                remove_recursive(child);
            }
        }
    };

    remove_recursive(root);
}

Array QuadTree::query_circle(Vector2 location, float radius, bool must_be_blocking)
{
    ERR_FAIL_COND_V_EDMSG(!root, {}, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    std::vector<const QuadTreeNode::Entry*> found;
    root->query(QuadTreeNode::CircleData{ location, radius }, must_be_blocking, found);
    return convert_results(found);
}

Array QuadTree::query_rect(Rect2 rect, bool must_be_blocking)
{
    ERR_FAIL_COND_V_EDMSG(!root, {}, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    std::vector<const QuadTreeNode::Entry*> found;
    root->query(QuadTreeNode::RectData{ rect }, must_be_blocking, found);
    return convert_results(found);
}

Array QuadTree::query_line(Vector2 p1, Vector2 p2, bool must_be_blocking)
{
    ERR_FAIL_COND_V_EDMSG(!root, {}, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    std::vector<const QuadTreeNode::Entry*> found;
    root->query(QuadTreeNode::LineData{ p1, p2 }, must_be_blocking, found);
    return convert_results(found);
}

Array QuadTree::query_triangle(Vector2 a, Vector2 b, Vector2 c, bool must_be_blocking) {
    ERR_FAIL_COND_V_EDMSG(!root, {}, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    std::vector<const QuadTreeNode::Entry*> found;
    root->query(QuadTreeNode::TriangleData{ a, b, c }, must_be_blocking, found);
    return convert_results(found);
}

bool QuadTree::intersects_circle(Vector2 location, float radius, bool must_be_blocking) {
    ERR_FAIL_COND_V_EDMSG(!root, false, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    return root->query_any(QuadTreeNode::CircleData{ location, radius }, must_be_blocking);
}

bool QuadTree::intersects_rect(Rect2 rect, bool must_be_blocking)
{
    ERR_FAIL_COND_V_EDMSG(!root, false, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    return root->query_any(QuadTreeNode::RectData{ rect }, must_be_blocking);
}

bool QuadTree::intersects_line(Vector2 p1, Vector2 p2, bool must_be_blocking)
{
    ERR_FAIL_COND_V_EDMSG(!root, false, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    return root->query_any(QuadTreeNode::LineData{ p1, p2 }, must_be_blocking);;
}

bool QuadTree::intersects_triangle(Vector2 a, Vector2 b, Vector2 c, bool must_be_blocking) {
    ERR_FAIL_COND_V_EDMSG(!root, false, "QuadTree must be initialize()d before being used.");
    std::shared_lock<std::shared_mutex> lock(mutex);
    return root->query_any(QuadTreeNode::TriangleData{ a, b, c }, must_be_blocking);
}

void QuadTree::_bind_methods()
{
    ClassDB::bind_method(D_METHOD("initialize", "boundary", "capacity"), &QuadTree::initialize, DEFVAL(4));
    ClassDB::bind_method(D_METHOD("clear"), &QuadTree::clear);

    ClassDB::bind_method(D_METHOD("add_circle", "object", "center", "radius", "blocking"), &QuadTree::add_circle);
    ClassDB::bind_method(D_METHOD("add_rect", "object", "rect", "blocking"), &QuadTree::add_rect);
    ClassDB::bind_method(D_METHOD("add_line", "object", "a", "b", "blocking"), &QuadTree::add_line);
    ClassDB::bind_method(D_METHOD("add_triangle", "object", "a", "b", "c", "blocking"), &QuadTree::add_triangle);
    
    ClassDB::bind_method(D_METHOD("remove", "object"), &QuadTree::remove);
    
    ClassDB::bind_method(D_METHOD("query_circle", "location", "radius", "must_be_blocking"), &QuadTree::query_circle);
    ClassDB::bind_method(D_METHOD("query_rect", "rect", "must_be_blocking"), &QuadTree::query_rect);
    ClassDB::bind_method(D_METHOD("query_line", "a", "b", "must_be_blocking"), &QuadTree::query_line);
    ClassDB::bind_method(D_METHOD("query_triangle", "a", "b", "c", "must_be_blocking"), &QuadTree::query_triangle);

    ClassDB::bind_method(D_METHOD("intersects_circle", "location", "radius", "must_be_blocking"), &QuadTree::intersects_circle);
    ClassDB::bind_method(D_METHOD("intersects_rect", "rect", "must_be_blocking"), &QuadTree::intersects_rect);
    ClassDB::bind_method(D_METHOD("intersects_line", "a", "b", "must_be_blocking"), &QuadTree::intersects_line);
    ClassDB::bind_method(D_METHOD("intersects_triangle", "a", "b", "c", "must_be_blocking"), &QuadTree::intersects_triangle);
}

Array QuadTree::convert_results(const std::vector<const QuadTreeNode::Entry*>& found)
{
    Dictionary results;
    for (auto e : found) {
        results[e->object] = true;
    }
    return results.keys();
}

// QuadTreeNode

void QuadTreeNode::subdivide() {
    float x = boundary.position.x;
    float y = boundary.position.y;
    float hw = boundary.size.x / 2.0f;
    float hh = boundary.size.y / 2.0f;
    children[0] = std::make_unique<QuadTreeNode>(Rect2{ x, y, hw, hh }, capacity);
    children[1] = std::make_unique<QuadTreeNode>(Rect2{ x + hw, y, hw, hh }, capacity);
    children[2] = std::make_unique<QuadTreeNode>(Rect2{ x, y + hh, hw, hh }, capacity);
    children[3] = std::make_unique<QuadTreeNode>(Rect2{ x + hw, y + hh, hw, hh }, capacity);
    ERR_FAIL_COND_EDMSG(hw <= 0 || hh <= 0, "Invalid subdivision: zero or negative size.");
    divided = true;
}

bool QuadTreeNode::insert(const Entry& entry) {
    // Reject if not in this node's boundary.
    bool overlap = std::visit([&](auto&& shape) {
        return intersects_shape(boundary, shape);
    }, entry.shape);
    if (!overlap) return false;

    // If space remains and not divided, store here.
    if (entries.size() < (size_t)capacity) {
        entries.push_back(entry);
        return true;
    }

    // Otherwise, subdivide if necessary and delegate.
    if (!divided) subdivide();
    bool inserted = false;
    for (auto& c : children) {
        inserted |= c->insert(entry);
    }

    ERR_FAIL_COND_V_EDMSG(!inserted, false, "Invalid subdivision: zero or negative size.");
    return true;
}

void QuadTreeNode::query(const ShapeData& query, bool must_be_blocking, std::vector<const Entry*>& found) const {
    std::visit([&](auto&& Q) {
        // If this node's region does not intersect the query shape, skip.
        if (!intersects_shape(boundary, Q)) return;

        // Check entries in this node.
        for (auto& e : entries) {
            if (must_be_blocking && !e.blocking) continue;
            bool hit = std::visit([&](auto&& S) {
                return intersects_query(S, Q);
            }, e.shape);
            if (hit) found.push_back(&e);
        }

        // Recurse into children.
        if (divided) {
            for (auto& c : children) {
                c->query(query, must_be_blocking, found);
            }
        }
    }, query);
}

bool QuadTreeNode::query_any(const ShapeData& query, bool must_be_blocking) const
{
    return std::visit([&](auto&& Q) -> bool {
        // If this node's boundary doesn't overlap Q at all, skip entirely.
        if (!intersects_shape(boundary, Q)) {
            return false;
        }

        // Check every entry in this node, and bail out on first hit.
        for (auto& e : entries) {
            if (must_be_blocking && !e.blocking) continue;
            bool hit = std::visit([&](auto&& S) {
                return intersects_query(S, Q);
            }, e.shape);
            if (hit) return true;
        }

        // Recurse into children.
        if (divided) {
            for (auto& c : children) {
                if (c->query_any(query, must_be_blocking)) return true;
            }
        }

        return false;
    }, query);
}

bool QuadTreeNode::intersects_shape(const Rect2& rect, const CircleData& c) {
    float cx = std::clamp(c.center.x, rect.position.x, rect.position.x + rect.size.x);
    float cy = std::clamp(c.center.y, rect.position.y, rect.position.y + rect.size.y);
    float dx = c.center.x - cx;
    float dy = c.center.y - cy;
    return (dx * dx + dy * dy) <= (c.radius * c.radius);
}

bool QuadTreeNode::intersects_shape(const Rect2& rect, const RectData& r) {
    return rect.intersects(r.rect);
}

bool QuadTreeNode::intersects_shape(const Rect2& rect, const LineData& l) {
    if (rect.has_point(l.a) || rect.has_point(l.b)) return true;
    Vector2 p = rect.position, s = rect.size;
    std::pair<Vector2, Vector2> edges[4] = {
        { p,                       Vector2(p.x + s.x, p.y)      },
        { p,                       Vector2(p.x,       p.y + s.y)},
        { Vector2(p.x, p.y + s.y), p + s    },
        { Vector2(p.x + s.x, p.y), p + s    }
    };
    for (auto& e : edges) {
        if (segments_intersect(l.a, l.b, e.first, e.second)) return true;
    }
    return false;
}

bool QuadTreeNode::intersects_shape(const Rect2& rect, const TriangleData& t)
{
    // If any triangle vertex is inside the rect
    if (rect.has_point(t.a) || rect.has_point(t.b) || rect.has_point(t.c)) return true;

    // If any rect corner is inside triangle.
    Vector2 r1 = rect.position;
    Vector2 r2 = rect.position + Vector2(rect.size.x, 0);
    Vector2 r3 = rect.position + rect.size;
    Vector2 r4 = rect.position + Vector2(0, rect.size.y);
    if (point_in_triangle(r1, t.a, t.b, t.c) ||
        point_in_triangle(r2, t.a, t.b, t.c) ||
        point_in_triangle(r3, t.a, t.b, t.c) ||
        point_in_triangle(r4, t.a, t.b, t.c)) return true;

    // If any triangle edge crosses any rect edge.
    std::pair<Vector2, Vector2> tri_edges[3] = {
        {t.a, t.b}, {t.b, t.c}, {t.c, t.a}
    };
    std::pair<Vector2, Vector2> rect_edges[4] = {
        { r1, r2 }, { r2, r3 }, { r3, r4 }, { r4, r1 }
    };
    for (auto& te : tri_edges) {
        for (auto& re : rect_edges) {
            if (segments_intersect(te.first, te.second, re.first, re.second)) {
                return true;
            }
        }
    }

    return false;
}

bool QuadTreeNode::intersects_query(const CircleData& s, const CircleData& q) {
    float dx = s.center.x - q.center.x;
    float dy = s.center.y - q.center.y;
    float rsum = s.radius + q.radius;
    return (dx * dx + dy * dy) <= (rsum * rsum);
}

bool QuadTreeNode::intersects_query(const RectData& s, const CircleData& q) {
    return intersects_shape(s.rect, q);
}

bool QuadTreeNode::intersects_query(const LineData& s, const CircleData& q) {
    Vector2 d = s.b - s.a;
    float len2 = d.length_squared();
    if (len2 == 0) {
        return q.center.distance_squared_to(s.a) <= q.radius * q.radius;
    }
    float t = ((q.center - s.a).dot(d)) / len2;
    t = Math::clamp(t, 0.0f, 1.0f);
    Vector2 closest = s.a + d * t;
    return q.center.distance_squared_to(closest) <= q.radius * q.radius;
}

bool QuadTreeNode::intersects_query(const TriangleData& s, const CircleData& q)
{
    return intersects_query(q, s);
}

bool QuadTreeNode::intersects_query(const CircleData& s, const RectData& q) {
    return intersects_shape(q.rect, s);
}

bool QuadTreeNode::intersects_query(const RectData& s, const RectData& q) {
    return intersects_shape(q.rect, s);
}

bool QuadTreeNode::intersects_query(const LineData& s, const RectData& q) {
    return intersects_shape(q.rect, s);
}

bool QuadTreeNode::intersects_query(const TriangleData& s, const RectData& q)
{
    return intersects_query(q, s);
}

bool QuadTreeNode::intersects_query(const CircleData& s, const LineData& q) {
    return intersects_query(q, s);
}

bool QuadTreeNode::intersects_query(const RectData& s, const LineData& q) {
    return intersects_shape(s.rect, q);
}

bool QuadTreeNode::intersects_query(const LineData& s, const LineData& q) {
    return segments_intersect(s.a, s.b, q.a, q.b);
}

bool QuadTreeNode::intersects_query(const TriangleData& s, const LineData& q)
{
    return intersects_query(q, s);
}

bool QuadTreeNode::intersects_query(const CircleData& s, const TriangleData& q) {
    // Circle/triangle: vertex in circle, edge crosses circle, or circle center in triangle
    if ((s.center.distance_to(q.a) <= s.radius) ||
        (s.center.distance_to(q.b) <= s.radius) ||
        (s.center.distance_to(q.c) <= s.radius)) return true;

    // If any triangle edge intersects circle.
    std::pair<Vector2, Vector2> edges[3] = {
        {q.a, q.b}, {q.b, q.c}, {q.c, q.a}
    };
    for (auto& e : edges) {
        // Line segment to circle intersection.
        LineData l{ e.first, e.second };
        if (intersects_query(l, s)) return true;
    }

    // If circle center is inside triangle.
    if (point_in_triangle(s.center, q.a, q.b, q.c)) return true;

    return false;
}

bool QuadTreeNode::intersects_query(const RectData& s, const TriangleData& q)
{
    return intersects_shape(s.rect, q);
}

bool QuadTreeNode::intersects_query(const LineData& s, const TriangleData& q)
{
    // If line segment intersects any triangle edge
    std::pair<Vector2, Vector2> edges[3] = {
        {q.a, q.b}, {q.b, q.c}, {q.c, q.a}
    };
    for (auto& e : edges) {
        if (segments_intersect(s.a, s.b, e.first, e.second)) {
            return true;
        }
    }
    // Or if line is entirely within triangle
    if (point_in_triangle(s.a, q.a, q.b, q.c) || point_in_triangle(s.b, q.a, q.b, q.c)) {
        return true;
    }
    return false;
}

bool QuadTreeNode::intersects_query(const TriangleData& s, const TriangleData& q) {
    // If any triangle edge intersects any other triangle edge, or a vertex is inside the other triangle.
    std::pair<Vector2, Vector2> e1[3] = { {s.a, s.b}, {s.b, s.c}, {s.c, s.a} };
    std::pair<Vector2, Vector2> e2[3] = { {q.a, q.b}, {q.b, q.c}, {q.c, q.a} };
    for (auto& se : e1) {
        for (auto& qe : e2) {
            if (segments_intersect(se.first, se.second, qe.first, qe.second)) {
                return true;
            }
        }
    }
    // Vertex inclusion.
    if (point_in_triangle(s.a, q.a, q.b, q.c) ||
        point_in_triangle(s.b, q.a, q.b, q.c) ||
        point_in_triangle(s.c, q.a, q.b, q.c)) return true;
    if (point_in_triangle(q.a, s.a, s.b, s.c) ||
        point_in_triangle(q.b, s.a, s.b, s.c) ||
        point_in_triangle(q.c, s.a, s.b, s.c)) return true;
    return false;
}

int QuadTreeNode::orient(const Vector2& a, const Vector2& b, const Vector2& c) {
    // Returns 0 if collinear, 1 if clockwise, 2 if counterclockwise.
    float v = (b.y - a.y) * (c.x - b.x)
            - (b.x - a.x) * (c.y - b.y);
    if (Math::is_equal_approx(v, 0.0f)) return 0;
    return (v > 0.0f) ? 1 : 2;
}

bool QuadTreeNode::on_segment(const Vector2& a, const Vector2& b, const Vector2& c) {
    // Is b within the AABB of a-c?
    return b.x >= std::min(a.x, c.x) && b.x <= std::max(a.x, c.x)
        && b.y >= std::min(a.y, c.y) && b.y <= std::max(a.y, c.y);
}

bool QuadTreeNode::segments_intersect(const Vector2& p1, const Vector2& p2,
                                      const Vector2& p3, const Vector2& p4) {
    int o1 = orient(p1, p2, p3);
    int o2 = orient(p1, p2, p4);
    int o3 = orient(p3, p4, p1);
    int o4 = orient(p3, p4, p2);

    // General case.
    if (o1 != o2 && o3 != o4) return true;

    // Special collinear cases.
    if (o1 == 0 && on_segment(p1, p3, p2)) return true;
    if (o2 == 0 && on_segment(p1, p4, p2)) return true;
    if (o3 == 0 && on_segment(p3, p1, p4)) return true;
    if (o4 == 0 && on_segment(p3, p2, p4)) return true;

    return false;
}

bool QuadTreeNode::point_in_triangle(const Vector2& p, const Vector2& a, const Vector2& b, const Vector2& c) {
    float s = a.y * c.x - a.x * c.y + (c.y - a.y) * p.x + (a.x - c.x) * p.y;
    float t = a.x * b.y - a.y * b.x + (a.y - b.y) * p.x + (b.x - a.x) * p.y;
    if ((s < 0) != (t < 0))
        return false;
    float A = -b.y * c.x + a.y * (c.x - b.x) + a.x * (b.y - c.y) + b.x * c.y;
    if (A < 0.0)
        return (s <= 0 && s + t >= A);
    return (s >= 0 && s + t <= A);
}
