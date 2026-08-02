/**
 * @file demo.cpp
 * @brief Full C++ host implementation for Vyrn.dll/LibVyrn.dll (ABI 3).
 *
 * Demonstrates the following host capabilities:
 * - Multi-return values
 * - Globals & table access
 * - Print logger integration
 * - Coroutine support
 * - Error code handling
 * - String copying via `vyrn_copy_string`
 *
 * @note Build & Run Instructions:
 * - Build Native DLL:
 *     .\scripts\build_native.ps1
 *
 * - Build & Run Host Executable (from repo root via VS Developer Prompt or Clang):
 *     cl /EHsc /std:c++17 /I include examples\native\cpp\demo.cpp /Fe:examples\native\cpp\demo.exe
 *     examples\native\cpp\demo.exe
 */

#include <cstdio>
#include <cstring>
#include <string>
#include <vector>

#define VYRN_STATIC
#include "../../../Native/include/vyrn.h"

#ifdef _WIN32
#  include <windows.h>
static void *LoadVyrn(const char *path) {
  return (void *)LoadLibraryA(path);
}
#  define LOAD(sym) GetProcAddress((HMODULE)lib, #sym)
#else
#  error "Windows x64 sample; use vyrn.h + dlopen elsewhere."
#endif

typedef int (*fn_abi)(void);
typedef VyrnVM *(*fn_create)(void);
typedef void (*fn_destroy)(VyrnVM *);
typedef int (*fn_set_limits)(VyrnVM *, int, int, int);
typedef int (*fn_set_logger)(VyrnVM *, VyrnLogFn, void *);
typedef int (*fn_run_file)(VyrnVM *, const char *);
typedef int (*fn_call)(VyrnVM *, const char *, const VyrnValue *, int, VyrnValue *);
typedef int (*fn_call_multi)(VyrnVM *, const char *, const VyrnValue *, int, VyrnValue *, int, int32_t *);
typedef int (*fn_get_global)(VyrnVM *, const char *, VyrnValue *);
typedef int (*fn_table_get)(VyrnVM *, int, const VyrnValue *, VyrnValue *);
typedef int (*fn_table_set)(VyrnVM *, int, const VyrnValue *, const VyrnValue *);
typedef int (*fn_reg)(VyrnVM *, const char *, VyrnHostFn, void *);
typedef int (*fn_co_create)(VyrnVM *, const char *, VyrnValue *);
typedef int (*fn_co_resume)(VyrnVM *, int, const VyrnValue *, int, VyrnValue *, int, int32_t *);
typedef int (*fn_co_close)(VyrnVM *, int, const char *);
typedef int (*fn_co_yielded)(VyrnVM *);
typedef int (*fn_co_finished)(VyrnVM *);
typedef const char *(*fn_err)(VyrnVM *);
typedef int (*fn_err_code)(VyrnVM *);
typedef int (*fn_copy_string)(const char *, char *, int);

struct Api {
  fn_abi abi = nullptr;
  fn_create create = nullptr;
  fn_destroy destroy = nullptr;
  fn_set_limits set_limits = nullptr;
  fn_set_logger set_logger = nullptr;
  fn_run_file run_file = nullptr;
  fn_call call_global = nullptr;
  fn_call_multi call_global_multi = nullptr;
  fn_get_global get_global = nullptr;
  fn_table_get table_get = nullptr;
  fn_table_set table_set = nullptr;
  fn_reg reg = nullptr;
  fn_co_create co_create = nullptr;
  fn_co_resume co_resume = nullptr;
  fn_co_close co_close = nullptr;
  fn_co_yielded co_yielded = nullptr;
  fn_co_finished co_finished = nullptr;
  fn_err last_error = nullptr;
  fn_err_code last_error_code = nullptr;
  fn_copy_string copy_string = nullptr;
};

static std::vector<std::string> g_logs;

/**
 * @brief Print logger callback.
 * @param ud User data (unused).
 * @param line The log line to print.
 */
static void OnPrint(void * /*ud*/, const char *line) {
  g_logs.emplace_back(line ? line : "");
}

/**
 * @brief Host scale function.
 * @param ud User data (unused).
 * @param args The arguments to the function.
 * @param argc The number of arguments.
 * @param out The output value.
 * @return The number of output values.
 */
static int HostScale(void * /*ud*/, const VyrnValue *args, int argc, VyrnValue *out) {
  double dt = (argc >= 1 && args[0].type == VYRN_TYPE_NUMBER) ? args[0].number : 0.0;
  out->type = VYRN_TYPE_NUMBER;
  out->bool_val = 0;
  out->number = dt * 10.0;
  out->str = nullptr;
  return 1;
}

/**
 * @brief Copy a string from the VM.
 * @param api The API struct.
 * @param p The string to copy.
 * @return The copied string.
 */
static std::string CopyStr(Api &api, const char *p) {
  if (!p || !api.copy_string) return {};
  int need = api.copy_string(p, nullptr, 0);
  if (need <= 1) return {};
  std::string s(static_cast<size_t>(need), '\0');
  api.copy_string(p, s.data(), need);
  if (!s.empty() && s.back() == '\0') s.pop_back();
  return s;
}

/**
 * @brief Fail function.
 * @param api The API struct.
 * @param vm The VM.
 * @param what The what.
 * @return The result.
 */
static bool Fail(Api &api, VyrnVM *vm, const char *what) {
  int code = api.last_error_code ? api.last_error_code(vm) : VYRN_ERR_OTHER;
  const char *msg = api.last_error ? api.last_error(vm) : "?";
  std::fprintf(stderr, "[error] %s (code=%d): %s\n", what, code, msg);
  return false;
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

  Api api;
  api.abi = (fn_abi)LOAD(vyrn_abi_version);
  api.create = (fn_create)LOAD(vyrn_create);
  api.destroy = (fn_destroy)LOAD(vyrn_destroy);
  api.set_limits = (fn_set_limits)LOAD(vyrn_set_limits);
  api.set_logger = (fn_set_logger)LOAD(vyrn_set_print_logger);
  api.run_file = (fn_run_file)LOAD(vyrn_run_file);
  api.call_global = (fn_call)LOAD(vyrn_call_global);
  api.call_global_multi = (fn_call_multi)LOAD(vyrn_call_global_multi);
  api.get_global = (fn_get_global)LOAD(vyrn_get_global);
  api.table_get = (fn_table_get)LOAD(vyrn_table_get);
  api.table_set = (fn_table_set)LOAD(vyrn_table_set);
  api.reg = (fn_reg)LOAD(vyrn_register);
  api.co_create = (fn_co_create)LOAD(vyrn_coroutine_create_global);
  api.co_resume = (fn_co_resume)LOAD(vyrn_coroutine_resume);
  api.co_close = (fn_co_close)LOAD(vyrn_coroutine_close);
  api.co_yielded = (fn_co_yielded)LOAD(vyrn_coroutine_yielded);
  api.co_finished = (fn_co_finished)LOAD(vyrn_coroutine_finished);
  api.last_error = (fn_err)LOAD(vyrn_last_error);
  api.last_error_code = (fn_err_code)LOAD(vyrn_last_error_code);
  api.copy_string = (fn_copy_string)LOAD(vyrn_copy_string);

  if (!api.abi || !api.create || !api.destroy || !api.run_file || !api.call_global ||
      !api.call_global_multi || !api.get_global || !api.table_get || !api.table_set ||
      !api.reg || !api.co_create || !api.co_resume || !api.co_close || !api.co_yielded ||
      !api.co_finished || !api.last_error || !api.last_error_code || !api.copy_string) {
    std::fprintf(stderr, "[error] missing export (need ABI 3)\n");
    return 1;
  }

  int ver = api.abi();
  std::printf("abi=%d\n", ver);
  if (ver < VYRN_ABI_VERSION) {
    std::fprintf(stderr, "[error] need ABI >= %d\n", VYRN_ABI_VERSION);
    return 1;
  }

  VyrnVM *vm = api.create();
  if (!vm) {
    std::fprintf(stderr, "[error] create failed\n");
    return 1;
  }

  api.set_limits(vm, 100000, 64, 500000);
  api.set_logger(vm, OnPrint, nullptr);

  if (!api.reg(vm, "host_scale", HostScale, nullptr)) {
    Fail(api, vm, "register");
    api.destroy(vm);
    return 1;
  }

  const char *script = (argc > 2) ? argv[2] : "tests\\native\\smoke.vyrn";
  if (!api.run_file(vm, script)) {
    Fail(api, vm, "run_file");
    api.destroy(vm);
    return 1;
  }

  VyrnValue a2[2] = {};
  a2[0].type = VYRN_TYPE_NUMBER;
  a2[0].number = 2;
  a2[1].type = VYRN_TYPE_NUMBER;
  a2[1].number = 3;
  VyrnValue out = {};
  if (!api.call_global(vm, "add", a2, 2, &out) || out.number != 5) {
    Fail(api, vm, "add");
    api.destroy(vm);
    return 1;
  }
  std::printf("add=%g\n", out.number);

  VyrnValue outs[VYRN_MAX_OUTS] = {};
  int32_t nout = 0;
  if (!api.call_global_multi(vm, "pair", nullptr, 0, outs, VYRN_MAX_OUTS, &nout) ||
      nout < 2 || outs[0].number != 7 || outs[1].number != 8) {
    Fail(api, vm, "pair");
    api.destroy(vm);
    return 1;
  }
  std::printf("pair=%g,%g\n", outs[0].number, outs[1].number);

  VyrnValue cfg = {};
  if (!api.get_global(vm, "cfg", &cfg) || cfg.type != VYRN_TYPE_TABLE) {
    Fail(api, vm, "get cfg");
    api.destroy(vm);
    return 1;
  }
  int tid = static_cast<int>(cfg.number);
  VyrnValue key = {};
  key.type = VYRN_TYPE_STRING;
  key.str = "x";
  VyrnValue xv = {};
  if (!api.table_get(vm, tid, &key, &xv) || xv.number != 10) {
    Fail(api, vm, "table_get x");
    api.destroy(vm);
    return 1;
  }
  VyrnValue nv = {};
  nv.type = VYRN_TYPE_NUMBER;
  nv.number = 42;
  if (!api.table_set(vm, tid, &key, &nv)) {
    Fail(api, vm, "table_set x");
    api.destroy(vm);
    return 1;
  }
  std::printf("cfg.x=42\n");

  VyrnValue msg = {};
  msg.type = VYRN_TYPE_STRING;
  msg.str = "cpp-log";
  if (!api.call_global(vm, "say", &msg, 1, &out)) {
    Fail(api, vm, "say");
    api.destroy(vm);
    return 1;
  }
  bool logged = false;
  for (auto &l : g_logs) {
    if (l.find("cpp-log") != std::string::npos) logged = true;
  }
  if (!logged) {
    std::fprintf(stderr, "[error] print logger missed line\n");
    api.destroy(vm);
    return 1;
  }
  std::printf("logger ok\n");

  /* Durable string copy after a call that returns a string. */
  VyrnValue nameArg = {};
  nameArg.type = VYRN_TYPE_STRING;
  nameArg.str = "vyrn";
  if (!api.call_global(vm, "greet", &nameArg, 1, &out) || out.type != VYRN_TYPE_STRING) {
    Fail(api, vm, "greet");
    api.destroy(vm);
    return 1;
  }
  std::string greet = CopyStr(api, out.str);
  std::printf("greet=%s\n", greet.c_str());

  /* Coroutine: gen yields 10, 20, then returns 30. */
  VyrnValue co = {};
  if (!api.co_create(vm, "gen", &co) || co.type != VYRN_TYPE_TABLE) {
    Fail(api, vm, "coroutine_create gen");
    api.destroy(vm);
    return 1;
  }
  int cid = static_cast<int>(co.number);
  for (int step = 0; step < 3; ++step) {
    nout = 0;
    if (!api.co_resume(vm, cid, nullptr, 0, outs, VYRN_MAX_OUTS, &nout)) {
      Fail(api, vm, "coroutine_resume");
      api.destroy(vm);
      return 1;
    }
    std::printf("resume#%d n=%d yielded=%d finished=%d\n",
                step, nout, api.co_yielded(vm), api.co_finished(vm));
  }
  api.co_close(vm, cid, nullptr);

  /* Typed error: missing global */
  if (api.call_global(vm, "no_such_fn", nullptr, 0, &out)) {
    std::fprintf(stderr, "[error] expected missing global to fail\n");
    api.destroy(vm);
    return 1;
  }
  int ec = api.last_error_code(vm);
  std::printf("missing_fn code=%d msg=%s\n", ec, api.last_error(vm));
  if (ec != VYRN_ERR_NOT_FOUND && ec != VYRN_ERR_RUNTIME && ec != VYRN_ERR_OTHER) {
    /* Accept several codes depending on classify heuristics; must be non-OK. */
    if (ec == VYRN_ERR_OK) {
      std::fprintf(stderr, "[error] expected non-OK error code\n");
      api.destroy(vm);
      return 1;
    }
  }

  api.destroy(vm);
  std::printf("OK cpp-demo\n");
  return 0;
}
