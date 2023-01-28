module gltf;
import libc;
import json;

char* data = "{\"asset\":{\"generator\":\"Khronos glTF Blender I/O v3.4.50\",\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"name\":\"Scene\",\"nodes\":[0]}]}";

fn void main() {
    JsonParser parser = json::decoder(data);
    defer parser.destroy();


    if (try value = parser.map.get("nodes")) {
        libc::printf("Key value = %d \n", value);
    }
    // char[] = parser.get("asset.generator.version");

}