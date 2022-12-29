module stb;
import libc;

enum Channel : int 
{
  STBI_DEFAULT,
  STBI_GREY,
  STBI_GREY_ALPHA,
  STBI_RGB,
  STBI_RGB_ALPHA
}

fn char* stbi_load(char*, uint*, uint*, uint*, uint) @extname("stbi_load");
fn void* stbi_image_free(char*) @extname("stbi_image_free");

fault FileError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    FAILED
}   

struct Image
{
    char* pixels;
    uint height;
    uint width;
    uint size;
    uint channels;
}

fn void Image.free(Image* self) {
    stbi_image_free(self.pixels); 
}

fn Image! loadImage(char* file_path, Channel channel) {
  Image data;  

  uint error;

  data.pixels = stbi_load(file_path, &data.width, &data.height, &data.channels, channel);

  if(data.pixels == null) {
     libc::printf("Image loading failed \n");
     return FileError.FILE_NOT_FOUND!;
  } 

  return data;
}