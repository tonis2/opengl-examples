module png;

import libc;

fn uint lodepng_decode32_file(char** image, uint width, uint height, char* filename) @extname("lodepng_decode32_file");
fn uint lodepng_load_file(char** image, uint* outsize, char* filename) @extname("lodepng_load_file");
fn uint lodepng_decode32(char** image, uint* width, uint* height, char* file, uint size) @extname("lodepng_decode32");
fn char* lodepng_error_text(uint error_id) @extname("lodepng_error_text");

fault FileError
{
    FILE_NOT_FOUND,
    FILE_NOT_READABLE,
    FAILED
}   

struct Png
{
    char* pixels;
    uint height;
    uint width;
    uint size;
}

fn void Png.free(Png* self) {
    mem::free(self.pixels);
}

fn Png! loadPNG(char* file_path) {
  Png data;  

  uint error;
  char* file;

  error = lodepng_load_file(&file, &data.size, file_path);
  defer mem::free(file);

  if(error) {
     libc::printf("PNG loading failed %s\n", lodepng_error_text(error));
     return FileError.FILE_NOT_FOUND!;
  } 

  data.pixels = malloc(data.size);
  error = lodepng_decode32(&data.pixels, &data.width, &data.height, file, data.size);

  if(error) {
     libc::printf("PNG parsing error %s \n", lodepng_error_text(error));
     return FileError.FAILED!;
  }

  return data;
}