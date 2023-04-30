import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::core::mem;
import std::collections::list;
import std::encoding::json;

import base64;

typedef PrimitiveList = List<Object*>;
typedef NodeList = List<Node>;
typedef SceneList= List<Scene>;
typedef MeshList = List<GltfMesh>;
typedef IndexList = List<uint>;
typedef BufferList = List<GltfBuffer>;
typedef BufferViewList = List<BufferView>;
typedef AccessorList = List<Accessor>;
typedef CameraList = List<Camera>;

enum Targets {
    ARRAY_BUFFER,
    ELEMENT_ARRAY_BUFFER
}

enum BufferType {
    IMAGE_JPEG,
    IMAGE_PNG,
    IMAGE_BMP,
    IMAGE_GIF,
    STREAM
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
    LINE_STRIP,
    TRIANGLES,
    TRIANGLE_STRIP,
    TRIANGLE_FAN
}

enum DataType {
    ICHAR,
    CHAR,
    SHORT,
    USHORT,
    UINT,
    FLOAT,
}

fault ParseError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    JSON_PARSE_FAILED,
    NO_BUFFER_VIEW,
    NO_BUFFER,
    BROKEN_BUFFER,
    KEY_NOT_FOUND
}

fault GltfError
{
    KEY_NOT_FOUND
}

struct Gltf {
    Object* json;
    String name;
    NodeList nodes;
    SceneList scenes;
    MeshList meshes;
    BufferList buffers;
    BufferViewList bufferViews;
    AccessorList accessors;
    CameraList cameras;
}

struct Scene {
    String name;
    IndexList nodes;
}

struct Node {
    String name;
    int mesh;
    int camera;
    Vec4f rotation;
    Vec3f scale;
    Vec3f translation;
}

struct Camera {
    String name;
    union
    {
        struct perspective {
            float aspectRatio;
            float yfov;
            float zfar;
            float znear;
        }
    }
}

struct Accessor {
    uint bufferView;
    uint offset;
    uint stride;
    uint count;
    bool normalize;
    Mode mode;
    DataType data_type;
    AccessorType type;
}

struct GltfMesh {
    String name;
    PrimitiveList primitives;
}

struct BufferView {
    uint buffer;
    uint byteLength;
    uint offset;
    uint stride;
    Targets target;     
}

struct GltfBuffer {
    char* data;
    uint size;
    BufferType data_type;
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
    Object*! cameras = gltfJson.get("cameras");

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
            nodeItem.mesh = -1;
            nodeItem.camera = -1;

            String! name = node.get_string("name");
            if (try name) nodeItem.name = name; 

            // Parse node transforms
            Object*! rotation = node.get("rotation");
            Object*! scale = node.get("scale");
            Object*! translation = node.get("translation");

            int! mesh = node.get_int("mesh");
            int! camera = node.get_int("camera");

            if (try mesh) nodeItem.mesh = mesh;
            if (try camera) nodeItem.camera = camera;
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
            GltfMesh meshItem;
            String! name = mesh.get_string("name");
            Object*! primitives = mesh.get("primitives");

            if (try name) meshItem.name = name;
            if (try primitives) {
                foreach (primitive : primitives.array) {
                    meshItem.primitives.push(primitive);
                }
            }
            content.meshes.push(meshItem);
        }
    }

    if (try bufferViews) {
        foreach (bufferView : bufferViews.array) {
            BufferView data;
            
            uint! buffer = bufferView.get_int("buffer");
            uint! byteLength = bufferView.get_int("byteLength");
            uint! offset = bufferView.get_int("byteOffset");
            uint! target = bufferView.get_int("target");

            if (try buffer) data.buffer = buffer;
            if (try byteLength) data.byteLength = byteLength;
            if (try offset) data.offset = offset;
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
            Object*! mode = accessor.get("mode");

            if (try count) data.count = (uint)count.f;
            if (try offset) data.offset = (uint)offset.f;
            if (try normalize) data.normalize = normalize.b;
            if (try stride) data.stride = (uint)stride.f;
            if (try bufferView) data.bufferView = (uint)bufferView.f;
            if (try mode) {
                switch((uint)mode.f) {
                    case 0:
                        data.mode = Mode.POINTS;
                    case 1:
                        data.mode = Mode.LINES;
                    case 2:
                        data.mode = Mode.LINE_LOOP;
                    case 3:
                        data.mode = Mode.LINE_STRIP;
                    case 4:
                        data.mode = Mode.TRIANGLES;
                    case 5:
                        data.mode = Mode.TRIANGLE_STRIP;
                    case 6:
                        data.mode = Mode.TRIANGLE_FAN;    
                }
            }


            if (try dataType && try objectType) {
                switch(dataType.f) {
                    case 5120:
                        data.data_type = DataType.ICHAR;
                    case 5121:
                        data.data_type = DataType.CHAR;
                    case 5122:
                        data.data_type = DataType.SHORT;
                    case 5123:
                        data.data_type = DataType.USHORT;
                    case 5125:
                        data.data_type = DataType.UINT;
                    case 5126:
                        data.data_type = DataType.FLOAT;
                }

                if (mem::equals(objectType.s, "SCALAR")) {
                    data.type = AccessorType.SCALAR;
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

  

    if (try buffers) { 
        foreach (buffer : buffers.array) {
            uint! size = buffer.get_int("byteLength");
            String! data = buffer.get_string("uri");
            BufferType bufferType;

            if (try size && try data) {          
                String[] bufferHeader = data.split(",");
                defer mem::free(bufferHeader);
                char* parsedBuffer = mem::malloc(char, size);

                // Parse buffer from base64 to bytes
                if (mem::equals(bufferHeader[0], "data:application/octet-stream;base64")) {
                    if (catch err = base64::decode(bufferHeader[1], parsedBuffer)) {
                         io::printf("failed parsing buffer %s \n", bufferHeader[0]);
                         return ParseError.BROKEN_BUFFER!;
                    };
                    bufferType = BufferType.STREAM;
                }

                content.buffers.push(GltfBuffer {
                    .data = parsedBuffer,
                    .size = size,
                    .data_type = bufferType
                });
            }
        }
    }

    if (try cameras) {
        foreach (camera : cameras.array) {
            Camera data;
            String! cameraType = camera.get_string("type");
            String! name = camera.get_string("name");

            if (try name) content.name = name;
            if (try cameraType) {
                if (mem::equals(cameraType, "perspective")) {
                    Object*! perspective = camera.get("perspective");

                    if (catch err = perspective) return ParseError.BROKEN_BUFFER!;

                    float! aspectRatio = (float)perspective.get_float("aspectRatio");
                    float! yfov = (float)perspective.get_float("yfov");
                    float! zfar = (float)perspective.get_float("zfar");
                    float! znear = (float)perspective.get_float("znear");

                    if (catch err = (aspectRatio, yfov, zfar, znear)) return ParseError.BROKEN_BUFFER!;

                    data.perspective = {
                          aspectRatio,
                          yfov,
                          zfar,
                          znear  
                    };
                }
            }

            content.cameras.push(data);
        }
    }

    file.close()?;
    return content;
 
}

fn void Gltf.close(Gltf* self) {
    foreach (mesh : self.meshes) {
        mesh.primitives.free();
    }

    foreach (buffer : self.buffers) {
        buffer.free();
    }

    self.cameras.free();
    self.accessors.free();
    self.bufferViews.free();
    self.buffers.free();
    self.scenes.free();
    self.nodes.free();
    self.meshes.free();
    self.json.free();
}

fn Node! Gltf.getNode(Gltf* self, String name) {
    foreach (node : self.nodes) {
        if (mem::equals(node.name, name)) {
            return node;
        }
    }

    return GltfError.KEY_NOT_FOUND!;
}

fn Accessor! Gltf.getAccessor(Gltf* data, Object* primitive, String key) {
    if (mem::equals(key, "indices") || mem::equals(key, "material")) {
        Object*! value = primitive.get(key);

        if (try value) return data.accessors[(uint)value.f];
    } else {
        Object*! attributes = primitive.get("attributes");

        if (try attributes) {
            Object*! value = attributes.get(key);
            if (try value) return data.accessors[(uint)value.f];
        }
    }
   
    return GltfError.KEY_NOT_FOUND!;
}


fn BufferView! Gltf.getBufferView(Gltf* data, Object* primitive, String key) {
    Accessor accessor = data.getAccessor(primitive, key)?;
    return data.bufferViews[accessor.bufferView];
}

fn uint Accessor.componentLen(Accessor* self) {
    return {|
            switch(self.type) {
                case AccessorType.SCALAR:
                    return 1;
                case AccessorType.VEC2:
                    return 2;
                case AccessorType.VEC3:
                    return 3;
                case AccessorType.VEC4:
                    return 4;
                case AccessorType.MAT2:
                    return 4;
                case AccessorType .MAT3:
                    return 9;
                case AccessorType.MAT4:
                    return 16;       
            }
            return 0;
    |};
}

fn uint Accessor.componentSize(Accessor* self) {
    return self.dataSize() * self.componentLen();
}

fn uint Accessor.dataSize(Accessor* self) {
    return {|
            switch(self.data_type) {
                case DataType.ICHAR:
                    return ichar.sizeof;
                case DataType.CHAR:
                    return char.sizeof;
                case DataType.SHORT:
                    return short.sizeof;
                case DataType.USHORT:
                    return ushort.sizeof;
                case DataType.UINT:
                    return uint.sizeof;
                case DataType.FLOAT:
                    return float.sizeof;
            }
            return 0;
        |};
}

fn void GltfBuffer.free(GltfBuffer* self) {
    mem::free(self.data);
}

// fn void! Gltf.get_buffer(Gltf* self, Accessor accessor) @inline {
//     BufferView bufferView = self.bufferViews[accessor.bufferView];
//     Buffer buffer = self.buffers[bufferView.buffer];
//     char* data = (buffer.data + accessor.offset + bufferView.offset);

//     for (uint i = 0; i < bufferView.byteLength; i += accessor.size()) {
//         if (accessor.data_type == DataType.USHORT) {
//             ushort value = bitcast(char[2]{data[i], data[i + 1]}, ushort);
//             io::printf("Parsed value %d \n", value);
//         }

//         if (accessor.data_type == DataType.SHORT) {
//             short value = bitcast(char[2]{data[i], data[i + 1]}, short);
//             io::printf("Parsed value %d \n", value);
//         }

//         if (accessor.data_type == DataType.UINT) {
//             uint value = bitcast(char[4]{data[i], data[i + 1], data[i + 2], data[i + 3]}, uint);
//             io::printf("Parsed value %d \n", value);
//         }

//         if (accessor.data_type == DataType.FLOAT) {
//             float value = bitcast(char[4]{data[i], data[i + 1], data[i + 2], data[i + 3]}, float);
//             io::printf(" %d ", value);
//         }
//     }

//     io::printf(" \n _______ \n%d");
// }