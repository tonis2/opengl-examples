module cubes;
import std::io;
import gl;
import glfw;
import gltf;
import std::collections::list;
import std::collections::object;
import stb;
import helpers;
import std::math;

const char* VERTEX_SHADER = `
  #version 430
  
  layout(binding = 0) uniform matrix
  {
      mat4 projection;
      mat4 view;
      mat4 model;
  };

  layout( location = 0 ) in vec3 vp;
  out vec3 theColor;

  void main () {
    theColor = vec3(0, 255, 0);
    gl_Position = projection * view * model * vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 430

  in vec3 theColor;
  out vec4 frag_colour;

  void main () {
    frag_colour = vec4(theColor, 1.0);
  }
`;

struct UniformBuffer {
    Matrix4f projection;
    Matrix4f view;
    Matrix4f model;
}

struct LoadedTexture {
    uint index;
    Image image;
}

fn int main()   
{
    const int WIDTH = 1280;
    const int HEIGHT = 720;

    char* renderer;
    char* version;

    uint vertexBuffer;
    uint indexBuffer;
    uint uniformBuffer;
    uint vao;

    Gltf! gltf_data = gltf::loadFile("assets/cubes.gltf");
    defer gltf_data.close();

    if (catch err = gltf_data) {
        io::printf("Gltf loading failed %d \n", err);
        return 1;
    }

    Node! cameraNode = gltf_data.getNode("Camera");

    if (catch err = cameraNode) {
        io::printf("Camera not found \n");
        return 1;
    }

    Camera camera = gltf_data.cameras[cameraNode.camera];

    UniformBuffer uniformData = UniformBuffer {
        math::matrix4f_perspective(helpers::toRadians(60), WIDTH / HEIGHT, 0.1, 100),
        cameraNode.rotation.to_matrixf().mul(vector::matrix4f_look_at(cameraNode.translation, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0})),
        MATRIX4F_IDENTITY
    };

    glfw::init();
    glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 4);
    glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
    glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
    glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, 1);
    glfw::WindowRef window = glfw::createWindow(WIDTH, HEIGHT, "OpenGL gltf example", null, null);

    if (window == null)
    {
        io::printf("Failed to init gl window");
        glfw::terminate();
        return 1;
    }

    defer {
        glfw::destroyWindow(window);
        glfw::terminate();
    }

    glfw::makeContextCurrent(window);
    gl::init(&glfw::getProcAddress);

    gl::genBuffers(1, &vertexBuffer);
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
    gl::genBuffers(1, &indexBuffer);
    gl::bindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, indexBuffer);

    gl::genVertexArrays(1, &vao);
    gl::bindVertexArray(vao);

    defer {
        gl::deleteBuffers(1, &vertexBuffer);
        gl::deleteBuffers(1, &indexBuffer);
        gl::deleteBuffers(1, &vao);
    }

    uint! vertex_shader = helpers::create_shader(gl::GL_VERTEX_SHADER, &VERTEX_SHADER);
    uint! fragment_shader = helpers::create_shader(gl::GL_FRAGMENT_SHADER, &FRAGMENT_SHADER);
    uint shader_program = gl::createProgram();

    defer {
        gl::detachShader(shader_program, vertex_shader);	
        gl::detachShader(shader_program, fragment_shader);
        gl::deleteShader(vertex_shader);
        gl::deleteShader(fragment_shader);
        gl::deleteProgram(shader_program);
    }

    if (catch err = vertex_shader) {
        io::printf("Error was %s\n", err); 
        return 1;
    }

    gl::attachShader(shader_program, vertex_shader);
    gl::attachShader(shader_program, fragment_shader);
    gl::linkProgram(shader_program);
    gl::useProgram(shader_program);

    // Shader settings
    gl::enableVertexAttribArray(0);
    gl::vertexAttribPointer(0, 3, gl::GL_FLOAT, false, 3*float.sizeof, null);

    // Bind uniform buffer
    uint model_mvp = gl::getUniformBlockIndex(shader_program, "matrix");
    gl::genBuffers(1, &uniformBuffer);
    gl::bindBuffer(gl::GL_UNIFORM_BUFFER, uniformBuffer);
    gl::bindBufferBase(gl::GL_UNIFORM_BUFFER, model_mvp, uniformBuffer);
    gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

    defer gl::deleteBuffers(1, &uniformBuffer);

    gl::depthFunc(gl::GL_LESS );
    gl::enable(gl::GL_DEPTH_TEST);
    gl::enable(gl::GL_CULL_FACE);
    gl::cullFace(gl::GL_FRONT );
    gl::frontFace(gl::GL_CW );

    // Load textures 
    for (uint i = 0; i < gltf_data.images.size; i++) {
        io::printf("image %d \n", i);

        // Image! image = stb::loadImage("./assets/logo.png", Channel.STBI_RGB_ALPHA);
        // if (catch err = image) return 1;

        // defer image.free();

        // Bind texture
        // uint texture;
        // gl::genTextures(1, &texture);
        // gl::bindTexture(gl::GL_TEXTURE_2D, texture);
        // gl::texImage2D(gl::GL_TEXTURE_2D, 0, gl::GL_RGBA, image.width, image.height, 0, gl::GL_RGBA, gl::GL_UNSIGNED_BYTE, &image.pixels[0]);
        // gl::generateMipmap(gl::GL_TEXTURE_2D);     
    }

    while(!glfw::windowShouldClose(window)) {
        gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
        gl::useProgram( shader_program );
        gl::viewport(0, 0, WIDTH, HEIGHT);

        foreach (node : gltf_data.nodes) {
            if (node.mesh >= 0) {
                GltfMesh mesh = gltf_data.meshes[node.mesh];
            
                // Apply node transforms
                uniformData.model = node.recompose();
                gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);
                

                Object* primitive = mesh.primitives[0];
                BufferView! position = gltf_data.getBufferView(primitive, "POSITION");
                BufferView! indices = gltf_data.getBufferView(primitive, "indices");
      
                BufferView! texture_pos = gltf_data.getBufferView(primitive, "TEXCOORD_0");
                uint! material_index = primitive.getValue("material");

                // Vertex buffer
                if (try position) {
                    GltfBuffer buffer = gltf_data.buffers[position.buffer];
                    gl::bufferData(gl::GL_ARRAY_BUFFER, position.byteLength, (buffer.data + position.offset), gl::GL_STATIC_DRAW);
                }

                // Parsing texture data and rendering it
                if (try texture_pos && try material_index) {

                    Material material = gltf_data.materials[material_index];
                    Texture color_texture = gltf_data.textures[material.pbrMetallicRoughness.baseColorTexture.index];
                    Sampler sampler = gltf_data.samplers[color_texture.sampler];
                    GltfImage image_info = gltf_data.images[color_texture.source];
                    BufferView image_buffer = gltf_data.bufferViews[image_info.bufferView];

                    // uint! texture_id = gltf_data.buffers
                    // gl::bufferData(gl::GL_ARRAY_BUFFER, position.byteLength, (buffer.data + position.offset), gl::GL_STATIC_DRAW);
                }

                // Index buffer
                if (try indices) {
                    GltfBuffer buffer = gltf_data.buffers[indices.buffer];
                    char* index_buffer = (buffer.data + indices.offset);
                    gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices.byteLength, index_buffer, gl::GL_STATIC_DRAW);
                    gl::drawElements(gl::GL_TRIANGLES, (int)(indices.byteLength / ushort.sizeof), gl::GL_UNSIGNED_SHORT, &index_buffer[0]);
                }
            }
        }

        glfw::pollEvents();
        glfw::swapBuffers(window);
    }

    return 0;
}