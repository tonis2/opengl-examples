module model;
import std::collections::object;
import std::io;
import gltf;
import std::collections::list;
import std::core::mem;

fn void main() {
    Gltf! gltf_data = gltf::loadFile("assets/minimal.gltf");
    defer gltf_data.close();

    if (catch err = gltf_data) {
        io::printf("Gltf loading failed %s \n", err);
        return;
    }

    foreach (mesh : gltf_data.meshes) {
        Primitive prim = mesh.primitives[0];

        int indices = prim.indices;
        int! position = prim.attributes.get_int("POSITION");
       
        Accessor indices_data = gltf_data.accessors[indices];

        if (catch err = gltf_data.@get_buffer(indices_data)) {
            io::printf("Error parsing buffer %d \n", indices);
        }

        if (try position) {
            Accessor position_data = gltf_data.accessors[position];
            
            if (catch err = gltf_data.@get_buffer(position_data)) {
                io::printf("Error parsing buffer %d \n", position);
            }
        };

       
    }
}