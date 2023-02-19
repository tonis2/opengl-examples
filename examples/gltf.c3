module gltf;
import libc;
import std::io;
import json;
import hashmap;

define JsonMap = HashMap<char*, char*>;

char* data = "{\"asset\":{\"generator\":\"Khronos glTF Blender I/O v3.4.50\",\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"name\":\"Scene\",\"nodes\":[0]}]}";

fn void main() {




    JsonParser parser = json::decoder(data);
    defer parser.free();


    JSONValue*! version = parser.get("version");

    if (try version)
    {
        libc::printf("Found %s \n", version.value);
    }

    // JSONValue value = JSONValue {
    //                                 JSONType.J_VALUE,
    //                                 (char*)libc::malloc(100),
    //                                 (char*)libc::malloc(100),
    //                                 null
    //                             };

    // JsonMap data;
    // defer data.free();

    // char* key = (char*)libc::malloc(10);
    // char* value = (char*)libc::malloc(10);

    // String keyValue = "test";

    // libc::memcpy(key, "test", 4);
    // libc::memcpy(value, "body", 4);

    // data.set(key, value);

    // char*! ref = data.get("test");



    // io::printfn("Has key: %s", data.has_key("test"));

    // char*! test = data["test"];



     // foreach (char* entry : data.key_list())
	// {
    //      libc::printf("Key value = %s \n", entry);
    // }

    // char[] = parser.get("asset.generator.version");

}