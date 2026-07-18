/* Vyrn native C ABI (Vyrn.dll) — for C, C++, and C# P/Invoke.
 * ABI version: vyrn_abi_version() == 3
 *
 * Calling convention: cdecl (ProcedureCDLL).
 * Strings: UTF-8, NUL-terminated.
 * One VM instance per process (handle is still required).
 * Target: Windows x64 (PureBasic 6.40 build).
 *
 * String lifetime: pointers from VyrnValue.str / vyrn_last_error are owned by the
 * DLL and invalidated by the next vyrn_* call that returns or sets a string.
 * Use vyrn_copy_string() to take a durable copy into a caller buffer.
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

#define VYRN_ABI_VERSION 3

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

typedef struct VyrnVM VyrnVM;

typedef struct VyrnValue {
  int32_t type;
  int32_t bool_val;
  double number;
  const char *str;
} VyrnValue;

typedef int (*VyrnHostFn)(void *userdata, const VyrnValue *args, int argc, VyrnValue *out);
typedef void (*VyrnLogFn)(void *userdata, const char *utf8_line);

VYRN_API int         vyrn_abi_version(void);
VYRN_API VyrnVM     *vyrn_create(void);
VYRN_API void        vyrn_destroy(VyrnVM *vm);

VYRN_API int         vyrn_set_limits(VyrnVM *vm, int max_loops, int max_calls, int max_ins);
VYRN_API int         vyrn_set_print_logger(VyrnVM *vm, VyrnLogFn fn, void *userdata);

VYRN_API int         vyrn_run_file(VyrnVM *vm, const char *path);           /* 1=ok */
VYRN_API int         vyrn_eval(VyrnVM *vm, const char *source);             /* 1=ok */

VYRN_API int         vyrn_call_global(VyrnVM *vm, const char *name,
                                      const VyrnValue *args, int argc,
                                      VyrnValue *out);
VYRN_API int         vyrn_call_global_multi(VyrnVM *vm, const char *name,
                                            const VyrnValue *args, int argc,
                                            VyrnValue *outs, int max_out,
                                            int32_t *out_count);

VYRN_API int         vyrn_get_global(VyrnVM *vm, const char *name, VyrnValue *out);
VYRN_API int         vyrn_set_global(VyrnVM *vm, const char *name, const VyrnValue *val);
VYRN_API int         vyrn_table_get(VyrnVM *vm, int table_id, const VyrnValue *key, VyrnValue *out);
VYRN_API int         vyrn_table_set(VyrnVM *vm, int table_id, const VyrnValue *key, const VyrnValue *val);

VYRN_API int         vyrn_register(VyrnVM *vm, const char *name,
                                   VyrnHostFn fn, void *userdata);

/* Coroutine: create from a global function; id is VYRN_TYPE_TABLE number field. */
VYRN_API int         vyrn_coroutine_create_global(VyrnVM *vm, const char *name, VyrnValue *out_co);
VYRN_API int         vyrn_coroutine_resume(VyrnVM *vm, int tid,
                                           const VyrnValue *args, int argc,
                                           VyrnValue *outs, int max_out,
                                           int32_t *out_count);
VYRN_API int         vyrn_coroutine_close(VyrnVM *vm, int tid, const char *err_msg); /* err_msg may be NULL */
VYRN_API int         vyrn_coroutine_yielded(VyrnVM *vm);   /* 1 if last resume yielded */
VYRN_API int         vyrn_coroutine_finished(VyrnVM *vm);  /* 1 if last resume finished */

VYRN_API const char *vyrn_last_error(VyrnVM *vm);          /* never NULL */
VYRN_API int         vyrn_last_error_code(VyrnVM *vm);      /* VYRN_ERR_* */

/* Durable UTF-8 copy. Returns bytes needed including NUL. Truncates if buf too small. */
VYRN_API int         vyrn_copy_string(const char *src, char *buf, int buf_size);

#ifdef __cplusplus
}
#endif

#endif /* VYRN_H */
