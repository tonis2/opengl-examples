module texture;
import glfw;
import helpers;
import gl;
import std::io;
import std::math;
import std::math::vector;
import std::math::matrix;
import stb;
import std::core::mem;
import libc;

// Shader data

const char* VERTEX_SHADER = `
  #version 420
  
  layout(binding = 0) uniform matrix
  {
      mat4 projection;
      mat4 view;
      mat4 model;
  };

  layout( location = 0 ) in vec3 vp;
  layout( location = 1 ) in vec3 vcolor;
  layout( location = 2 ) in vec2 textureCord;

  out vec3 ourColor;
  out vec2 texCords;

  void main () {
    ourColor = vcolor;
    texCords = textureCord;
    gl_Position = projection * view * model * vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 420

  in vec3 ourColor;
  in vec2 texCords;

  uniform sampler2D ourTexture;
  
  out vec4 frag_colour;

  void main () {
    frag_colour = vec4(ourColor + 0.8, 1.0) * texture(ourTexture, texCords);
  }
`;

const float CUBE_WIDTH = 1.0;

// Vertex data

float[] cube_data = {

    // Red
    -CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,  255, 0, 0,  
		CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,   255, 0, 0,  
		CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,    255, 0, 0,  
		-CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,   255, 0, 0,  

    // Green
		-CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH, 0, 255, 0,  
		-CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,  0, 255, 0,  
		CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,   0, 255, 0, 
		CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH,  0, 255, 0,  

    //Pink

		-CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,  245, 40, 145, 
		-CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,   245, 40, 145, 
		CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,    245, 40, 145, 
		CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,   245, 40, 145, 

    // Yellow
		-CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH,  254, 206, 33, 
		CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH,   254, 206, 33, 
		CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,    254, 206, 33, 
		-CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,   254, 206, 33, 

    // Blue
		CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH,   0, 0, 193, 
		CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,    0, 0, 193, 
		CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,     0, 0, 193, 
		CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,    0, 0, 193, 

    // Black
    -CUBE_WIDTH, -CUBE_WIDTH, -CUBE_WIDTH,  0, 0, 1,  
    -CUBE_WIDTH, -CUBE_WIDTH, CUBE_WIDTH,   0, 0, 1, 
    -CUBE_WIDTH, CUBE_WIDTH, CUBE_WIDTH,    0, 0, 1, 
    -CUBE_WIDTH, CUBE_WIDTH, -CUBE_WIDTH,   0, 0, 1, 
};


float[] texture_positions = {
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
  1.0, 1.0,
  1.0, 0.0,
  0.0, 0.0,
  0.0, 1.0,
};

uint [] indices = {
    0,  1,  2,      0,  2,  3,    // front
    4,  5,  6,      4,  6,  7,    // back
    8,  9,  10,     8,  10, 11,   // top
    12, 13, 14,     12, 14, 15,   // bottom
    16, 17, 18,     16, 18, 19,   // right
    20, 21, 22,     20, 22, 23    // left
};

struct UniformBuffer {
    Matrix4f projection;
    Matrix4f view;
    Matrix4f model;
}

fn int main()   
{
  const int WIDTH = 1280;
  const int HEIGHT = 720;
  char* renderer;
  char* version;

  float rotation = 0;

  UniformBuffer uniformData = {
      matrix4f_perspective(0.6, WIDTH / HEIGHT, 0.1, 100),
      vector::matrix4f_look_at({0.0, 0.0, -10.0}, {0.0, 0.0, 0.0}, {0.0, 1.0, 0.0}),
      MATRIX4F_IDENTITY
  };

  glfw::init();
  glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 4);
  glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 6);
  glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
  glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, 1);
  glfw::WindowRef window = glfw::createWindow(WIDTH, HEIGHT, "OpenGL rotating cube", null, null);

  if (window == null)
  {
        io::printfn("Failed to init gl window");
        glfw::terminate();
        return 1;
  }

  defer {
    glfw::destroyWindow(window);
    glfw::terminate();
  }

  glfw::makeContextCurrent(window);
  gl::init(&glfw::getProcAddress);

  renderer = gl::getString( gl::GL_RENDERER );
  version  = gl::getString( gl::GL_VERSION );

  libc::printf("Renderer: %s\n", renderer );
  libc::printf("OpenGL version supported %s\n", version );

  // Load texture
  Image! image = stb::loadImage("./assets/logo.png", Channel.STBI_RGB_ALPHA);
  if (catch err = image) return 1;

  defer image.free();

  // Bind texture
  uint texture;
  gl::genTextures(1, &texture);
  gl::bindTexture(gl::GL_TEXTURE_2D, texture);
  gl::texImage2D(gl::GL_TEXTURE_2D, 0, gl::GL_RGBA, image.width, image.height, 0, gl::GL_RGBA, gl::GL_UNSIGNED_BYTE, &image.pixels[0]);
  gl::generateMipmap(gl::GL_TEXTURE_2D);

  usz cube_size = cube_data.len * float.sizeof;
  usz indices_size = indices.len * uint.sizeof;
  usz texture_pos_size = texture_positions.len * float.sizeof;

  uint vertexBuffer;
  uint indexBuffer;
  uint uniformBuffer;
  uint vao;

  // Vertex buffer
  gl::genBuffers(1, &vertexBuffer );
  gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
  gl::bufferData(gl::GL_ARRAY_BUFFER, cube_size + texture_pos_size, null, gl::GL_STATIC_DRAW);

  gl::bufferSubData(gl::GL_ARRAY_BUFFER, 0, cube_size, cube_data);
  gl::bufferSubData(gl::GL_ARRAY_BUFFER, cube_size, texture_pos_size, texture_positions);

  // Index buffer
  gl::genBuffers(1, &indexBuffer );
  gl::bindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
  gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices_size, indices, gl::GL_STATIC_DRAW);

  gl::genVertexArrays(1, &vao );
  gl::bindVertexArray( vao );

  defer {
    gl::deleteBuffers(1, &vertexBuffer);
    gl::deleteBuffers(1, &vao);
  }

    uint! vertex_shader = helpers::create_shader(gl::GL_VERTEX_SHADER, &VERTEX_SHADER);
    uint! fragment_shader = helpers::create_shader(gl::GL_FRAGMENT_SHADER, &FRAGMENT_SHADER);
    uint shader_program = gl::createProgram();

    if (catch err = vertex_shader) {
        io::printfn("Error was %s", err);
        return 1;
    }


    if (catch err = fragment_shader) {
        io::printfn("Error was %s", err);
        return 1;
    }

  defer {
    gl::detachShader(shader_program, vertex_shader);	
    gl::detachShader(shader_program, fragment_shader);
    gl::deleteShader(vertex_shader);
    gl::deleteShader(fragment_shader);
    gl::deleteProgram(shader_program);
    gl::deleteTextures(1, &texture);
  }



  gl::attachShader(shader_program, vertex_shader);
  gl::attachShader(shader_program, fragment_shader);
  gl::linkProgram(shader_program);
  gl::useProgram(shader_program);


  // Shader settings
  gl::enableVertexAttribArray(0);
  gl::vertexAttribPointer(0, 3, gl::GL_FLOAT, false, 6*float.sizeof, null);

  gl::enableVertexAttribArray(1);
  gl::vertexAttribPointer(1, 3, gl::GL_FLOAT, false, 6*float.sizeof, (void*)(3*float.sizeof));

  gl::enableVertexAttribArray(2);
  gl::vertexAttribPointer(2, 2, gl::GL_FLOAT, false, 0, (void*)cube_size);


  // Bind uniform buffer
  uint model_mvp = gl::getUniformBlockIndex(shader_program, "matrix");
  gl::genBuffers(1, &uniformBuffer);
  gl::bindBuffer(gl::GL_UNIFORM_BUFFER, uniformBuffer);
  gl::bindBufferBase(gl::GL_UNIFORM_BUFFER, model_mvp, uniformBuffer);
  gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

  gl::enable(gl::GL_DEPTH_TEST);
  gl::enable(gl::GL_CULL_FACE);

  while(!glfw::windowShouldClose(window)) {
    gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
    gl::useProgram( shader_program );
    gl::viewport(0, 0, WIDTH, HEIGHT);


    if (rotation < 360) {
      rotation += 0.01;
    } else {
      rotation = 0;
    }
    
    // Update model rotation
    uniformData.model = MATRIX4F_IDENTITY.rotate_y(rotation).rotate_x(0.3);
    gl::bufferData(gl::GL_UNIFORM_BUFFER, UniformBuffer.sizeof, &uniformData, gl::GL_DYNAMIC_DRAW);

    gl::drawElements(gl::GL_TRIANGLES, 6*6, gl::GL_UNSIGNED_INT, &indices[0]);

    glfw::pollEvents();
    glfw::swapBuffers(window);
  }

  return 0;
}
