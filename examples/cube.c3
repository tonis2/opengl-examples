module cube;

import libc;
import glfw;
import gl;
import util;
import calgebra;

const char* VERTEX_SHADER = `
  #version 410
  layout(location = 0) in vec3 vp;
  layout(location = 1) in vec3 color;
  uniform mat4 viewProjection;

  out vec3 fcolor;
  void main () {
    gl_Position = viewProjection * vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 410
  in vec3 fcolor;
  out vec4 frag_colour;
  void main () {
    frag_colour = vec4(fcolor, 1.0);
  }
`;

float[] cube_data = {
    1.0f, 1.0f, 1.0f,       1.0f, 0.0f, 0.0f, // vertex 0
   -1.0f, 1.0f, 1.0f,       1.0f, 0.0f, 0.0f, // vertex 1
    1.0f,-1.0f, 1.0f,       1.0f, 0.0f, 0.0f, // vertex 2
    -1.0f,-1.0f, 1.0f,       1.0f, 0.0f, 0.0f, // vertex 3

// face 1:
    1.0f, 1.0f, 1.0f,       0.0f, 1.0f, 0.0f, // vertex 0
    1.0f,-1.0f, 1.0f,       0.0f, 1.0f, 0.0f, // vertex 1
    1.0f, 1.0f,-1.0f,       0.0f, 1.0f, 0.0f, // vertex 2
    1.0f,-1.0f,-1.0f,       0.0f, 1.0f, 0.0f, // vertex 3

// face 2:
    1.0f, 1.0f, 1.0f,       0.0f, 0.0f, 1.0f, // vertex 0
    1.0f, 1.0f,-1.0f,       0.0f, 0.0f, 1.0f, // vertex 1
  -1.0f, 1.0f, 1.0f,       0.0f, 0.0f, 1.0f, // vertex 2
  -1.0f, 1.0f,-1.0f,       0.0f, 0.0f, 1.0f, // vertex 3
  
// face 3:
    1.0f, 1.0f,-1.0f,       1.0f, 1.0f, 0.0f, // vertex 0
    1.0f,-1.0f,-1.0f,       1.0f, 1.0f, 0.0f, // vertex 1
  -1.0f, 1.0f,-1.0f,       1.0f, 1.0f, 0.0f, // vertex 2
  -1.0f,-1.0f,-1.0f,       1.0f, 1.0f, 0.0f, // vertex 3

// face 4:
  -1.0f, 1.0f, 1.0f,       0.0f, 1.0f, 1.0f, // vertex 0
  -1.0f, 1.0f,-1.0f,       0.0f, 1.0f, 1.0f, // vertex 1
  -1.0f,-1.0f, 1.0f,       0.0f, 1.0f, 1.0f, // vertex 2
  -1.0f,-1.0f,-1.0f,       0.0f, 1.0f, 1.0f, // vertex 3

// face 5:
    1.0f,-1.0f, 1.0f,       1.0f, 0.0f, 1.0f, // vertex 0
  -1.0f,-1.0f, 1.0f,       1.0f, 0.0f, 1.0f, // vertex 1
    1.0f,-1.0f,-1.0f,       1.0f, 0.0f, 1.0f, // vertex 2
  -1.0f,-1.0f,-1.0f,       1.0f, 0.0f, 1.0f, // vertex 3
};

uint [] indices = {
    // face 0:
    0,1,2,      // first triangle
    2,1,3,      // second triangle
    // face 1:
    4,5,6,      // first triangle
    6,5,7,      // second triangle
    // face 2:
    8,9,10,     // first triangle
    10,9,11,    // second triangle
    // face 3:
    12,13,14,   // first triangle
    14,13,15,   // second triangle
    // face 4:
    16,17,18,   // first triangle
    18,17,19,   // second triangle
    // face 5:
    20,21,22,   // first triangle
    22,21,23,  
};

fn int main()   
{
  const int WIDTH = 1280;
  const int HEIGHT = 720;
  char* renderer;
  char* version;

  glfw::init();
  glfw::windowHint(glfw::CONTEXT_VERSION_MAJOR, 3);
  glfw::windowHint(glfw::CONTEXT_VERSION_MINOR, 2);
  glfw::windowHint(glfw::OPENGL_PROFILE, glfw::OPENGL_CORE_PROFILE);
  glfw::windowHint(glfw::OPENGL_FORWARD_COMPAT, 1);
  glfw::WindowRef window = glfw::createWindow(WIDTH, HEIGHT, "GLFW OpenGL", null, null);

  if (window == null)
  {
        libc::printf("Failed to init gl window");
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

  libc::printf( "Renderer: %s\n", renderer );
  libc::printf( "OpenGL version supported %s\n", version );

  gl::enable( gl::GL_DEPTH_TEST );
  gl::depthFunc( gl::GL_LESS );

  int cube_size = cube_data.len * float.sizeof;
  int indices_size = indices.len * float.sizeof;

  uint vertexBuffer;
  uint indexBuffer;
  uint vao;
  uint ibo;

  gl::genBuffers( 1, &vertexBuffer );
  gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
  gl::bufferData(gl::GL_ARRAY_BUFFER, cube_size, cube_data, gl::GL_STATIC_DRAW);


  gl::genBuffers(1, &indexBuffer );
  gl::bindBuffer(gl::GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
  gl::bufferData(gl::GL_ELEMENT_ARRAY_BUFFER, indices_size, indices, gl::GL_STATIC_DRAW);
  

  gl::genVertexArrays( 1, &vao );
  gl::bindVertexArray( vao );
  gl::enableVertexAttribArray( 0 );
  gl::vertexAttribPointer( 0, 3, gl::GL_FLOAT, false, 0, null );
  
  gl::enableVertexAttribArray( 1 );
  gl::vertexAttribPointer( 1, 3, gl::GL_FLOAT, false, 0, null );

  defer {
    gl::deleteBuffers(1, &vertexBuffer);
    gl::deleteBuffers(1, &vao);
  }

  uint! vertex_shader = util::create_shader(gl::GL_VERTEX_SHADER, &VERTEX_SHADER);
  uint! fragment_shader = util::create_shader(gl::GL_FRAGMENT_SHADER, &FRAGMENT_SHADER);
  uint shader_program = gl::createProgram();

  if (catch err = vertex_shader) {
    libc::printf("Error was %s\n", err); 
    return 1;
  }
 
  gl::attachShader(shader_program, vertex_shader);
  gl::attachShader(shader_program, fragment_shader);
  gl::linkProgram(shader_program);
  gl::useProgram(shader_program);

  defer {
    gl::detachShader(shader_program, vertex_shader);	
    gl::detachShader(shader_program, fragment_shader);
    gl::deleteShader(vertex_shader);
    gl::deleteShader(fragment_shader);
    gl::deleteProgram(shader_program);
  }

  Mat4x4 projection = calgebra::mat4::perspective(90, 1.3, 0.1, 100);
  Mat4x4 view = calgebra::mat4::fromTranslate(Vec3 {0.0, 0.0, -5.0 });
  
  view.rotate(90.0, Vec3 {1.0, 1.0, 1.0 });

  Mat4x4 viewPtr = calgebra::mat4::mul(projection, view);

  // Add uniform matrix to shader
  uint uniform_mvp = gl::getUniformLocation(shader_program, "viewProjection");
  gl::uniformMatrix4fv(uniform_mvp, 1, false, (float*)&viewPtr.data[0][0]); 

  gl::enable(gl::GL_DEPTH_TEST);
  gl::depthFunc(gl::GL_LESS);

  while(!glfw::windowShouldClose(window)) {
    gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
    gl::useProgram( shader_program );
    gl::drawArrays( gl::GL_TRIANGLES, 0, 3 );

    glfw::pollEvents();
    glfw::swapBuffers(window);
  }

  return 0;
}