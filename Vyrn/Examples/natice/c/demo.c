/**
 * @file demo.c
 * @brief Full C host implementation for Vyrn.dll/LibVyrn.dll (ABI 3).
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
 *     cl /EHsc /std:c17 /I include examples\native\c\demo.c /Fe:examples\native\c\demo.exe
 *     examples\native\c\demo.exe
 */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

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

typedef struct Api {
  fn_abi abi;
  fn_create create;
  fn_destroy destroy;
  fn_set_limits set_limits;
  fn_set_logger set_logger;
  fn_run_file run_file;
  fn_call call_global;
  fn_call_multi call_global_multi;
  fn_get_global get_global;
  fn_table_get table_get;
  fn_table_set table_set;
  fn_reg reg;
  fn_co_create co_create;
  fn_co_resume co_resume;
  fn_co_close co_close;
  fn_co_yielded co_yielded;
  fn_co_finished co_finished;
  fn_err last_error;
  fn_err_code last_error_code;
  fn_copy_string copy_string;
} Api;

/* Dynamic array for log storage */
static char **g_logs = NULL;
static size_t g_log_count = 0;
static size_t g_log_capacity = 0;

/**
 * @brief Print logger callback.
 * @param ud User data (unused).
 * @param line The log line to print.
 */
static void OnPrint(void *ud, const char *line) {
  (void)ud;
  if (g_log_count >= g_log_capacity) {
    size_t new_cap = g_log_capacity ? g_log_capacity * 2 : 8;
    char **new_logs = realloc(g_logs, sizeof(char *) * new_cap);
    if (!new_logs) return;
    g_logs = new_logs;
    g_log_capacity = new_cap;
  }
  g_logs[g_log_count] = malloc(strlen(line ? line : "") + 1);
  if (g_logs[g_log_count]) {
    strcpy(g_logs[g_log_count], line ? line : "");
  }
  g_log_count++;
}

/**
 * @brief Free log storage.
 */
static void FreeLogs(void) {
  for (size_t i = 0; i < g_log_count; i++) {
    free(g_logs[i]);
  }
  free(g_logs);
  g_logs = NULL;
  g_log_count = 0;
  g_log_capacity = 0;
}

/**
 * @brief Host scale function.
 * @param ud User data (unused).
 * @param args The arguments to the function.
 * @param argc The number of arguments.
 * @param out The output value.
 * @return The number of output values.
 */
static int HostScale(void *ud, const VyrnValue *args, int argc, VyrnValue *out) {
  (void)ud;
  double dt = (argc >= 1 && args[0].type == VYRN_TYPE_NUMBER) ? args[0].number : 0.0;
  out->type = VYRN_TYPE_NUMBER;
  out->bool_val = 0;
  out->number = dt * 10.0;
  out->str = NULL;
  return 1;
}

/**
 * @brief Copy a string from the VM.
 * @param api The API struct.
 * @param p The string to copy.
 * @return The copied string (caller must free).
 */
static char *CopyStr(Api *api, const char *p) {
  if (!p || !api->copy_string) return NULL;
  int need = api->copy_string(p, NULL, 0);
  if (need <= 1) return NULL;
  char *s = malloc((size_t)need);
  if (!s) return NULL;
  api->copy_string(p, s, need);
  size_t len = strlen(s);
  if (len > 0 && s[len - 1] == '\0') s[len - 1] = '\0';
  return s;
}

/**
 * @brief Fail function.
 * @param api The API struct.
 * @param vm The VM.
 * @param what The what.
 * @return The result.
 */
static int Fail(Api *api, VyrnVM *vm, const char *what) {
  int code = api->last_error_code ? api->last_error_code(vm) : VYRN_ERR_OTHER;
  const char *msg = api->last_error ? api->last_error(vm) : "?";
  fprintf(stderr, "[error] %s (code=%d): %s\n", what, code, msg);
  return 0;
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
    fprintf(stderr, "[error] LoadLibrary %s failed\n", dllPath);
    return 1;
  }

  Api api;
  memset(&api, 0, sizeof(api));
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
    fprintf(stderr, "[error] missing export (need ABI 3)\n");
    return 1;
  }

  int ver = api.abi();
  printf("abi=%d\n", ver);
  if (ver < VYRN_ABI_VERSION) {
    fprintf(stderr, "[error] need ABI >= %d\n", VYRN_ABI_VERSION);
    return 1;
  }

  VyrnVM *vm = api.create();
  if (!vm) {
    fprintf(stderr, "[error] create failed\n");
    return 1;
  }

  api.set_limits(vm, 100000, 64, 500000);
  api.set_logger(vm, OnPrint, NULL);

  if (!api.reg(vm, "host_scale", HostScale, NULL)) {
    Fail(&api, vm, "register");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }

  const char *script = (argc > 2) ? argv[2] : "tests\\native\\smoke.vyrn";
  if (!api.run_file(vm, script)) {
    Fail(&api, vm, "run_file");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }

  VyrnValue a2[2] = {0};
  a2[0].type = VYRN_TYPE_NUMBER;
  a2[0].number = 2;
  a2[1].type = VYRN_TYPE_NUMBER;
  a2[1].number = 3;
  VyrnValue out = {0};
  if (!api.call_global(vm, "add", a2, 2, &out) || out.number != 5) {
    Fail(&api, vm, "add");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  printf("add=%g\n", out.number);

  VyrnValue outs[VYRN_MAX_OUTS] = {0};
  int32_t nout = 0;
  if (!api.call_global_multi(vm, "pair", NULL, 0, outs, VYRN_MAX_OUTS, &nout) ||
      nout < 2 || outs[0].number != 7 || outs[1].number != 8) {
    Fail(&api, vm, "pair");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  printf("pair=%g,%g\n", outs[0].number, outs[1].number);

  VyrnValue cfg = {0};
  if (!api.get_global(vm, "cfg", &cfg) || cfg.type != VYRN_TYPE_TABLE) {
    Fail(&api, vm, "get cfg");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  int tid = (int)cfg.number;
  VyrnValue key = {0};
  key.type = VYRN_TYPE_STRING;
  key.str = "x";
  VyrnValue xv = {0};
  if (!api.table_get(vm, tid, &key, &xv) || xv.number != 10) {
    Fail(&api, vm, "table_get x");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  VyrnValue nv = {0};
  nv.type = VYRN_TYPE_NUMBER;
  nv.number = 42;
  if (!api.table_set(vm, tid, &key, &nv)) {
    Fail(&api, vm, "table_set x");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  printf("cfg.x=42\n");

  VyrnValue msg = {0};
  msg.type = VYRN_TYPE_STRING;
  msg.str = "cpp-log";
  if (!api.call_global(vm, "say", &msg, 1, &out)) {
    Fail(&api, vm, "say");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  int logged = 0;
  for (size_t i = 0; i < g_log_count; i++) {
    if (g_logs[i] && strstr(g_logs[i], "cpp-log") != NULL) {
      logged = 1;
      break;
    }
  }
  if (!logged) {
    fprintf(stderr, "[error] print logger missed line\n");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  printf("logger ok\n");

  /* Durable string copy after a call that returns a string. */
  VyrnValue nameArg = {0};
  nameArg.type = VYRN_TYPE_STRING;
  nameArg.str = "vyrn";
  if (!api.call_global(vm, "greet", &nameArg, 1, &out) || out.type != VYRN_TYPE_STRING) {
    Fail(&api, vm, "greet");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  char *greet = CopyStr(&api, out.str);
  printf("greet=%s\n", greet ? greet : "(null)");
  free(greet);

  /* Coroutine: gen yields 10, 20, then returns 30. */
  VyrnValue co = {0};
  if (!api.co_create(vm, "gen", &co) || co.type != VYRN_TYPE_TABLE) {
    Fail(&api, vm, "coroutine_create gen");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  int cid = (int)co.number;
  for (int step = 0; step < 3; ++step) {
    nout = 0;
    if (!api.co_resume(vm, cid, NULL, 0, outs, VYRN_MAX_OUTS, &nout)) {
      Fail(&api, vm, "coroutine_resume");
      api.destroy(vm);
      FreeLogs();
      return 1;
    }
    printf("resume#%d n=%d yielded=%d finished=%d\n",
           step, nout, api.co_yielded(vm), api.co_finished(vm));
  }
  api.co_close(vm, cid, NULL);

  /* Typed error: missing global */
  if (api.call_global(vm, "no_such_fn", NULL, 0, &out)) {
    fprintf(stderr, "[error] expected missing global to fail\n");
    api.destroy(vm);
    FreeLogs();
    return 1;
  }
  int ec = api.last_error_code(vm);
  printf("missing_fn code=%d msg=%s\n", ec, api.last_error(vm));
  if (ec != VYRN_ERR_NOT_FOUND && ec != VYRN_ERR_RUNTIME && ec != VYRN_ERR_OTHER) {
    /* Accept several codes depending on classify heuristics; must be non-OK. */
    if (ec == VYRN_ERR_OK) {
      fprintf(stderr, "[error] expected non-OK error code\n");
      api.destroy(vm);
      FreeLogs();
      return 1;
    }
  }

  api.destroy(vm);
  FreeLogs();
  printf("OK c-demo\n");
  return 0;
}