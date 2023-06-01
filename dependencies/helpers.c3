module helpers;
import gl;
import std::io;
import std::math;

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

fn Matrix4f perspective(float fov, float aspect_ratio, float near, float far)
{
	float f = (float)math::tan(math::PI * 0.5 - 0.5 * fov);
	float rangeInv = (float)1.0 / (near - far);
	
    return Matrix4f {
        f / aspect_ratio, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (near + far) * rangeInv, -1,
        0, 0, near * far * rangeInv * 2, 0,
    };
}


fn Matrix4f perspective2(float fov, float aspect_ratio, float near, float far)
{
    
	float f =  1 / (float)math::tan(fov * 0.5);
	float rangeInv = (float)1.0 / (near - far);
	
    return Matrix4f {
        f / aspect_ratio, 0, 0, 0,
        0, f, 0, 0,
        0, 0, (near + far) / (near - far), -1,
        0, 0, 2 * far * near / (near - far), 0,
    };
}

fn Matrix4f lookAt(Vec3f eye, Vec3f target, Vec3f up)
{
    Vec3f vz = (eye - target).normalize();
	Vec3f vx = up.cross(vz).normalize();
	Vec3f vy = vz.cross(vx);

	return Matrix4f {
		vx[0], vy[0], vz[0], 0,
		vx[1], vy[1], vz[1], 0,
		vx[2], vy[2], vz[2], 0,
		- vx.dot(eye), - vy.dot(eye), - vz.dot(eye), 1
	};
}
