# Platform support  

## Official matrix

| Runtime | Windows | Linux | macOS |
|---------|---------|-------|-------|
| PureBasic VM (`Vyrn.exe`, official CLI / `run_tests` asm backend) | **Official.** Built with PureBasic 6.41. | No official build or CI. The PB sources have a few `#PB_OS_Windows` branches (HTTP, timezone, `os.execute` shell), but they are not a supported product. | Not supported. |
| `libvyrnrt` (C99, `vyrnrt_smoke` / `compile_suite`) | Official (MSVC is the Windows gate). | **Official CI** (`test-libvyrnrt-linux` on `debian:bookworm-slim`, gcc/cmake). | CMake `UNIX` would theoretically configure and compile; **untested, no CI job.** Do not ship or promise it. |
| Windows PB `Vyrn.dll` + C# binding (`bindings/csharp`) | Official (win-x64 P/Invoke of `Vyrn.dll`). | Absent. | Absent. |
| IDE | Official (Windows / PureBasic). | Absent. | Absent. |
| `VyrnHost` (C, `native/host`) | Official. | Builds with CMake (same tree as libvyrnrt). | Same as libvyrnrt: untested. |
| Compile to `.vyrnc` / run via libvyrnrt | Yes (`--compile-vyrnc`). | Yes (Linux CI runs the compile-suite fixtures). | Untested. |
| Compile to a native exe (`--exe`) | `windows-x64` must be produced **on Windows**. | `linux-x64` must be produced **on Linux**. | No target. |

`--compile-vyrnc` and the C runtime are the portable way to run Vyrn on Linux. The official Windows CLI is the PureBasic VM (asm backend) or libvyrnrt (C backend / `VyrnHost`).  
