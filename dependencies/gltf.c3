import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::core::mem;
import std::collections::list;
import std::encoding::json;
import base64;

typedef NodeList = List<Node>;
typedef SceneList= List<Scene>;
typedef MeshList = List<Mesh>;
typedef IndexList = List<uint>;
typedef BufferList = List<char*>;

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
    Object* buffers = gltfJson.get("buffers")?;

    // Parsed data
    SceneList scenes;

    // Parse scenes
    foreach (scene : gltfJson.get("scenes")?.array) {
        Scene sceneItem;
        sceneItem.name = scene.get_string("name")?;
        foreach (node : scene.get("nodes")?.array) sceneItem.nodes.push((uint)node.f);
        content.scenes.push(sceneItem);
    }

    // Parse nodes
    foreach (node : gltfJson.get("nodes")?.array) {

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
    foreach (mesh : gltfJson.get("meshes")?.array) {
        Mesh meshItem;
        meshItem.name = mesh.get_string("name")?;
        content.meshes.push(meshItem);
    }


    // Parse buffers
    foreach (buffer : gltfJson.get("buffers")?.array) {
        Object*! length = buffer.get("byteLength");
        Object*! data = buffer.get("uri");

        if (try length) {
            char* bufferContent = mem::malloc(char, (int)length.f);
     
            if (base64::decode(data.s, bufferContent)?) {
                // Not working
                io::printf("Added buffer!");
                content.buffers.push(bufferContent);
              
            } else {
                mem::free(bufferContent);
            }
        }
    }

    content.json = gltfJson;

    file.close()?;
    return content;
 
}

fn void Gltf.close(Gltf* self) {
  
    foreach (buffer : self.buffers) {
        mem::free(buffer);
    }

    self.buffers.free();
    self.scenes.free();
    self.nodes.free();
    self.meshes.free();
    self.json.free();
}   

struct Gltf {
    Object* json;
    String name;
    NodeList nodes;
    SceneList scenes;
    MeshList meshes;
    BufferList buffers;
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

struct Mesh {
    String name;
    Vec3f position;
    Vec2f texture_position;
    Vec3f normal;
}

// struct Primitive {
//     uint indices;
//     uint material;
//     struct attributes {
//         uint position;
//         uint texrcord_0;
//         uint normal;
//     }
// }