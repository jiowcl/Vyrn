/**
 * @file vyrn_host.c
 * @brief Generic Standalone host for Vyrn.Standalone packages (C ABI via Vyrn.dll).
 *
 * Replaces the PureBasic VyrnHost.pb for end users: build with CMake / MSVC / MinGW,
 * no PureBasic install required. Loads Vyrn.dll from the executable directory and
 * runs a Standalone payload: argv[1], else the only *.vyrnc beside the exe
 * (compiled VYBX bytecode, the default package since 1.6.73), else the only
 * *.bundle.vyrn (readable source, `standalone --ship-source`).
 *
 * Build (from repo root):
 *   .\scripts\build_vyrn_host.ps1
 *   — or —
 *   cmake -S native/host -B native/host/build && cmake --build native/host/build --config Release
 *
 * Usage (from a ship folder that already has Vyrn.dll + payload):
 *   VyrnHost.exe hello.vyrnc
 *   VyrnHost.exe hello.bundle.vyrn
 *   VyrnHost.exe          ; auto-picks a single *.vyrnc, else a single *.bundle.vyrn
 *
 * Author: Ji-Feng Tsai (jiowcl@gmail.com)
 */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define VYRN_STATIC
#include "../include/vyrn.h"

#ifdef _WIN32
#  include <windows.h>
#else
#  include <dlfcn.h>
#  include <dirent.h>
#  include <limits.h>
#  include <unistd.h>
#endif

/*
 * Diagnostics mirror the PB CLI / PB VyrnHost.pb: "[error] ..." lines go to
 * stdout (PrintN), exit code 1. Flush so they stay ordered after script output
 * written by Vyrn.dll through the same console/pipe.
 */
static void host_out(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stdout, fmt, ap);
  va_end(ap);
  fflush(stdout);
}

typedef int (*fn_abi)(void);
typedef const char *(*fn_version)(void);
typedef VyrnVM *(*fn_create)(void);
typedef void (*fn_destroy)(VyrnVM *);
typedef int (*fn_run_file)(VyrnVM *, const char *);
typedef const char *(*fn_err)(VyrnVM *);
typedef int (*fn_set_caps)(VyrnVM *, unsigned int);
typedef int (*fn_set_allowlist)(VyrnVM *, const char *);

/** Vyrn API structure */
typedef struct VyrnApi {
  void *lib;
  fn_abi abi;
  fn_version version;
  fn_create create;
  fn_destroy destroy;
  fn_run_file run_file;
  fn_err last_error;
  fn_set_caps set_capabilities; /* ABI 8+; may be NULL */
  fn_set_allowlist set_net_allowlist; /* ABI 9+; may be NULL */
} VyrnApi;

#ifdef _WIN32
/** 
  @brief Get the directory of the host executable. 
  @param buf The buffer to store the directory.
  @param buflen The length of the buffer.
*/
static void host_exe_dir(char *buf, size_t buflen)
{
  DWORD n;
  char *slash;
  if (!buf || buflen < 4) {
    return;
  }
  n = GetModuleFileNameA(NULL, buf, (DWORD)buflen);
  if (n == 0 || n >= buflen) {
    buf[0] = '\0';
    return;
  }
  slash = strrchr(buf, '\\');
  if (!slash) {
    slash = strrchr(buf, '/');
  }
  if (slash) {
    slash[1] = '\0';
  } else {
    buf[0] = '.';
    buf[1] = '\\';
    buf[2] = '\0';
  }
}

/** 
  @brief Load a library.
  @param path The path to the library.
  @return A pointer to the library.
*/
static void *host_load_lib(const char *path)
{
  return (void *)LoadLibraryA(path);
}

/** 
  @brief Get a symbol from a library.
  @param lib The library.
  @param name The name of the symbol.
  @return A pointer to the symbol.
*/
static void *host_sym(void *lib, const char *name)
{
  return (void *)GetProcAddress((HMODULE)lib, name);
}

/** 
  @brief Close a library.
  @param lib The library.
*/
static void host_close_lib(void *lib)
{
  if (lib) {
    FreeLibrary((HMODULE)lib);
  }
}

/** 
  @brief Find the only file ending in suffix next to the host exe.
  @param exe_dir The directory of the host executable.
  @param suffix The suffix of the file.
  @return A pointer to the heap path or NULL.
*/
static char *host_find_default_bundle(const char *exe_dir, const char *suffix)
{
  char pattern[MAX_PATH];
  WIN32_FIND_DATAA fd;
  HANDLE h;
  char *found = NULL;
  int n = 0;
  size_t dirlen;

  if (!exe_dir || !exe_dir[0]) {
    return NULL;
  }
  dirlen = strlen(exe_dir);
  if (dirlen + strlen(suffix) + 2 >= sizeof(pattern)) {
    return NULL;
  }
  memcpy(pattern, exe_dir, dirlen + 1);
  strcat(pattern, "*");
  strcat(pattern, suffix);
  h = FindFirstFileA(pattern, &fd);
  if (h == INVALID_HANDLE_VALUE) {
    return NULL;
  }
  do {
    if (!(fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY)) {
      size_t need = dirlen + strlen(fd.cFileName) + 1;
      n++;
      if (n == 1) {
        found = (char *)malloc(need);
        if (found) {
          memcpy(found, exe_dir, dirlen);
          memcpy(found + dirlen, fd.cFileName, strlen(fd.cFileName) + 1);
        }
      } else {
        free(found);
        found = NULL;
        break;
      }
    }
  } while (FindNextFileA(h, &fd));
  FindClose(h);
  return found;
}
#else
/** 
  @brief Get the directory of the host executable.
  @param buf The buffer to store the directory.
  @param buflen The length of the buffer.
*/
static void host_exe_dir(char *buf, size_t buflen)
{
  ssize_t n;
  char *slash;
  if (!buf || buflen < 4) {
    return;
  }
  n = readlink("/proc/self/exe", buf, buflen - 1);
  if (n < 0) {
    buf[0] = '\0';
    return;
  }
  buf[n] = '\0';
  slash = strrchr(buf, '/');
  if (slash) {
    slash[1] = '\0';
  } else {
    strcpy(buf, "./");
  }
}

/** 
  @brief Load a library.
  @param path The path to the library.
  @return A pointer to the library.
*/
static void *host_load_lib(const char *path)
{
  return dlopen(path, RTLD_NOW);
}

/** 
  @brief Get a symbol from a library.
  @param lib The library.
  @param name The name of the symbol.
  @return A pointer to the symbol.
*/
static void *host_sym(void *lib, const char *name)
{
  return dlsym(lib, name);
}

/** 
  @brief Close a library.
  @param lib The library.
*/
static void host_close_lib(void *lib)
{
  if (lib) {
    dlclose(lib);
  }
}

/** 
  @brief Find the only file ending in suffix next to the host exe.
  @param exe_dir The directory of the host executable.
  @param suffix The suffix of the file.
  @return A pointer to the heap path or NULL.
*/
static char *host_find_default_bundle(const char *exe_dir, const char *suffix)
{
  size_t slen = strlen(suffix);
  DIR *d;
  struct dirent *ent;
  char *found = NULL;
  int n = 0;
  size_t dirlen;

  if (!exe_dir || !exe_dir[0]) {
    return NULL;
  }
  dirlen = strlen(exe_dir);
  d = opendir(exe_dir);
  if (!d) {
    return NULL;
  }
  while ((ent = readdir(d)) != NULL) {
    const char *name = ent->d_name;
    size_t len = strlen(name);
    if (len > slen && strcmp(name + len - slen, suffix) == 0) {
      size_t need = dirlen + len + 1;
      n++;
      if (n == 1) {
        found = (char *)malloc(need);
        if (found) {
          memcpy(found, exe_dir, dirlen);
          memcpy(found + dirlen, name, len + 1);
        }
      } else {
        free(found);
        found = NULL;
        break;
      }
    }
  }
  closedir(d);
  return found;
}
#endif

/** 
  @brief Load the Vyrn API.
  @param api The Vyrn API structure.
  @param dll_path The path to the library.
  @return 1 if successful, 0 otherwise.
*/
static int host_load_api(VyrnApi *api, const char *dll_path)
{
  memset(api, 0, sizeof(*api));
  api->lib = host_load_lib(dll_path);
  if (!api->lib) {
    host_out("[error] failed to load %s\n", dll_path);
    return 0;
  }
  api->abi = (fn_abi)host_sym(api->lib, "vyrn_abi_version");
  api->version = (fn_version)host_sym(api->lib, "vyrn_version");
  api->create = (fn_create)host_sym(api->lib, "vyrn_create");
  api->destroy = (fn_destroy)host_sym(api->lib, "vyrn_destroy");
  api->run_file = (fn_run_file)host_sym(api->lib, "vyrn_run_file");
  api->last_error = (fn_err)host_sym(api->lib, "vyrn_last_error");
  api->set_capabilities = (fn_set_caps)host_sym(api->lib, "vyrn_set_capabilities");
  api->set_net_allowlist = (fn_set_allowlist)host_sym(api->lib, "vyrn_set_net_allowlist");
  if (!api->abi || !api->create || !api->destroy || !api->run_file || !api->last_error) {
    host_out("[error] missing Vyrn.dll export (need ABI >= 3)\n");
    host_close_lib(api->lib);
    api->lib = NULL;
    return 0;
  }
  if (api->abi() < 3) {
    host_out("[error] Vyrn.dll ABI %d too old (need >= 3)\n", api->abi());
    host_close_lib(api->lib);
    api->lib = NULL;
    return 0;
  }
  return 1;
}

/** 
  @brief Join a directory and a name.
  @param out The buffer to store the joined path.
  @param outlen The length of the buffer.
  @param dir The directory.
  @param name The name.
*/
static void host_join(char *out, size_t outlen, const char *dir, const char *name)
{
  size_t dlen, nlen;
  if (!out || outlen < 2) {
    return;
  }
  out[0] = '\0';
  if (!dir || !name) {
    return;
  }
  dlen = strlen(dir);
  nlen = strlen(name);
  if (dlen + nlen + 1 >= outlen) {
    return;
  }
  memcpy(out, dir, dlen + 1);
  memcpy(out + dlen, name, nlen + 1);
}

/** 
  @brief Main function.
  @param argc The number of arguments.
  @param argv The arguments.
  @return 0 if successful, 1 otherwise.
*/
int main(int argc, char **argv)
{
  char exe_dir[1024];
  char dll_path[1100];
  char *script = NULL;
  int free_script = 0;
  VyrnApi api;
  VyrnVM *vm;
  int ok;

  host_exe_dir(exe_dir, sizeof(exe_dir));
  if (!exe_dir[0]) {
    host_out("[error] cannot resolve executable directory\n");
    return 1;
  }

  /* Prefer Vyrn.dll beside the host (Standalone ship layout). */
  host_join(dll_path, sizeof(dll_path), exe_dir, "Vyrn.dll");
  if (!host_load_api(&api, dll_path)) {
#ifdef _WIN32
    if (!host_load_api(&api, "Vyrn.dll")) {
      return 1;
    }
#else
    host_join(dll_path, sizeof(dll_path), exe_dir, "libVyrn.so");
    if (!host_load_api(&api, dll_path) &&
        !host_load_api(&api, "libVyrn.so") &&
        !host_load_api(&api, "Vyrn.dll")) {
      return 1;
    }
#endif
  }

  {
    int i;
    int allow_net = 0;
    const char *allow_hosts = NULL;
    for (i = 1; i < argc; ++i) {
      if (!argv[i]) continue;
      if (strcmp(argv[i], "--allow-net") == 0) {
        allow_net = 1;
        allow_hosts = NULL; /* bare = all hosts */
      } else if (strncmp(argv[i], "--allow-net=", 12) == 0) {
        allow_net = 1;
        allow_hosts = argv[i] + 12;
      } else if (!script && argv[i][0] != '-') script = argv[i];
    }
    if (!script) {
      /* Compiled payload first (default Standalone package), then readable bundle. */
      script = host_find_default_bundle(exe_dir, ".vyrnc");
      if (!script) {
        script = host_find_default_bundle(exe_dir, ".bundle.vyrn");
      }
      free_script = 1;
      if (!script) {
        host_out("[error] usage: VyrnHost.exe <script.vyrnc | script.bundle.vyrn> [--allow-net[=hosts]]\n");
        host_out("       (or place exactly one *.vyrnc or *.bundle.vyrn beside VyrnHost.exe)\n");
        host_close_lib(api.lib);
        return 1;
      }
    }

    vm = api.create();
    if (!vm) {
      host_out("[error] vyrn_create failed\n");
      if (free_script) {
        free(script);
      }
      host_close_lib(api.lib);
      return 1;
    }

    if (allow_net && api.set_capabilities) {
      api.set_capabilities(vm, VYRN_CAP_NET);
    }
    if (allow_net && allow_hosts && api.set_net_allowlist) {
      api.set_net_allowlist(vm, allow_hosts);
    }
  }

  ok = api.run_file(vm, script);
  if (!ok) {
    const char *msg = api.last_error ? api.last_error(vm) : "unknown error";
    host_out("[error] %s\n", msg ? msg : "unknown error");
    api.destroy(vm);
    if (free_script) {
      free(script);
    }
    host_close_lib(api.lib);
    return 1;
  }

  api.destroy(vm);
  if (free_script) {
    free(script);
  }
  host_close_lib(api.lib);
  return 0;
}
