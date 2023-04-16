module model;
import std::collections::object;
import std::io;
import gltf;
import std::collections::list;


fn void main() {
    Gltf! data = gltf::loadFile("assets/minimal.gltf");
    defer data.close();

    if (catch err = data) {
        io::printf("Gltf loading failed %s \n", err);
        return;
    }

    foreach (mesh : data.meshes) {
        Primitive prim = mesh.primitives[0];
        int! position = prim.attributes.get_int("POSITION");

        if (try position) {
            Accessor accessor = data.accessors[position];

            if (catch err = data.@get_buffer(accessor)) {
                io::printf("Error parsing buffer %d \n", position);
            }
        };

       
    }
}