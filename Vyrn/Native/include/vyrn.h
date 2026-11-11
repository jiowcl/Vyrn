/* Vyrn native C ABI (Vyrn.dll) — for C, C++, and C# P/Invoke.
 * ABI version: vyrn_abi_version() == 9 (8 = capabilities; 9 = net allowlist)
 *
 * Calling convention: cdecl (ProcedureCDLL).
 * Strings: UTF-8, NUL-terminated.
 * One VM instance per process (handle is still required).
 * Target: Windows x64/x86 (PureBasic 6.41 build).
 *
 * String lifetime: pointers from VyrnValue.str / vyrn_last_error are owned by the
 * DLL and invalidated by the next vyrn_* call that returns or sets a string.
 * Use vyrn_copy_string() to take a durable copy into a caller buffer.
 *
 * Author: Ji-Feng Tsai (jiowcl@gmail.com)
 */

#ifndef VYRN_H
#define VYRN_H

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>

#if defined(_WIN32) && !defined(VYRN_STATIC)
#  ifdef VYRN_BUILDING_DLL
#    define VYRN_API __declspec(dllexport)
#  else
#    define VYRN_API __declspec(dllimport)
#  endif
#else
#  define VYRN_API
#endif

#define VYRN_ABI_VERSION 9

#define VYRN_CAP_NET 1

#define VYRN_TYPE_NIL    0
#define VYRN_TYPE_BOOL   1
#define VYRN_TYPE_NUMBER 2
#define VYRN_TYPE_STRING 3
#define VYRN_TYPE_TABLE  4  /* number field holds table id (also coroutine objects) */

#define VYRN_MAX_ARGS 16
#define VYRN_MAX_OUTS 8

#define VYRN_ERR_OK              0
#define VYRN_ERR_INVALID_HANDLE  1
#define VYRN_ERR_NOT_FOUND       2
#define VYRN_ERR_COMPILE         3
#define VYRN_ERR_RUNTIME         4
#define VYRN_ERR_TYPE            5
#define VYRN_ERR_ARG             6
#define VYRN_ERR_OTHER           7
#define VYRN_ERR_CANCELLED       8

typedef struct VyrnVM VyrnVM;

typedef struct VyrnValue {
  int32_t type;
  /* BOOL: truth. NUMBER subtype (ABI 7): 0 = legacy auto, 1 = integer, 2 = float. */
  int32_t bool_val;
  double number;
  int64_t integer; /* ABI 7: exact int64 when type==NUMBER and bool_val==1 */
  const char *str;
} VyrnValue;

/** ABI 7: set *v to the integer q. */
static inline void vyrn_value_set_integer(VyrnValue *v, int64_t q) {
  v->type = VYRN_TYPE_NUMBER; v->bool_val = 1; v->integer = q; v->number = (double)q; v->str = 0;
}
/** ABI 7: set *v to the float d. */
static inline void vyrn_value_set_float(VyrnValue *v, double d) {
  v->type = VYRN_TYPE_NUMBER; v->bool_val = 2; v->number = d; v->integer = 0; v->str = 0;
}
/** ABI 7: non-zero when *v is a NUMBER integer subtype. */
static inline int vyrn_value_is_integer(const VyrnValue *v) {
  return v && v->type == VYRN_TYPE_NUMBER && v->bool_val == 1;
}
/** ABI 7: write the integer representation of *v into *out (Lua tointegerx, no strings). */
static inline int vyrn_value_to_integer(const VyrnValue *v, int64_t *out) {
  if (!v || !out || v->type != VYRN_TYPE_NUMBER) return 0;
  if (v->bool_val == 1) { *out = v->integer; return 1; }
  { double d = v->number;
    if (d != d || d != (double)(int64_t)d || d < -9223372036854775808.0 || d >= 9223372036854775808.0)
      return 0;
    *out = (int64_t)d; return 1; }
}

typedef int (*VyrnHostFn)(void *userdata, const VyrnValue *args, int argc, VyrnValue *out);
typedef void (*VyrnLogFn)(void *userdata, const char *utf8_line);

/** @return ABI integer (must equal VYRN_ABI_VERSION). */
VYRN_API int         vyrn_abi_version(void);

/** @return Product version string owned by the DLL (never NULL). */
VYRN_API const char *vyrn_version(void);

/** @return New VM handle, or NULL on failure. */
VYRN_API VyrnVM     *vyrn_create(void);

/**
 * Destroy a VM created by vyrn_create.
 * @param vm VM handle (NULL-safe).
 */
VYRN_API void        vyrn_destroy(VyrnVM *vm);

/**
 * Cooperative cancel: abort the in-flight vyrn_run_file / vyrn_eval / call.
 * Safe to call from another thread. The running call returns 0 with
 * VYRN_ERR_CANCELLED. Does not unload the DLL.
 * @param vm VM handle.
 * @return Non-zero on success.
 */
VYRN_API int         vyrn_request_cancel(VyrnVM *vm);

/**
 * Set opt-in runtime limits (0 = no limit). Since 1.6.112 a new VM has no loop or
 * instruction limit; use vyrn_request_cancel to stop a runaway script.
 * @param vm        VM handle.
 * @param max_loops Max loop ticks (backward jumps, calls, returns).
 * @param max_calls Max call depth / calls.
 * @param max_ins   Max instructions.
 * @return Non-zero on success.
 */
VYRN_API int         vyrn_set_limits(VyrnVM *vm, int max_loops, int max_calls, int max_ins);

/**
 * Set capability bits for this VM (ABI 8). Default is 0 (sandboxed).
 * VYRN_CAP_NET enables http.*. Keep ABI-7 hosts working: they simply never call this.
 * @param vm   VM handle.
 * @param caps Bitmask (VYRN_CAP_NET = 1).
 * @return Non-zero on success.
 */
VYRN_API int         vyrn_set_capabilities(VyrnVM *vm, unsigned int caps);

/**
 * @return Current capability bits for this VM (ABI 8).
 */
VYRN_API unsigned int vyrn_get_capabilities(VyrnVM *vm);

/**
 * Set an optional host allowlist for http.* (ABI 9).
 * NULL or "" clears (all hosts allowed when VYRN_CAP_NET is set).
 * Non-empty CSV of exact hosts, optionally with :port.
 * Disallowed hosts raise: network access to host X is not allowed.
 * ABI-8 hosts keep working if they never call this.
 */
VYRN_API int vyrn_set_net_allowlist(VyrnVM *vm, const char *hosts_csv);

/**
 * @return Current allowlist CSV ("" when unrestricted); owned by the DLL (ABI 9).
 */
VYRN_API const char *vyrn_get_net_allowlist(VyrnVM *vm);

/**
 * Install a print logger for script print output.
 * @param vm       VM handle.
 * @param fn       Logger callback (NULL clears).
 * @param userdata Passed to fn.
 * @return Non-zero on success.
 */
VYRN_API int         vyrn_set_print_logger(VyrnVM *vm, VyrnLogFn fn, void *userdata);

/**
 * Compile and run a script file.
 * @param vm   VM handle.
 * @param path UTF-8 path.
 * @return 1 on success; 0 on failure (see vyrn_last_error*).
 */
VYRN_API int         vyrn_run_file(VyrnVM *vm, const char *path);

/**
 * Compile and evaluate a source string.
 * @param vm     VM handle.
 * @param source UTF-8 source.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_eval(VyrnVM *vm, const char *source);

/**
 * Call a global function; single primary return in out.
 * @param vm   VM handle.
 * @param name Global function name.
 * @param args Argument array (may be NULL if argc==0).
 * @param argc Argument count (<= VYRN_MAX_ARGS).
 * @param out  Optional primary return (may be NULL).
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_call_global(VyrnVM *vm, const char *name,
                                      const VyrnValue *args, int argc,
                                      VyrnValue *out);

/**
 * Call a global function with multiple returns.
 * @param vm        VM handle.
 * @param name      Global function name.
 * @param args      Argument array.
 * @param argc      Argument count.
 * @param outs      Output value array.
 * @param max_out   Capacity of outs (<= VYRN_MAX_OUTS).
 * @param out_count Receives actual return count.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_call_global_multi(VyrnVM *vm, const char *name,
                                            const VyrnValue *args, int argc,
                                            VyrnValue *outs, int max_out,
                                            int32_t *out_count);

/**
 * Read a global into out.
 * @param vm   VM handle.
 * @param name Global name.
 * @param out  Destination value.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_get_global(VyrnVM *vm, const char *name, VyrnValue *out);

/**
 * Write a global from val.
 * @param vm   VM handle.
 * @param name Global name.
 * @param val  Value to store.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_set_global(VyrnVM *vm, const char *name, const VyrnValue *val);

/**
 * Read table[key] into out.
 * @param vm       VM handle.
 * @param table_id Table id (from VYRN_TYPE_TABLE number field).
 * @param key      Lookup key.
 * @param out      Destination value.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_table_get(VyrnVM *vm, int table_id, const VyrnValue *key, VyrnValue *out);

/**
 * Write table[key] = val.
 * @param vm       VM handle.
 * @param table_id Table id.
 * @param key      Key.
 * @param val      Value.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_table_set(VyrnVM *vm, int table_id, const VyrnValue *key, const VyrnValue *val);

/**
 * Pin a table (ABI 6). Table ids returned by other calls are NOT pinned: once the
 * script drops its last reference the GC may free the table and reuse the id.
 * A pinned table is a GC root until every pin is released. Pins are counted.
 * @param vm       VM handle.
 * @param table_id Table id.
 * @return New pin count (>= 1) on success; 0 on failure
 *         (VYRN_ERR_ARG for id < 1, VYRN_ERR_NOT_FOUND for a stale id).
 */
VYRN_API int         vyrn_table_pin(VyrnVM *vm, int table_id);

/**
 * Release one pin (ABI 6). At zero pins the table is collectable again.
 * @param vm       VM handle.
 * @param table_id Table id.
 * @return 1 on success; 0 on failure (VYRN_ERR_ARG for id < 1,
 *         VYRN_ERR_NOT_FOUND when the id is not pinned: unknown, stale or fully unpinned).
 */
VYRN_API int         vyrn_table_unpin(VyrnVM *vm, int table_id);

/**
 * Current pin count of a table (ABI 6).
 * @return Pin count (>= 0; 0 = not pinned); -1 on an invalid VM handle.
 */
VYRN_API int         vyrn_table_pin_count(VyrnVM *vm, int table_id);

/**
 * Register a host function as a global callable.
 * @param vm       VM handle.
 * @param name     Global name.
 * @param fn       Host callback.
 * @param userdata Passed to fn.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_register(VyrnVM *vm, const char *name,
                                   VyrnHostFn fn, void *userdata);

/**
 * Create a coroutine from a global function; out_co is VYRN_TYPE_TABLE.
 * @param vm     VM handle.
 * @param name   Global function name.
 * @param out_co Receives coroutine object value.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_coroutine_create_global(VyrnVM *vm, const char *name, VyrnValue *out_co);

/**
 * Resume a coroutine by table id.
 * @param vm        VM handle.
 * @param tid       Coroutine table id.
 * @param args      Resume arguments.
 * @param argc      Argument count.
 * @param outs      Output values.
 * @param max_out   Capacity of outs.
 * @param out_count Receives return count.
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_coroutine_resume(VyrnVM *vm, int tid,
                                           const VyrnValue *args, int argc,
                                           VyrnValue *outs, int max_out,
                                           int32_t *out_count);

/**
 * Close a coroutine (optional error message).
 * @param vm      VM handle.
 * @param tid     Coroutine table id.
 * @param err_msg Optional UTF-8 error (may be NULL).
 * @return 1 on success; 0 on failure.
 */
VYRN_API int         vyrn_coroutine_close(VyrnVM *vm, int tid, const char *err_msg);

/** @param vm VM handle. @return 1 if the last resume yielded. */
VYRN_API int         vyrn_coroutine_yielded(VyrnVM *vm);

/** @param vm VM handle. @return 1 if the last resume finished. */
VYRN_API int         vyrn_coroutine_finished(VyrnVM *vm);

/** @param vm VM handle. @return Last error message (never NULL; short-lived). */
VYRN_API const char *vyrn_last_error(VyrnVM *vm);

/** @param vm VM handle. @return Last VYRN_ERR_* code. */
VYRN_API int         vyrn_last_error_code(VyrnVM *vm);

/**
 * @param vm VM handle.
 * @return Warning count from the last vyrn_run_file / vyrn_eval.
 */
VYRN_API int         vyrn_warning_count(VyrnVM *vm);

/**
 * @param vm    VM handle.
 * @param index Zero-based warning index.
 * @return Warning text (never NULL; short-lived).
 */
VYRN_API const char *vyrn_get_warning(VyrnVM *vm, int index);

/**
 * Durable UTF-8 copy into a caller buffer.
 * @param src      Source string (may be NULL).
 * @param buf      Destination buffer (may be NULL to query size).
 * @param buf_size Capacity of buf in bytes.
 * @return Bytes needed including NUL (truncates if buf too small).
 */
VYRN_API int         vyrn_copy_string(const char *src, char *buf, int buf_size);

#ifdef __cplusplus
}
#endif

#endif /* VYRN_H */
