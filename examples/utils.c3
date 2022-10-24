module util;

import gl;
import std;
import libc;

fault ShaderError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    FAILED
}   

fn uint! create_shader(int shadertype, char** resources) {
  int shader = gl::createShader( shadertype );
  gl::shaderSource( shader, 1, resources, null );
  gl::compileShader( shader );

  int success;
  char[512] infoLog;
  gl::getShaderiv(shader, gl::GL_COMPILE_STATUS, &success);

  if (!success) {
		gl::getShaderInfoLog(shader, 512, null, &infoLog);
        libc::printf("error message %s \n", infoLog);
        return ShaderError.FAILED!;
	} else {
        return shader;
    }
}