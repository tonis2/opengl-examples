module model;
import std::collections::object;
import std::io;
import gltf;


fn void main() {
    Gltf! data = gltf::loadFile("assets/casa.gltf");
    
    defer data.close();

}