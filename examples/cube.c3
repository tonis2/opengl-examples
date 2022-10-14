import libc;
import glfw;
import gl;
import util;

const char* VERTEX_SHADER = `
  #version 410
  in vec3 vp;
  void main () {
    gl_Position = vec4(vp, 1.0);
  }
`;

const char* FRAGMENT_SHADER = `
  #version 410
  out vec4 frag_colour;
  void main () {
    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
  }
`;

float[] cube_data = {
    -0.5, -0.5, 0.0,
     0.5, -0.5, 0.0,
     0.0,  0.5, 0.0
};

float [] indices = {
  0, 1, 3,
	1, 2, 3	
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

  uint vertexBuffer;
  uint vao;

  gl::genBuffers( 1, &vertexBuffer );
  gl::bindBuffer(gl::GL_ARRAY_BUFFER, vertexBuffer);
  gl::bufferData(gl::GL_ARRAY_BUFFER, cube_size, cube_data, gl::GL_STATIC_DRAW);

  gl::genVertexArrays( 1, &vao );
  gl::bindVertexArray( vao );
  gl::enableVertexAttribArray( 0 );
  gl::vertexAttribPointer( 0, 3, gl::GL_FLOAT, false, 0, null );

  defer {
    gl::deleteBuffers(1, &vertexBuffer);
    gl::deleteBuffers(1, &vao);
  }

  uint! vertex_shader = util::create_shader(gl::GL_VERTEX_SHADER, &VERTEX_SHADER);
  uint! fragment_shader = util::create_shader(gl::GL_FRAGMENT_SHADER, &FRAGMENT_SHADER);
  uint shader_programme = gl::createProgram();

  if (catch err = vertex_shader) {
    libc::printf("Error was %s\n", err); 
    return 1;
  }
 
  gl::attachShader(shader_programme, vertex_shader);
  gl::attachShader(shader_programme, fragment_shader);
  gl::linkProgram(shader_programme);
  gl::useProgram(shader_programme);

  gl::enable(gl::GL_DEPTH_TEST);
  gl::depthFunc(gl::GL_LESS);

  while(!glfw::windowShouldClose(window)) {
    gl::clear( gl::GL_COLOR_BUFFER_BIT | gl::GL_DEPTH_BUFFER_BIT );
    gl::useProgram( shader_programme );
    gl::drawArrays( gl::GL_TRIANGLES, 0, 3 );

    glfw::pollEvents();
    glfw::swapBuffers(window);
  }

  return 0;
}