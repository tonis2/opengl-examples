import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::collections::list;
import std::encoding::json;

typedef NodeList = List<Node>;
typedef SceneList= List<Scene>;
typedef PrimitiveList = List<Primitive>;

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

    Object* nodes = gltfJson.get("nodes")?;

    // Parse scenes array
    foreach (scene : gltfJson.get("scenes")?.array) {

        Scene sceneItem;
        sceneItem.name = scene.get_string("name")?;

        foreach (node : scene.get("nodes")?.array) {

             // Get node data at index
             double node_id = node.f;
             Object* node_json = nodes.get_at((ulong)node_id);

             Node nodeItem;
             nodeItem.name = node_json.get_string("name")?;

             // Parse node transforms
             Object*! rotation = node_json.get("rotation");
             Object*! scale = node_json.get("scale");
             Object*! translation = node_json.get("translation");

             if (try rotation) {
                 nodeItem.rotation = Vec4f {(float)rotation.get_at(0).f, (float)rotation.get_at(1).f, (float)rotation.get_at(2).f, (float)rotation.get_at(3).f};
             }

             if (try scale) {
                 nodeItem.scale = Vec3f {(float)scale.get_at(0).f, (float)scale.get_at(1).f, (float)scale.get_at(2).f };
             }

             if (try translation) {
                 nodeItem.translation = Vec3f {(float)translation.get_at(0).f, (float)translation.get_at(1).f, (float)translation.get_at(2).f };
             }
        }
    }

    content.json = gltfJson;

    file.close()?;
    return content;
 
}

fn void Gltf.close(Gltf* self) {
    self.scenes.free();
    self.json.free();
}   

struct Gltf {
    Object* json;
    String name;
    SceneList scenes;
}

struct Scene {
    String name;
    NodeList nodes;
}

struct Node {
    String name;
    Vec4f rotation;
    Vec3f scale;
    Vec3f translation;
}

struct Mesh {
    String name;
    PrimitiveList primitives;
}

struct Primitive {
    uint indices;
    uint material;
    struct attributes {
        uint position;
        uint texrcord_0;
        uint normal;
    }
}