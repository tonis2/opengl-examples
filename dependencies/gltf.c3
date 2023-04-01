import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::core::mem;
import std::collections::list;
import std::encoding::json;

typedef PrimitiveList = List<Primitive>;
typedef NodeList = List<Node>;
typedef SceneList= List<Scene>;
typedef MeshList = List<Mesh>;
typedef IndexList = List<uint>;
typedef BufferList = List<Buffer>;
typedef BufferViewList = List<BufferView>;
typedef AccessorList = List<Accessor>;

struct Gltf {
    Object* json;
    String name;
    NodeList nodes;
    SceneList scenes;
    MeshList meshes;
    BufferList buffers;
    BufferViewList bufferViews;
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

struct BufferView {
    uint buffer;
    uint byteLength;
    uint byteOffset;
    Targets target;     
}

struct Mesh {
    String name;
    PrimitiveList primitives;
}

struct Buffer {
    char* data;
    uint size;
}

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

fault ParseError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    JSON_PARSE_FAILED,
    NO_BUFFER_VIEW,
    NO_BUFFER
}    

fn Gltf! loadFile(String path) {

    File! file = file::open(path, "r");
    if (catch err = file)
    {
        if (err == IoError.FILE_NOT_FOUND) {
            return ParseError.FILE_NOT_FOUND!;
        }

        return ParseError.FILE_NOT_READABLE!;
    }

    Gltf content;
    JsonParser json;
	json.init(file.as_stream());
	Object*! gltfJson = json.parse_any();

    if (catch err = gltfJson) {
        return ParseError.JSON_PARSE_FAILED!;
    }

    content.json = gltfJson;

    // JSON data
    Object*! scenes = gltfJson.get("scenes");
    Object*! nodes = gltfJson.get("nodes");
    Object*! meshes = gltfJson.get("meshes");
    Object*! bufferViews = gltfJson.get("bufferViews");
    Object*! accessors = gltfJson.get("accessors");
    Object*! buffers = gltfJson.get("buffers");

    // Parse scenes
    if (try scenes) {
        foreach (scene : scenes.array) {
            Scene sceneItem;

            String! name = scene.get_string("name");
            Object*! sceneNodes = scene.get("nodes");

            if (try name) sceneItem.name = name;
            if (try sceneNodes) foreach (node : sceneNodes.array) sceneItem.nodes.push((uint)node.f);
 
            content.scenes.push(sceneItem);
        }
    }
 
    // Parse nodes
    if (try nodes) {
        foreach (node : nodes.array) {
            Node nodeItem;

            String! name = node.get_string("name");

            if (try name) nodeItem.name = name;

            // Parse node transforms
            Object*! rotation = node.get("rotation");
            Object*! scale = node.get("scale");
            Object*! translation = node.get("translation");
            Object*! mesh = node.get("mesh");

            if (try mesh) nodeItem.mesh = (uint)mesh.f;

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
    }


    // Parse meshes
    if (try meshes) {
        foreach (mesh : meshes.array) {
            Mesh meshItem;
            String! name = mesh.get_string("name");
            Object*! primitives = mesh.get("primitives");

            if (try name) meshItem.name = name;
            if (try primitives) {
                foreach (primitive : primitives.array) {
                    // Add all attributes
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
            }
            content.meshes.push(meshItem);
        }
    }

    // Parse accessors
    if (try accessors) {
        foreach (accessor : accessors.array) {
            Accessor data;

            Object*! dataType = accessor.get("componentType");
            Object*! objectType = accessor.get("type");
            Object*! bufferView = accessor.get("bufferView");
            Object*! count = accessor.get("count");
            Object*! offset = accessor.get("offset");
            Object*! stride = accessor.get("stride");
            Object*! normalize = accessor.get("normalize");

            if (try stride) data.stride = (uint)stride.f;
            if (try count) data.count = (uint)count.f;
            if (try offset) data.offset = (uint)offset.f;
            if (try normalize) data.normalize = normalize.b;
            if (try bufferView) data.bufferView = (uint)bufferView.f;

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
    }

    if (try bufferViews) {
        foreach (bufferView : bufferViews.array) {
            BufferView data;
            
            int! buffer = bufferView.get_int("buffer");
            int! byteLength = bufferView.get_int("byteLength");
            int! byteOffset = bufferView.get_int("byteOffset");
            int! target = bufferView.get_int("target");

            if (try buffer) data.buffer = buffer;
            if (try byteLength) data.byteLength = byteLength;
            if (try byteOffset) data.byteOffset = byteOffset;
            if (try target) {
                switch(target) {
                    case 34962: {
                        data.target = Targets.ARRAY_BUFFER;
                    }
                    case 34963: {
                        data.target = Targets.ELEMENT_ARRAY_BUFFER;
                    }
                }
            }
            content.bufferViews.push(data);
        }
    }

    // Parse buffers
    if (try buffers) { 
        foreach (buffer : buffers.array) {
            uint! size = buffer.get_int("byteLength");
            String! data = buffer.get_string("uri");

            if (try size && try data) {
                content.buffers.push(Buffer {
                    .data = data.split("base64,")[1],
                    .size = size
                });
            }
        }
    }

 

    file.close()?;
    return content;
 
}

fn void Gltf.close(Gltf* self) {
    foreach (mesh : self.meshes) {
        mesh.primitives.free();
    }

    self.accessors.free();
    self.bufferViews.free();
    self.buffers.free();
    self.scenes.free();
    self.nodes.free();
    self.meshes.free();
    self.json.free();
}   


macro uint Accessor.size(Accessor* self, uint size) {
    return self.count * size;
}

macro void! Gltf.@get_buffer(Gltf* self, Accessor accessor, list) {
    
    BufferView bufferView = self.bufferViews[accessor.bufferView];
    Buffer buffer = self.buffers[bufferView.buffer];

    uint datum = {| 
        switch(accessor.type) {
            case AccessorType.SCALAR: {
                return 1;
            }
            case AccessorType.VEC2: {
                return 2;
            }
            case AccessorType.VEC3: {
                return 3;
            }
            case AccessorType.VEC4: {
                return 4;
            }
            case AccessorType.MAT2: {
                return 4;
            }
            case AccessorType.MAT3: {
                return 9;
            }
            case AccessorType.MAT4: {
                return 16;
            }     
        };
        return 0;
    |}; 

    // Todo convert bytes to correct format
    for (uint i = 0; i < accessor.count; i++) {
        list.push((buffer.data + bufferView.byteOffset)[i*(i+1) + i]);
    }
}