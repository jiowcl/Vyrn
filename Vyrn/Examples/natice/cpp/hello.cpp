/**
 * @file hello.cpp
 * @brief Minimal C++ host implementation for Vyrn.dll/LibVyrn.dll.
 *
 * Demonstrates the basic setup required to load and execute Vyrn.dll
 * with minimal boilerplate code.
 *
 * @note Build & Run Instructions:
 * - Build Native DLL:
 *     .\scripts\build_native.ps1
 *
 * - Build & Run Host Executable (from repo root via VS Developer Prompt):
 *     cl /EHsc /I include examples\native\cpp\hello.cpp /link /LIBPATH:native
 *     examples\native\cpp\hello.exe
 *
 * - Runtime Dependency:
 *     Ensure Vyrn.dll is located on your PATH or in the same directory as the executable.
 *
 * @tip Alternative Choice:
 * Use the C# example if you do not have a C++ toolchain configured.
 */

#include <cstdio>
#include <cstring>

#define VYRN_STATIC
#include "../../../Native/include/vyrn.h"

#ifdef _WIN32
#  include <windows.h>
static void *LoadVyrn(const char *path) {
  return (void *)LoadLibraryA(path);
}
#  define LOAD(sym) GetProcAddress((HMODULE)lib, sym)
#else
#  error "This smoke sample is Windows-oriented; use vyrn.h + dlopen on other hosts."
#endif

typedef int (*fn_abi)(void);
typedef VyrnVM *(*fn_create)(void);
typedef void (*fn_destroy)(VyrnVM *);
typedef int (*fn_run_file)(VyrnVM *, const char *);
typedef int (*fn_call)(VyrnVM *, const char *, const VyrnValue *, int, VyrnValue *);
typedef int (*fn_reg)(VyrnVM *, const char *, VyrnHostFn, void *);
typedef const char *(*fn_err)(VyrnVM *);

/**
 * @brief Host scale function.
 * @param userdata User data (unused).
 * @param args The arguments to the function.
 * @param argc The number of arguments.
 * @param out The output value.
 * @return The number of output values.
 */
static int HostScale(void * /*userdata*/, const VyrnValue *args, int argc, VyrnValue *out) {
  double dt = (argc >= 1 && args[0].type == VYRN_TYPE_NUMBER) ? args[0].number : 0.0;
  out->type = VYRN_TYPE_NUMBER;
  out->bool_val = 0;
  out->number = dt * 10.0;
  out->str = nullptr;
  return 1;
}

/**
 * @brief Main function.
 * @param argc The number of arguments.
 * @param argv The arguments.
 * @return The result.
 */
int main(int argc, char **argv) {
  const char *dllPath = (argc > 1) ? argv[1] : "native\\Vyrn.dll";
  void *lib = LoadVyrn(dllPath);
  if (!lib) {
    std::fprintf(stderr, "[error] LoadLibrary %s failed\n", dllPath);
    return 1;
  }

  auto abi = (fn_abi)LOAD("vyrn_abi_version");
  auto create = (fn_create)LOAD("vyrn_create");
  auto destroy = (fn_destroy)LOAD("vyrn_destroy");
  auto run_file = (fn_run_file)LOAD("vyrn_run_file");
  auto call_global = (fn_call)LOAD("vyrn_call_global");
  auto reg = (fn_reg)LOAD("vyrn_register");
  auto last_error = (fn_err)LOAD("vyrn_last_error");
  if (!abi || !create || !destroy || !run_file || !call_global || !reg || !last_error) {
    std::fprintf(stderr, "[error] missing export\n");
    return 1;
  }

  std::printf("abi=%d\n", abi());
  if (abi() < 3) {
    std::fprintf(stderr, "[error] need ABI >= 3\n");
    return 1;
  }
  VyrnVM *vm = create();
  if (!vm) {
    std::fprintf(stderr, "[error] create failed\n");
    return 1;
  }

  if (!reg(vm, "host_scale", HostScale, nullptr)) {
    std::fprintf(stderr, "[error] register: %s\n", last_error(vm));
    destroy(vm);
    return 1;
  }

  const char *script = (argc > 2) ? argv[2] : "examples\\native\\hello.vyrn";
  if (!run_file(vm, script)) {
    std::fprintf(stderr, "[error] run_file: %s\n", last_error(vm));
    destroy(vm);
    return 1;
  }

  VyrnValue args2[2] = {};
  args2[0].type = VYRN_TYPE_NUMBER;
  args2[0].number = 2;
  args2[1].type = VYRN_TYPE_NUMBER;
  args2[1].number = 3;
  VyrnValue out = {};
  if (!call_global(vm, "add", args2, 2, &out)) {
    std::fprintf(stderr, "[error] add: %s\n", last_error(vm));
    destroy(vm);
    return 1;
  }
  std::printf("add=%g\n", out.number);

  VyrnValue tickArg = {};
  tickArg.type = VYRN_TYPE_NUMBER;
  tickArg.number = 0.5;
  if (!call_global(vm, "on_tick", &tickArg, 1, &out)) {
    std::fprintf(stderr, "[error] on_tick: %s\n", last_error(vm));
    destroy(vm);
    return 1;
  }
  std::printf("on_tick=%g\n", out.number);

  destroy(vm);
  return 0;
}
