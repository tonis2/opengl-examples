module glfw;

def WindowRef = void*;
def Monitoref = void*;
def GLproc = void*;
def KeyCallback = fn void(WindowRef window, int key, int scancode, int action, int mods);
def MouseCallback = fn void(WindowRef window, int button, int action, int mods);

const GLFW_RELEASE = 0;
const GLFW_PRESS = 1;
const GLFW_REPEAT = 2;

const CONTEXT_VERSION_MAJOR = 0x00022002;
const CONTEXT_VERSION_MINOR = 0x00022003;
const CONTEXT_REVISION = 0x00022004;

const CONTEXT_RELEASE_BEHAVIOR = 0x00022009;
const CONTEXT_CREATION_API = 0x0002200B;
const COCOA_RETINA_FRAMEBUFFER = 0x00023001;
const COCOA_FRAME_NAME = 0x00023002;

const COCOA_GRAPHICS_SWITCHING = 0x00023003;
const X11_CLASS_NAME = 0x00024001;
const X11_INSTANCE_NAME = 0x00024002;

const OPENGL_PROFILE = 0x00022008;
const OPENGL_CORE_PROFILE = 0x00032001;
const OPENGL_COMPAT_PROFILE = 0x00032002;
const OPENGL_FORWARD_COMPAT = 0x00022006;



extern fn void init() @extern("glfwInit");
extern fn void windowHint(int, int) @extern("glfwWindowHint");
extern fn void pollEvents() @extern("glfwPollEvents");
extern fn void swapBuffers(WindowRef window) @extern("glfwSwapBuffers");
extern fn void destroyWindow(WindowRef window) @extern("glfwDestroyWindow");
extern fn void makeContextCurrent(WindowRef window) @extern("glfwMakeContextCurrent");
extern fn void getFramebufferSize(WindowRef window, int*, int*) @extern("glfwGetFramebufferSize");
extern fn double getTime() @extern("glfwGetTime");
extern fn void terminate() @extern("glfwTerminate");

extern fn GLproc getProcAddress(char*) @extern("glfwGetProcAddress");
extern fn bool windowShouldClose(WindowRef window) @extern("glfwWindowShouldClose");
extern fn bool getCursorPos(WindowRef window, double* x_pos, double* y_pos) @extern("glfwGetCursorPos");
extern fn void setKeyCallback(WindowRef window, KeyCallback* callback) @extern("glfwSetKeyCallback");
extern fn void setMouseButtonCallback(WindowRef window, MouseCallback* callback) @extern("glfwSetMouseButtonCallback");
extern fn Monitoref createWindow(int, int, char*, Monitoref, WindowRef) @extern("glfwCreateWindow");
