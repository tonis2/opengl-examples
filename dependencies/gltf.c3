import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::core::mem;
import std::collections::list;
import std::encoding::json;
import base64;

typedef PrimitiveList = List<Primitive>;
typedef NodeList = List<Node>;
typedef SceneList= List<Scene>;
typedef MeshList = List<Mesh>;
typedef IndexList = List<uint>;
typedef BufferList = List<Buffer>;
typedef AccessorList = List<Accessor>;


enum Targets {
    ARRAY_BUFFER,
    ELEMENT_ARRAY_BUFFER
}

enum AccessorType {
    SCALAR,
    VEC2,
    VEC3,
    VEC4,
    MAT2,
    MAT3,
    MAT4
}

enum Mode {
    POINTS,
    LINES,
    LINE_LOOP,
    LINE_STRIPE,
    TRIANGLES,
    TRIANGLE_STRIP,
    TRIANGLE_FAN
}

enum DataType {
    I8,
    U8,
    I16,
    U16,
    U32,
    F32,
}

struct Gltf {
    Object* json;
    String name;
    NodeList nodes;
    SceneList scenes;
    MeshList meshes;
    BufferList buffers;
    AccessorList accessors;
}

struct Scene {
    String name;
    IndexList nodes;
}

struct Node {
    String name;
    uint mesh;
    Vec4f rotation;
    Vec3f scale;
    Vec3f translation;
}

struct Primitive {
    uint indices;
    uint material;
    Mode mode;
    Object* attributes;
}

struct Accessor {
    uint bufferView;
    uint offset;
    uint stride;
    uint count;
    bool normalize;
    DataType data_type;
    AccessorType type;
}

struct Mesh {
    String name;
    PrimitiveList primitives;
}

struct Buffer {
    String data;
    uint size;
}

fault ParseError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    JSON_PARSE_FAILED
}    

fn Gltf! loadFile(String path) {
    File! file = file::open(path, "r");
    if (catch err = file)
    {
        case IoError.FILE_NOT_FOUND:
            return ParseError.FILE_NOT_FOUND!;
        default:
            return ParseError.FILE_NOT_READABLE!;
    }

    Gltf content;
    JsonParser json;
	json.init(file.as_stream());

	Object*! gltfJson = json.parse_any();

    if (catch err = gltfJson) {
        return ParseError.JSON_PARSE_FAILED!;
    } 

    // JSON data
    Object* nodes = gltfJson.get("nodes")?;
    Object* meshes = gltfJson.get("meshes")?;
    Object* bufferViews = gltfJson.get("bufferViews")?;
    Object* accessors = gltfJson.get("accessors")?;
    Object* buffers = gltfJson.get("buffers")?;
    Object* scenes = gltfJson.get("scenes")?;

    // Parse scenes
    foreach (scene : scenes.array) {
        Scene sceneItem;
        sceneItem.name = scene.get_string("name")?;
        foreach (node : scene.get("nodes")?.array) sceneItem.nodes.push((uint)node.f);
        content.scenes.push(sceneItem);
    }

    // Parse nodes
    foreach (node : nodes.array) {

        Object* node_json = nodes.get_at((ulong)node.f);
        Node nodeItem;
        nodeItem.name = node_json.get_string("name")?;

        // Parse node transforms
        Object*! rotation = node_json.get("rotation");
        Object*! scale = node_json.get("scale");
        Object*! translation = node_json.get("translation");
        Object*! mesh = node_json.get("mesh");

        if (try mesh) {
            nodeItem.mesh = (uint)mesh.f;
        }

        if (try rotation) {
            nodeItem.rotation = Vec4f {(float)rotation.get_at(0).f, (float)rotation.get_at(1).f, (float)rotation.get_at(2).f, (float)rotation.get_at(3).f};
        }

        if (try scale) {
            nodeItem.scale = Vec3f {(float)scale.get_at(0).f, (float)scale.get_at(1).f, (float)scale.get_at(2).f };
        }

        if (try translation) {
            nodeItem.translation = Vec3f {(float)translation.get_at(0).f, (float)translation.get_at(1).f, (float)translation.get_at(2).f };
        }

        content.nodes.push(nodeItem);
    }


    // Parse meshes
    foreach (mesh : meshes.array) {
        Mesh meshItem;
        meshItem.name = mesh.get_string("name")?;

        // Add all attributes
        foreach (primitive : mesh.get("primitives")?.array) {

            Primitive data;
            Object*! indices = primitive.get("indices");
            Object*! material = primitive.get("indices");
            Object*! attributes = primitive.get("attributes");

            if (try indices) {
                data.indices = (uint)indices.f;
            }

            if (try material) {
                data.material = (uint)material.f;
            }

            if (try attributes) {
                data.attributes = attributes;
            }

            meshItem.primitives.push(data);
        }
        content.meshes.push(meshItem);
    }

    // Parse accessors
    foreach (accessor : accessors.array) {
        Accessor data;

        Object*! dataType = accessor.get("componentType");
        Object*! objectType = accessor.get("type");
        Object*! bufferView = accessor.get("bufferView");
        Object* count = accessor.get("count")?;
        Object* offset = accessor.get("offset")?;
        Object* stride = accessor.get("stride")?;
        Object* normalize = accessor.get("normalize")?;

        data.stride = (uint)stride.f;
        data.count = (uint)count.f;
        data.offset = (uint)offset.f;
        data.normalize = normalize.b;

        if (try bufferView) {
            data.bufferView = (uint)bufferView.f;
        }

        if (try dataType && try objectType) {
            switch(dataType.f) {
                case 5120:
                    data.data_type = DataType.I8;
                case 5121:
                    data.data_type = DataType.U8;
                case 5122:
                    data.data_type = DataType.I16;
                case 5123:
                    data.data_type = DataType.U16;
                case 5125:
                    data.data_type = DataType.U32;
                case 5126:
                    data.data_type = DataType.F32;
            }


            if (mem::equals(objectType.s, "VEC2")) {
                data.type = AccessorType.VEC2;
            }
            if (mem::equals(objectType.s, "VEC3")) {
                data.type = AccessorType.VEC3;
            }
            if (mem::equals(objectType.s, "VEC4")) {
                data.type = AccessorType.VEC4;
            }
            if (mem::equals(objectType.s, "MAT2")) {
                data.type = AccessorType.MAT2;
            }
            if (mem::equals(objectType.s, "MAT3")) {
                data.type = AccessorType.MAT3;
            }
            if (mem::equals(objectType.s, "MAT4")) {
                data.type = AccessorType.MAT4;
            }   
        }

        content.accessors.push(data);
    }

    // Parse buffers
    foreach (buffer : buffers.array) {
        Object*! size = buffer.get("byteLength");
        Object*! data = buffer.get("uri");

        if (try size && try data) {
            content.buffers.push(Buffer {
                .data = data.s,
                .size = (uint)size.f
            });
        }
    }

    content.json = gltfJson;

    file.close()?;
    return content;
 
}

fn void Gltf.close(Gltf* self) {
    foreach (mesh : self.meshes) {
        mesh.primitives.free();
    }

    self.accessors.free();
    self.buffers.free();
    self.scenes.free();
    self.nodes.free();
    self.meshes.free();
    self.json.free();
}   
