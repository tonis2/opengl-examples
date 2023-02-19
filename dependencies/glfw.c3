module glfw;

define WindowRef = void*;
define Monitoref = void*;
define GLproc = void*;

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

fn void init() @extname("glfwInit");
fn void windowHint(int, int) @extname("glfwWindowHint");
fn void pollEvents() @extname("glfwPollEvents");
fn void swapBuffers(WindowRef window) @extname("glfwSwapBuffers");
fn void destroyWindow(WindowRef window) @extname("glfwDestroyWindow");
fn void makeContextCurrent(WindowRef window) @extname("glfwMakeContextCurrent");
fn void getFramebufferSize(WindowRef window, int*, int*) @extname("glfwGetFramebufferSize");
fn double getTime() @extname("glfwGetTime");

fn void terminate() @extname("glfwTerminate");

fn GLproc getProcAddress(char*) @extname("glfwGetProcAddress");
fn bool windowShouldClose(WindowRef window) @extname("glfwWindowShouldClose");
fn Monitoref createWindow(int, int, char*, Monitoref, WindowRef) @extname("glfwCreateWindow");


