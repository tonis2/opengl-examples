module gltf;
import std::collections::object;
import std::io;

import std::encoding::json;

fn void main() {
    File! gltfFile = file::open("assets/casa.gltf", "r");
    if (catch err = gltfFile)
    {
        case IoError.FILE_NOT_FOUND:
            io::printfn("Could not find the file");
        default:
            io::printfn("Could not load file");
  
        return;     
    }

    defer (void)gltfFile.close();

    JsonParser json;
	json.init(gltfFile.as_stream());
	Object*! gltfData = json.parse_any();


   

	// reader.init(`{ "b": 123, "c": [ { "d": 66 }, null, "hello", false ] }`);
	// JsonParser json;
	// json.init(reader.as_stream());

}