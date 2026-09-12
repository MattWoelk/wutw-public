#pragma once

#include <memory>
#include <shared_mutex>
#include <mutex>

#include <godot_cpp/classes/ref.hpp>
#include <variant>

using namespace godot;

struct QuadTreeNode {
    struct CircleData { Vector2 center; float radius; };
    struct RectData { Rect2 rect; };
    struct LineData { Vector2 a, b; };
    struct TriangleData { Vector2 a, b, c; };
    using ShapeData = std::variant<CircleData, RectData, LineData, TriangleData>;
    struct Entry {
        Variant object;
        bool blocking;
        ShapeData shape;
    };

    Rect2 boundary;
    int capacity;
    std::vector<Entry> entries;
    std::unique_ptr<QuadTreeNode> children[4];
    bool divided = false;

    QuadTreeNode(const Rect2& boundary, int capacity) : boundary(boundary), capacity(capacity) {}

    void subdivide();
    bool insert(const Entry& entry);
    void query(const ShapeData& query, bool must_be_blocking, std::vector<const Entry*>& found) const;
    bool query_any(const ShapeData& query, bool must_be_blocking) const;

    // Does this node intersect a shape?
    static bool intersects_shape(const Rect2& rect, const CircleData& c);
    static bool intersects_shape(const Rect2& rect, const RectData& r);
    static bool intersects_shape(const Rect2& rect, const LineData& l);
    static bool intersects_shape(const Rect2& rect, const TriangleData& t);

    // Does this query shape intersect a stored shape?
    static bool intersects_query(const CircleData& s, const CircleData& q);
    static bool intersects_query(const RectData& s, const CircleData& q);
    static bool intersects_query(const LineData& s, const CircleData& q);
    static bool intersects_query(const TriangleData& s, const CircleData& q);

    static bool intersects_query(const CircleData& s, const RectData& q);
    static bool intersects_query(const RectData& s, const RectData& q);
    static bool intersects_query(const LineData& s, const RectData& q);
    static bool intersects_query(const TriangleData& s, const RectData& q);

    static bool intersects_query(const CircleData& s, const LineData& q);
    static bool intersects_query(const RectData& s, const LineData& q);
    static bool intersects_query(const LineData& s, const LineData& q);
    static bool intersects_query(const TriangleData& s, const LineData& q);

    static bool intersects_query(const CircleData& s, const TriangleData& q);
    static bool intersects_query(const RectData& s, const TriangleData& q);
    static bool intersects_query(const LineData& s, const TriangleData& q);
    static bool intersects_query(const TriangleData& s, const TriangleData& q);

    // Helpers for segment intersection.
    static int orient(const Vector2& a, const Vector2& b, const Vector2& c);
    static bool on_segment(const Vector2& a, const Vector2& b, const Vector2& c);
    static bool segments_intersect(const Vector2& p1, const Vector2& p2, const Vector2& p3, const Vector2& p4);
    static bool point_in_triangle(const Vector2& p, const Vector2& a, const Vector2& b, const Vector2& c);
};

class QuadTree : public RefCounted
{
    GDCLASS(QuadTree, RefCounted);

public:
    QuadTree() {}
    ~QuadTree() {}

    void initialize(const Rect2& boundary, int capacity = 4);
    void clear();
    bool is_initialized() const;
    Rect2 get_boundary() const;

    void add_circle(Variant object, Vector2 center, float radius, bool blocking);
    void add_rect(Variant object, Rect2 rect, bool blocking);
    void add_line(Variant object, Vector2 a, Vector2 b, bool blocking);
    void add_triangle(Variant object, Vector2 a, Vector2 b, Vector2 c, bool blocking);

    void remove(Variant object);

    Array query_circle(Vector2 location, float radius, bool must_be_blocking);
    Array query_rect(Rect2 rect, bool must_be_blocking);
    Array query_line(Vector2 p1, Vector2 p2, bool must_be_blocking);
    Array query_triangle(Vector2 a, Vector2 b, Vector2 c, bool must_be_blocking);

    bool intersects_circle(Vector2 location, float radius, bool must_be_blocking);
    bool intersects_rect(Rect2 rect, bool must_be_blocking);
    bool intersects_line(Vector2 p1, Vector2 p2, bool must_be_blocking);
    bool intersects_triangle(Vector2 a, Vector2 b, Vector2 c, bool must_be_blocking);

protected:
    static void _bind_methods();

private:
    std::unique_ptr<QuadTreeNode> root;
    mutable std::shared_mutex mutex;

    static Array convert_results(const std::vector<const QuadTreeNode::Entry*>& found);
};
