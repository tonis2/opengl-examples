module model;
import std::io;
import gl;
import glfw;
import gltf;
import std::collections::object;
import helpers;
import std::math;
import std::math::vector;
import std::math::matrix;

const char* VERTEX_SHADER = `
  #version 430
  
  layout(binding = 0) uniform matrix
  {
      mat4 projection;
      mat4 view;
      mat4 model;
  };

  layout( location = 0 ) in vec3 vp;
//   layout( location = 1 ) in vec3 vcolor;

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

const int WIDTH = 1280;
const int HEIGHT = 720;

uint vertexBuffer;
uint indexBuffer;
uint uniformBuffer;
uint vao;

fn int main() {
    Matrix4f perspective = math::matrix4f_perspective(helpers::toRadians(60), WIDTH / HEIGHT, -5.0, 1000);
    Matrix4f lookAt = vector::matrix4f_look_at(Vec3f{0.0, 0.0, -1}, Vec3f{0.0, 0.0, 0.0}, Vec3f{0.0, 1.0, 0.0});
    Matrix4f model = helpers::identity_4x4().rotate_y(10).rotate_x(20);

    Gltf! gltf_data = gltf::loadFile("assets/cubes.gltf");
    defer gltf_data.close();

    UniformBuffer uniformData = UniformBuffer {
        perspective,
        lookAt,
        model
    };

    if (catch err = gltf_data) {
        io::printf("Gltf loading failed %s \n", err);
        return 1;
    }

    glfw::init();
    glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 4);
    glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 3);
    glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
    glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, 1);
    glfw::WindowRef window = glfw::createWindow(WIDTH, HEIGHT, "OpenGL cubes", null, null);

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

    uint model_mvp = gl::getUniformBlockIndex(shader_program, "matrix");
    gl::genBuffers(1, &uniformBuffer);
    gl::bindBuffer(gl::GL_UNIFORM_BUFFER, uniformBuffer);
    gl::bindBufferBase(gl::GL_UNIFORM_BUFFER, model_mvp, uniformBuffer);
    gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

    defer gl::deleteBuffers(1, &uniformBuffer);


    // GLTF Loading
    Mesh mesh = gltf_data.meshes[0];
    Object* primitive = mesh.primitives[0];

    Accessor! position = gltf_data.getAccessor(primitive, "POSITION");
    Accessor! texture = gltf_data.getAccessor(primitive, "TEXCOORD_0");
    Accessor! indices = gltf_data.getAccessor(primitive, "indices");

    if (try position) {
        BufferView view = gltf_data.bufferViews[position.bufferView];
        Buffer buffer = gltf_data.buffers[view.buffer];

        gl::enableVertexAttribArray(0);
        gl::vertexAttribPointer(0, position.data_len(), gl::GL_FLOAT, false, position.data_size(), null);

        gl::genBuffers(1, &vertexBuffer );
        gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
        gl::bufferData(gl::GL_ARRAY_BUFFER, view.byteLength, (buffer.data + view.offset), gl::GL_STATIC_DRAW);
    }

    if (try indices) {
        BufferView view = gltf_data.bufferViews[indices.bufferView];
        Buffer buffer = gltf_data.buffers[view.buffer];

        gl::genBuffers(1, &indexBuffer);
        gl::bindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
        gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, view.byteLength, (buffer.data + view.offset), gl::GL_STATIC_DRAW);
        gl::drawElements(gl::GL_TRIANGLES, 6*6, gl::GL_UNSIGNED_INT, (buffer.data + view.offset));
    }

    if (try texture) {
        io::printf("Texture entries %d \n", texture.count);
    }

    // foreach (node : gltf_data.nodes) {
    //     Matrix4f tranform = helpers::identity_4x4().scale(node.scale).translate(node.translation);
    // }

    gl::depthFunc( gl::GL_LESS );
    gl::enable(gl::GL_DEPTH_TEST);
    gl::enable(gl::GL_CULL_FACE);
    gl::cullFace( gl::GL_FRONT );
    gl::frontFace( gl::GL_CW ); 

    while(!glfw::windowShouldClose(window)) {
        gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
        gl::useProgram( shader_program );
        gl::viewport(0, 0, WIDTH, HEIGHT);

        glfw::pollEvents();
        glfw::swapBuffers(window);
    }

  return 0;

}