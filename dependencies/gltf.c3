import std::collections::object;
import std::io;
import std::ascii;
import std::math::matrix;
import std::math;
import std::collections::list;
import std::encoding::json;

typedef IntList = List<int>;
typedef SceneList= List<Scene>;
typedef PrimitiveList = List<Primitive>;


fault ParseError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
}    


fn Gltf! loadFile(String path) {
    File! fileData = file::open(path, "r");
    if (catch err = fileData)
    {
        case IoError.FILE_NOT_FOUND:
            return ParseError.FILE_NOT_FOUND!;
        default:
            return ParseError.FILE_NOT_READABLE!;
    }

    Gltf content;
    content.data = fileData;

    JsonParser json;
	json.init(fileData.as_stream());
	Object*! gltfData = json.parse_any();
    // var scenes = gltfData.get("scenes")?;

    return content;
 
}

fn void Gltf.close(Gltf* self) {
    self.scenes.free();
    (void)self.data.close();
}   

struct Gltf {
    File data;
    String name;
    SceneList scenes;
}

struct Scene {
    String name;
    IntList nodes;
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