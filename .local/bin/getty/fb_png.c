#include <errno.h>
#include <fcntl.h>
#include <limits.h>
#include <linux/fb.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/types.h>

#pragma comment(lib, "png")
#include <libpng16/png.h>

typedef struct {
  uint32_t *pixels;
  size_t width;
  size_t height;
  size_t stride;
} Canvas;

#define SHIFT(argc, argv)      ((argc)--, *(argv)++)
#define CANVAS_PIXEL(oc, x, y) (oc).pixels[(y)*(oc).stride + (x)]
#define PIXEL_BLUE(color)      (((color)&0x000000FF)>>(8*0))
#define PIXEL_GREEN(color)     (((color)&0x0000FF00)>>(8*1))
#define PIXEL_RED(color)       (((color)&0x00FF0000)>>(8*2))
#define PIXEL_ALPHA(color)     (((color)&0xFF000000)>>(8*3))
#define PIXEL_RGBA(r, g, b, a) ((((b)&0xFF)<<(8*0)) | (((g)&0xFF)<<(8*1)) | (((r)&0xFF)<<(8*2)) | (((a)&0xFF)<<(8*3)))

Canvas canvas_from_fb(char* filename) {
  int fdScreen = open(filename, O_RDWR);
  if (fdScreen < 0) {
    fprintf(stderr, "fb_olivec: can't open '%s': %s\n", filename, strerror(errno));
    exit(1);
  }

  struct fb_var_screeninfo varInfo;
  int err = ioctl(fdScreen, FBIOGET_VSCREENINFO, &varInfo);
  if (err) {
    fprintf(stderr, "fb_olivec: can't ioctl '%s': %s\n", filename, strerror(errno));
    exit(1);
  }
  size_t nScreenSize = varInfo.xres * varInfo.yres * varInfo.bits_per_pixel / 8;
  uint32_t* display = mmap(0, nScreenSize, PROT_READ | PROT_WRITE, MAP_SHARED, fdScreen, 0);
  if (display == MAP_FAILED) {
    fprintf(stderr, "fb_olivec: can't mmap '%s': %s\n", filename, strerror(errno));
    exit(1);
  }

  return (Canvas){display, varInfo.xres, varInfo.yres, varInfo.xres};
}

Canvas canvas_in_ram(int width, int height) {
  return (Canvas){calloc(4, width*height), width, height, width};
}

void free_fb_canvas(Canvas* oc) {
  munmap(oc->pixels, oc->height*oc->width*4);
  oc->pixels = NULL;
}

void free_image_canvas(Canvas* oc) {
  free(oc->pixels);
  oc->pixels = NULL;
}

Canvas read_png(char* filename) {
  png_image image = {0};
  image.version = PNG_IMAGE_VERSION;
  if (!png_image_begin_read_from_file(&image, filename)) {
    fprintf(stderr, "libpng: couldn't read %s: %s\n", filename, image.message);
    exit(1);
  }
  image.format = PNG_FORMAT_BGRA;

  int stride = image.width*4;
  uint32_t* pixels = malloc(stride*image.height);
  png_image_finish_read(&image, NULL, pixels, stride, NULL);

  return (Canvas){pixels, image.width, image.height, image.width};
}

// not actually linear lol
int gradient_lerp(int x, int gradient_start, int gradient_end, int gradient_min, int gradient_max) {
  int v0 = gradient_min;
  int v1 = gradient_max;
  if (x < gradient_start) return v0;
  if (x >= gradient_end) return v1;

  // funny int arithmetic let's goo~
  int d = v1 - v0;
  int t = (x - gradient_start) * d / (gradient_end - gradient_start);
  t = t*t*(3*d - 2*t) / d / d;
  return v0 + t;
}

inline int dither(int x, int t, int strength) {
  if (strength == 0) return x*t / 255;

  int random = 255*(strength/2) - (rand()%(255*strength));
  int res = (x * t * t / 255 + random) / 255;
  if (res < 0) res = 0;
  if (res > 255) res = 255;
  return res;
}

void copy_sprite(Canvas oc, int gradient_start, int gradient_end, int dither_strength, Canvas sprite) {
  for (size_t y = 0; y < oc.height; y++) {
    for (size_t x = gradient_start; x < oc.width; x++) {
      size_t nx = x*((int) sprite.width)/oc.width;
      size_t ny = y*((int) sprite.height)/oc.height;

      int t = gradient_lerp(x, gradient_start, gradient_end, 0, 255);
      if (t == 0) {
        continue;
      } else if (t == 255) {
        CANVAS_PIXEL(oc, x, y) = CANVAS_PIXEL(sprite, nx, ny);
        continue;
      } else if(CANVAS_PIXEL(oc, x, y)) {
        continue;
      }

      uint32_t pixel = CANVAS_PIXEL(sprite, nx, ny);
      uint8_t r = dither(PIXEL_RED(pixel), t, dither_strength);
      uint8_t g = dither(PIXEL_GREEN(pixel), t, dither_strength);
      uint8_t b = dither(PIXEL_BLUE(pixel), t, dither_strength);
      CANVAS_PIXEL(oc, x, y) = PIXEL_RGBA(r, g, b, 255);
    }
  }
}

void usage(char* program_name, int exit_code) {
  fprintf(stderr, "usage: %s [png path] [--gradient-start num] [--gradient-end num] [--dither 1]\n", program_name);
  exit(exit_code);
}

void need_extra_arg(char* program_name, int argc, char* arg) {
  if (argc == 0) {
    fprintf(stderr, "%s: %s needs an extra arg\n", program_name, arg);
    usage(program_name, 1);
  }
}

int main(int argc, char** argv) {
  char* program_name = SHIFT(argc, argv);
  char* image_path = NULL;
  int gradient_start = 0;
  int gradient_end = 0;
  int dither_strength = 0;
  while (argc > 0) {
    char* arg = SHIFT(argc, argv);
    if (strcmp(arg, "--gradient-start") == 0) {
      need_extra_arg(program_name, argc, arg);
      gradient_start = atoi(SHIFT(argc, argv));
    } else if (strcmp(arg, "--gradient-end") == 0) {
      need_extra_arg(program_name, argc, arg);
      gradient_end = atoi(SHIFT(argc, argv));
    } else if (strcmp(arg, "--dither") == 0) {
      need_extra_arg(program_name, argc, arg);
      dither_strength = atoi(SHIFT(argc, argv));
    } else if (strcmp(arg, "--help") == 0) {
      usage(program_name, 0);
    } else if (arg[0] != '-' && image_path == NULL) {
      image_path = arg;
    } else {
      fprintf(stderr, "%s: illegal argument '%s'\n", program_name, arg);
      usage(program_name, 1);
    }
  }
  if (image_path == NULL) image_path = "/home/green/.config/wall.png";

  Canvas image = read_png(image_path);
  Canvas oc = canvas_from_fb("/dev/fb0");

  if (gradient_start && !gradient_end) gradient_end = oc.width;
  copy_sprite(oc, gradient_start, gradient_end, dither_strength, image);

  free_image_canvas(&image);
  free_fb_canvas(&oc);
  return 0;
}
