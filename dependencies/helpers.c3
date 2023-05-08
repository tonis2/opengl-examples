module helpers;

import gl;
import std::io;
import std::math;


macro Matrix4f identity_4x4() => { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 };

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
        return FileError.FAILED?;
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


fn Matrix4f Quaternion.quaternionToMatrix(Quaternion* q)
{
    Matrix4f result = identity_4x4(); // MatrixIdentity()

    // float a2 = q.x*q.x;
    // float b2 = q.y*q.y;
    // float c2 = q.z*q.z;
    // float ac = q.x*q.z;
    // float ab = q.x*q.y;
    // float bc = q.y*q.z;
    // float ad = q.w*q.x;
    // float bd = q.w*q.y;
    // float cd = q.w*q.z;

    // result.m0 = 1 - 2*(b2 + c2);
    // result.m1 = 2*(ab + cd);
    // result.m2 = 2*(ac - bd);

    // result.m4 = 2*(ab - cd);
    // result.m5 = 1 - 2*(a2 + c2);
    // result.m6 = 2*(bc + ad);

    // result.m8 = 2*(ac + bd);
    // result.m9 = 2*(bc - ad);
    // result.m10 = 1 - 2*(a2 + b2);

   return result;
}
