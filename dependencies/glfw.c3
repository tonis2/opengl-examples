module glfw;

typedef WindowRef = void*;
typedef Monitoref = void*;
typedef GLproc = void*;

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

fn void init() @extern("glfwInit");
fn void windowHint(int, int) @extern("glfwWindowHint");
fn void pollEvents() @extern("glfwPollEvents");
fn void swapBuffers(WindowRef window) @extern("glfwSwapBuffers");
fn void destroyWindow(WindowRef window) @extern("glfwDestroyWindow");
fn void makeContextCurrent(WindowRef window) @extern("glfwMakeContextCurrent");
fn void getFramebufferSize(WindowRef window, int*, int*) @extern("glfwGetFramebufferSize");
fn double getTime() @extern("glfwGetTime");

fn void terminate() @extern("glfwTerminate");

fn GLproc getProcAddress(char*) @extern("glfwGetProcAddress");
fn bool windowShouldClose(WindowRef window) @extern("glfwWindowShouldClose");
fn Monitoref createWindow(int, int, char*, Monitoref, WindowRef) @extern("glfwCreateWindow");
