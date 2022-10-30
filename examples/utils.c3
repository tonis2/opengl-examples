module util;

import gl;
import std;
import libc;
import calgebra;

struct Color
{
    float r;
    float g;
    float b;
}


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

fn void printMat(Mat4x4 matrix) {
    libc::printf("\n ------------ \n");
    foreach (column, value: matrix.data) 
    {
        foreach (row, value2: matrix.data[column]) { 
            // For debugging
            libc::printf("Col: %d, Row: %d, value %f\n", column + 1, row + 1, matrix.data[column][row]);
        }
    }
    libc::printf("\n ------------ \n");
}