module gltf;
import libc;
import json;

char* data = "{\"asset\":{\"generator\":\"Khronos glTF Blender I/O v3.4.50\",\"version\":\"2.0\"},\"scene\":0,\"scenes\":[{\"name\":\"Scene\",\"nodes\":[0]}]}";

fn void main() {
    JsonParser parser = json::decoder(data);

    libc::printf("first char %c \n", parser.skipSpaces());
    libc::printf("second char %c \n", parser.skipSpaces());
}