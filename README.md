# ztrace
Toy raytracer written in [Zig](https://ziglang.org) 0.11, inspired by [_Ray Tracing in One Weekend_](https://raytracing.github.io/books/RayTracingInOneWeekend.html)

![example/scene.png](https://github.com/theantagonist9509/ztrace/blob/main/example/scene.png)

## Features
* Interprets scene to be rendered through specified JSON file
* Can render uniformly-colored spheres, infinite planes, triangles, and binary STL models
* Supports linear mixing of specular and diffuse (Lambertian) reflection through `shininess` attribute
* Supports multithreading

## Build Instructions
ztrace has no dependencies; the Zig 0.11 compiler is all you need.

Simply run `zig build` to build the executable.

## JSON Specification

https://github.com/theantagonist9509/ztrace/blob/edadaa0d9c3803945eb31464f7ba92ae4379fe37/src/world.zig#L27-L63
