import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::collections::list;

struct Node {
    String name;
    uint parent;
    uint mesh;
    uint camera;
    uint skin;
    List(uint) children;
    Matrix4f matrix;
    Vec4f rotation;
    Vec3f scale;
    Vec3f translation;
    []usize weights;
    uint light;
};