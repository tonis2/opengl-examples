module cubes;
import std::io;
import gl;
import glfw;
import gltf;
import std::collections::list;
import std::collections::object;
import stb;
import helpers;
import camera;
import std::math;

const char* VERTEX_SHADER = `
  #version 430
  
  layout(binding = 0) uniform matrix
  {
      mat4 projection;
      mat4 view;
      mat4 model;
  };

  layout(binding = 1) uniform material
  {
      vec4 colorValue;
  };
  
  layout (location = 0) in vec3 vp;
  layout (location = 1) in vec2 texturePosition;
  
  out vec4 materialColor;
  out vec2 texCords;

  void main () {
    texCords = texturePosition;
    materialColor = colorValue;
    gl_Position = projection * view * model * vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 430
  uniform sampler2D textureData;

  in vec2 texCords;
  in vec4 materialColor;
  out vec4 frag_colour;

  void main () {
    frag_colour = materialColor * texture(textureData, texCords);
  }
`;

def LoadedImages = List<Image>;

struct GltfMaterial {
    float[4] color;
}

uint vertexBuffer, indexBuffer;
uint uniformBuffer, materialBuffer;
uint vao;
double xPos, yPos;
double xPosDelta, yPosDelta;
bool rightMouseClick = false;

Camera renderCamera;
GltfMaterial material;

fn void keyboardEvents(WindowRef window, int key, int scancode, int action, int mods) {

    // up arrow 
    if (key == 265) {
        renderCamera.add_zoom(-0.5);
    }

    // down arrow 
    if (key == 264) {
        renderCamera.add_zoom(0.5);
    }

    // // left arrow 
    // if (key == 262) {
    //     renderCamera.scene_offset({0.0, 0.5, 0.0});
    // }

    // // right arrow 
    // if (key == 263) {
    //     renderCamera.scene_offset({0.0, -0.5, 0.0});
    // }
}

fn void mouseEvents(WindowRef window, int button, int action, int mods) {
    // left mouse button action
    if (button == 0) {
        if (action == 1) {
            rightMouseClick = true;
        } else {
            rightMouseClick = false;
        }
    }

    // right button
    if (button == 1) {}
}

fn void drawNode(Node node, Gltf data) {
    if (node.mesh >= 0) {
        GltfMesh mesh = data.meshes[node.mesh];

        UniformData uniformData = renderCamera.matrix(node.recompose());
    
        // Apply node transforms
        gl::bindBufferRange(gl::GL_UNIFORM_BUFFER, 0, uniformBuffer, 0, UniformData.sizeof);
        gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformData.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);
        
        Object* primitive = mesh.primitives[0];
        Accessor! position_accessor = data.getAccessor(primitive, "POSITION");
        BufferView! position = data.getBufferView(primitive, "POSITION");
        BufferView! texture_pos = data.getBufferView(primitive, "TEXCOORD_0");
        BufferView! indices = data.getBufferView(primitive, "indices");
        uint! material_index = primitive.getValue("material");

        if (catch err = position, texture_pos, indices, material_index, position_accessor) {
            io::printf("failed node parsing \n");
            return;
        }

        // Buffer for position + texcordinate + color
        uint render_buffer_size = position.byteLength + texture_pos.byteLength;
        char* render_buffer = mem::malloc(char, render_buffer_size);
        
        // Parsing texture data
        Material materialData = data.materials[material_index];
        // Bind texture data
        Texture color_texture = data.textures[materialData.pbrMetallicRoughness.baseColorTexture.index];
        Sampler color_sampler = data.samplers[color_texture.sampler];
        gl::bindTexture(gl::GL_TEXTURE_2D, color_texture.source + 1);

        material.color = materialData.pbrMetallicRoughness.baseColorFactor;

        // Set material buffer data
        gl::bindBufferRange(gl::GL_UNIFORM_BUFFER, 1, materialBuffer, 0, 192);
        gl::bufferData(gl::GL_UNIFORM_BUFFER, 192, &material, gl::GL_DYNAMIC_DRAW);

        // Copy buffers to render_buffer
        GltfBuffer buffer = data.buffers[position.buffer];
        mem::copy(render_buffer, (buffer.data + position.offset), position.byteLength);
        mem::copy((render_buffer + position.byteLength), (buffer.data + texture_pos.offset), texture_pos.byteLength);

        // Set vertex buffer data
        gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
        gl::vertexAttribPointer(0, 3, gl::GL_FLOAT, false, 0, null);
        gl::vertexAttribPointer(1, 2, gl::GL_FLOAT, false, 0, (void*)(usz)position.byteLength);
        gl::bufferData(gl::GL_ARRAY_BUFFER, render_buffer_size, render_buffer, gl::GL_STATIC_DRAW);

        // Index buffer
        char* index_buffer = (buffer.data + indices.offset);
        gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices.byteLength, index_buffer, gl::GL_STATIC_DRAW);
        gl::drawElements(gl::GL_TRIANGLES, (int)(indices.byteLength / ushort.sizeof), gl::GL_UNSIGNED_SHORT, &index_buffer[0]);
        mem::free(render_buffer);
    }
}

fn int main()   
{
    const int WIDTH = 1280;
    const int HEIGHT = 720;
    
    char* renderer;
    char* version;

    LoadedImages loadedImages;

    defer {
        foreach (image : loadedImages) {
            gl::deleteTextures(1, &image.index);
            image.free();
        };
        loadedImages.free();
        
    };

    Gltf! gltf_data = gltf::loadFile("assets/boat.gltf");
    defer gltf_data.close();

    if (catch err = gltf_data) {
        io::printf("Gltf loading failed %d \n", err);
        return 1;
    }

    Node! cameraNode = gltf_data.getNode("Camera");

    // if (catch err = cameraNode) {
    //     io::printf("Camera not found \n");
    //     return 1;
    // }

    // Camera camera = gltf_data.cameras[cameraNode.camera];

    renderCamera = camera::new({0, 0, 0}, 10, WIDTH / HEIGHT);

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

    // Generate buffers
    gl::genBuffers(1, &vertexBuffer);
    gl::genBuffers(1, &indexBuffer);
    gl::genBuffers(1, &uniformBuffer);
    gl::genBuffers(1, &materialBuffer);

    gl::bindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    gl::genVertexArrays(1, &vao);
    gl::bindVertexArray(vao);
   
    defer {
        gl::deleteBuffers(1, &vertexBuffer);
        gl::deleteBuffers(1, &indexBuffer);
        gl::deleteBuffers(1, &uniformBuffer);
        gl::deleteBuffers(1, &materialBuffer);
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

    gl::enableVertexAttribArray(0);
    gl::enableVertexAttribArray(1);

    gl::enable(gl::GL_DEPTH_TEST);
    gl::enable(gl::GL_CULL_FACE);

    // Upload textures to GPU memory
    foreach (gltf_img : gltf_data.images) {
        BufferView image_view = gltf_data.bufferViews[gltf_img.bufferView];
        GltfBuffer buffer = gltf_data.buffers[image_view.buffer];
        Image! image = stb::loadFromBuffer((buffer.data + image_view.offset), image_view.byteLength, Channel.STBI_RGB);
      
        if (catch err = image) {
            io::printf("Image loading failed \n");
            return 1;
        };
       
        gl::genTextures(1, &image.index);
        gl::bindTexture(gl::GL_TEXTURE_2D, image.index);
        gl::texImage2D(gl::GL_TEXTURE_2D, 0, gl::GL_RGB, image.width, image.height, 0, gl::GL_RGB, gl::GL_UNSIGNED_BYTE, &image.pixels[0]);
        gl::generateMipmap(gl::GL_TEXTURE_2D);
        
        // gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MIN_FILTER, gl::GL_LINEAR_MIPMAP_LINEAR);
        // gl::texParameteri(gl::GL_TEXTURE_2D, gl::GL_TEXTURE_MAG_FILTER, gl::GL_LINEAR);

        loadedImages.push(image);
    }


    glfw::setKeyCallback(window, (KeyCallback*)&keyboardEvents);
    glfw::setMouseButtonCallback(window, (MouseCallback*)&mouseEvents);

    while(!glfw::windowShouldClose(window)) {
        gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
        gl::useProgram( shader_program );
        gl::viewport(0, 0, WIDTH, HEIGHT);

        foreach (node : gltf_data.nodes) {
            drawNode(node, gltf_data);
        }

        if (rightMouseClick == true) {
            // Slow down mouse delta, and rotate the model
            renderCamera.rotate_x(-(float)(xPosDelta * 0.5));
            renderCamera.rotate_y(-(float)(yPosDelta * 0.5));
        }
       
        glfw::pollEvents();
        double xLocal, yLocal;
        glfw::getCursorPos(window, &xLocal, &yLocal);

        xPosDelta = xLocal - xPos;
        yPosDelta = yLocal - yPos;
        xPos = xLocal;
        yPos = yLocal;

        glfw::swapBuffers(window);
    }

    return 0;
}