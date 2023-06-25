
module camera;
import std::math;
import std::io;

fn float radians(float value) {
    return value * (float)math::PI / 180;
}

struct Camera {
    Vec3f eye;
    Vec3f focus;
    float zoom;
    float aspect;
    float yaw;
    float pitch;
    float min_zoom;
    float max_zoom;
}

fn Camera new(Vec3f focus, float zoom, float aspect) {
    Camera camera = {
        {0, 0, zoom},
        focus,
        zoom,
        aspect,
        -90.0,
        50.0,
        0.1,
        100.0,
    };

    camera.eye_offset();
    return camera;
}

fn void Camera.eye_offset(Camera* self) {
    float horizontal_distance = self.zoom * math::cos(radians(self.pitch));
    float vertical_distance = self.zoom * math::sin(radians(self.pitch));

    self.eye = {
        self.focus.x - horizontal_distance * math::sin(radians(self.yaw)),
        self.focus.y + vertical_distance,
        self.focus.z - horizontal_distance * math::cos(radians(self.yaw)),
    };
}