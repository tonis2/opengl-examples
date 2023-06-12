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

  layout (location = 0) in vec3 vp;
  layout (location = 1) in vec2 texturePosition;
  
  out vec3 theColor;
  out vec2 texCords;

  void main () {
    texCords = texturePosition;
    gl_Position = projection * view * model * vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 430
  uniform sampler2D textureData;

  in vec2 texCords;
  out vec4 frag_colour;

  void main () {
    frag_colour = texture(textureData, texCords);
  }
`;

typedef LoadedImages = List<Image>;

struct UniformBuffer {
    Matrix4f projection;
    Matrix4f view;
    Matrix4f model;
}

uint vertexBuffer;
uint indexBuffer;
uint uniformBuffer;
uint vao;
double xPos, yPos;

float cameraX = 0; 
float cameraY = 0; 
float cameraZ = -10;

UniformBuffer uniformData;

fn void keyboardEvents(WindowRef window, int key, int scancode, int action, int mods) {

    // up arrow 
    if (key == 265) {
        cameraY += 0.5;
    }

    // down arrow 
    if (key == 264) {
        cameraY -= 0.5;
    }

    // left arrow 
    if (key == 262) {
        cameraX -= 0.5;
    }

    // right arrow 
    if (key == 263) {
        cameraX += 0.5;
    }

    uniformData.view = vector::matrix4f_look_at({cameraX, cameraY, cameraZ}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0});
}

fn void mouseEvents(WindowRef window, int button, int action, int mods) {
    io::printf("button code %d \n", button);
    // io::printf("x pos %d , y pos %d \n", xPos, yPos);
}

fn void drawNode(Node node, Gltf data, UniformBuffer* uniformData) {
    if (node.mesh >= 0) {
        GltfMesh mesh = data.meshes[node.mesh];
    
        // Apply node transforms
        uniformData.model = node.recompose();
        gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, uniformData, gl::GL_DYNAMIC_DRAW);
        
        Object* primitive = mesh.primitives[0];
        BufferView! position = data.getBufferView(primitive, "POSITION");
        BufferView! texture_pos = data.getBufferView(primitive, "TEXCOORD_0");
        BufferView! indices = data.getBufferView(primitive, "indices");
       
        uint! material_index = primitive.getValue("material");

        // Vertex buffer
        if (try position && try texture_pos) {
            GltfBuffer buffer = data.buffers[position.buffer];
            // Bind vertex position and texture position to same buffer

            gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
            gl::bufferData(gl::GL_ARRAY_BUFFER, position.byteLength + texture_pos.byteLength, null, gl::GL_STATIC_DRAW);
            
            gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, position.byteLength, (buffer.data + position.offset));
            gl::bufferSubData(gl::GL_ARRAY_BUFFER, position.byteLength, texture_pos.byteLength, (buffer.data + texture_pos.offset));  

            gl::vertexAttribPointer(0, 3, gl::GL_FLOAT, false, 0, null);
            gl::vertexAttribPointer(1, 2, gl::GL_FLOAT, false, 0, (void*)(usz)(position.byteLength));
        }


        // Parsing texture data and rendering it
        if (try material_index) {
            Material material = data.materials[material_index];
            Texture color_texture = data.textures[material.pbrMetallicRoughness.baseColorTexture.index];
            Sampler color_sampler = data.samplers[color_texture.sampler];
            gl::bindTexture(gl::GL_TEXTURE_2D, color_texture.source + 1);
        }

        // Index buffer
        if (try indices) {
            GltfBuffer buffer = data.buffers[indices.buffer];
            char* index_buffer = (buffer.data + indices.offset);
            gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices.byteLength, index_buffer, gl::GL_STATIC_DRAW);
            gl::drawElements(gl::GL_TRIANGLES, (int)(indices.byteLength / ushort.sizeof), gl::GL_UNSIGNED_SHORT, &index_buffer[0]);
        }
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

    uniformData = {
        helpers::perspective(0.6, WIDTH / HEIGHT, 0.1, 100),
        vector::matrix4f_look_at({cameraX, cameraY, cameraZ}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}),
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
    gl::genBuffers(1, &indexBuffer);
    
    gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
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

    gl::enableVertexAttribArray(0);
    gl::enableVertexAttribArray(1);
   
    // Bind uniform buffer
    uint model_mvp = gl::getUniformBlockIndex(shader_program, "matrix");
    gl::genBuffers(1, &uniformBuffer);
    gl::bindBuffer(gl::GL_UNIFORM_BUFFER, uniformBuffer);
    gl::bindBufferBase(gl::GL_UNIFORM_BUFFER, model_mvp, uniformBuffer);
    gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

    defer gl::deleteBuffers(1, &uniformBuffer);

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

        // Update world rotation
        gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

        foreach (node : gltf_data.nodes) {
            drawNode(node, gltf_data, &uniformData);
        }
       
        glfw::pollEvents();
        glfw::getCursorPos(window, &xPos, &yPos);
        glfw::swapBuffers(window);
    }

    return 0;
}