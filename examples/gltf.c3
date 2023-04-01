module model;
import std::collections::object;
import std::io;
import gltf;
import std::collections::list;


typedef Buffer = List<float>;

fn void main() {
    Gltf! data = gltf::loadFile("assets/minimal.gltf");
    defer data.close();

    if (catch err = data) {
        io::printf("Gltf loading failed %s \n", err);
        return;
    }

    // foreach (node : data.nodes) {
    //     if (node.mesh) {
    //         Mesh mesh = data.meshes[node.mesh];

    //         Primitive prim = mesh.primitives[0];
    //         int! position = prim.attributes.get_int("POSITION");

    //         if (try position) {
    //             io::printf("Position %d \n", position);
    //             Accessor accessor = data.accessors[position];

    //             uint size = accessor.size(float.sizeof);


           
    //         };
    //     };
    // }


    foreach (mesh : data.meshes) {
        Primitive prim = mesh.primitives[0];
        int! position = prim.attributes.get_int("POSITION");

        Buffer buffferData;
        defer buffferData.free();

        if (try position) {
            Accessor accessor = data.accessors[position];
            anyerr err = data.@get_buffer(accessor, &buffferData);
        };

        foreach (item : buffferData) {
            io::printf("item %d \n", item);
        }
    }
}