![](sample.png)

# Simple raytracer in Zig

A basic implementation of [Ray Tracing in One Weekend](https://raytracing.github.io/books/RayTracingInOneWeekend.html) by Peter Shirley in Zig

I wrote it in C++, C, Rust, Go and Zig as a learning exercise and to compare the languages.

## Dependencies

Zig compiler version 0.14.0 and up.

I tested it with 0.14.0-dev.218+b3b923e51

## Compile and Run

```sh
zig build
```

Run

```sh
time ./zig-out/bin/raytracer-in-zig simple > test.ppm
```
