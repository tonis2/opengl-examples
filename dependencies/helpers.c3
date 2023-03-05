module helpers;

import gl;
import std::io;
import std::math;


macro Matrix4f identity_4x4() => { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };
macro tan(x) => $$sin(x) / $$cos(x);

fn float toRadians(float value) {
    return value * (float)math::PI / 180;
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
        io::printf("shader failed with error message %s \n", infoLog);
        return FileError.FAILED!;
	} else {
        return shader;
    }
}

fault FileError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    FAILED
}  
 