# VyrnSpec  

Vyrn is the primary surface syntax for the Vyrn (LuaLiteVM) bytecode runtime. The VM still accepts legacy LuaLiteVM (`.lua`) scripts; new code should use `.vyrn` files.  

## File Extension  

- **Preferred:** `.vyrn`  
- **Legacy:** `.lua` (fully supported)  

## Dialect Header (Optional, Recommended)  

First line may declare the dialect version:

```vyrn
-- vyrn: 1
```

Also accepted: `-- vyrn 1`, `#vyrn 1`.  
`.vyrn` files default to dialect version 1 even without a header.  

## Legacy Keyword Warnings  

In `.vyrn` scripts (or any script with a `vyrn` header), using `func`, `local`, or `elseif` prints non-fatal warnings:  

```text
[warn] script.vyrn:3: 'func' is legacy; prefer 'def' in Vyrn scripts
```

Legacy `.lua` files are not warned.  

## Keywords (Vyrn 0.1)  

| Vyrn | Legacy equivalent | Notes |
| ------ | ------------------- | ------- |
| `def` | `func`, `function` | Function definition |
| `let` | `local` | Local binding |
| `elif` | `elseif` | Else-if branch |
| `end` | `end` | Unchanged (Style A) |

All other LuaLite keywords (`if`, `while`, `for`, `return`, `and`, `or`, `not`, `then`, `else`, `do`, …) are unchanged.

## Functions  

```vyrn
def greet(name: string) -> string
    return "Hello, " .. name
end

def pair() -> number, number
    return 10, 20
end

def pair2() -> (number, number)
    return 10, 20
end

let a, b = pair()
```

- Parameter types and return types are **optional**; when present they are checked at **runtime**.  
- Return type may be written as `-> type` (Vyrn) or `: type` (legacy).  
- **Multiple return types:** `-> number, number` or `-> (number, number)` annotates each value from `return a, b` (checked per position).  
- **Typed destructure:** `let a: number, b: string = f()` checks each binding after assignment (also applies when `f()` has no return annotations). Mismatch reports `binding #N`.  
- **Tuple destructure:** `let (a, b): (number, string) = pair()` — parenthesized names and types.  
- **Parameter types:** mismatch reports `parameter #N`.  

Supported type names: `nil`, `boolean` / `bool`, `number`, `string`, `table`, `function` / `func`.  

## Locals  

```vyrn
let score = 100
let score: number = 100
let a: number, b: string = 1, "x"
let (a, b): (number, string) = pair()
let def add(a, b)
    return a + b
end
```

`let` followed by `def` defines a local function (same as `local func`).  

Optional type annotations on `let` bindings are checked at **runtime** when `=` is present.  

## Dialect version

Use `-- vyrn: 2` for scripts using typed `let` (optional; recommended for new files).  

## Constants (v0.3)  

```vyrn
const PI: number = 3.14
const LABEL: string = "ok"
```

`const` requires an initializer; reassignment is a **compile-time** error in scripts, or **compile-time / runtime** error for REPL globals.  

In REPL / `-e`, `const` at top level creates an immutable **global** (same persistence as `let`).  

## Loop control (v0.3)  

`continue` jumps to the next iteration of the innermost `while`, `for`, or `repeat` loop.

## String interpolation (v0.4)  

In **double-quoted** strings, `{expr}` embeds an expression:

```vyrn
let name = "Vyrn"
print("Hello, {name}!")
```

- `\{` and `\}` produce literal braces in the string part.
- Empty `{}` is a compile error.
- Nested `{` inside an interpolation expression is not allowed in v0.4.  

## Pattern matching (v0.4)  

```vyrn
match x
    0 => print("zero")
    1 => print("one")
    else => print("other")
end
```

- Subject is a single expression; arms compare with `==` (literal number, string, `true`, `false`, `nil`).
- `else =>` is optional and must appear last.
- Desugars to `if` / `elif` chains; terminates with `end`.  

## Default parameters (v0.5)  

```vyrn
def add(a, b: number = 10) -> number
    return a + b
end
```

- Default values must be **literals** (`number`, `string`, `true`, `false`, `nil`, unary `-` on numbers).
- Default values may be **any expression**; non-literals are evaluated at **call time** in the caller's environment (via enclosing locals / globals).
- Parameters without defaults must come before parameters with defaults.
- Omitted arguments are filled at call time.  

## REPL / eval (v0.6)

Interactive REPL and `--eval-file` accumulate lines until a syntactic unit is complete (`...>` continuation prompt). Unclosed blocks at end of eval report an error.  

## Struct (v1.0, dialect ≥ 9; v1.1 extensions dialect ≥ 10)  

```vyrn
-- vyrn: 9
struct Vec2
    x: number
    y: number
end

let v = Vec2 { x = 1, y = 2 }
```

- Defines a **constructor function** with the struct name; call with a table literal (`Name { ... }` or `Name({ ... })`).
- Validates each field type at **runtime** when the constructor runs.
- Type mismatch reports `field 'name'` (v1.1+).  

## Enum (v1.1, dialect ≥ 10; explicit type dialect ≥ 12)  

```vyrn
-- vyrn: 10
enum Color
    Red
    Green
    Blue
end

print(Color.Red, Color.Green, Color.Blue)   -- 0 1 2

enum Status { Idle, Running, Done }

-- vyrn: 12
enum Priority: number
    Low
    High
end
```

- Defines a global table mapping member names to `0, 1, 2, …`.
- Brace or `end`-terminated forms are supported.
- **Explicit value type (dialect ≥ 12):** `enum Name: number` — documents intent; only **`number`** is accepted today (members remain numeric).  

## Import (v1.0, dialect ≥ 9; extensions in 10–11)  

```vyrn
import greet from "lib.greet"
import "lib.config"
import { run, tag } from "lib.mod_exports"
import { run as greetFn } from "lib.mod_exports"
import * as M from "lib.mod_exports"
```

- `import name from "path"` → `let name = require("path")` in scripts (local binding).
- `import "path"` → side-effect `require("path")`.
- `import { a, b } from "path"` → field bindings; dialect ≥ 10.
- `import { a as b } from "path"` → rename on import; dialect ≥ 10.
- `import * as m from "path"` → namespace import; dialect ≥ 11.
- Module path uses the same rules as `require()` (dots → subdirectories).
- REPL binds imported names as **globals** (same as single `import`).  

## Attributes (v1.2+, dialect ≥ 11; v1.3 extensions dialect ≥ 12)  

```vyrn
[doc: "swap two numbers"]
def swap(a: number, b: number) -> (number, number)
    return b, a
end

@doc("greets by name")   -- dialect ≥ 12; same as [doc: "..."]
def greet(name: string) -> string
    return "Hello, " .. name
end

[deprecated: "use greet2 instead"]
def greetLegacy(name: string) -> string
    return "Hi, " .. name
end
```

- Bracket attributes before `def` / `struct`; **`doc`** and **`deprecated`** (dialect ≥ 12 for flag/value `[deprecated]`).
- **`@doc("...")`** sugar (dialect ≥ 12) — equivalent to `[doc: "..."]`.
- **`[deprecated]`** or **`[deprecated: "reason"]`** — emits a compile-time **`[warn]`** when the definition is compiled; shown in `--dump` as `; deprecated` or `; deprecated "..."`.
- Doc strings appear in `--dump` output as `; doc "..."`.
- Unknown attributes emit a **warning** and are ignored.  

**Struct field docs (dialect ≥ 12):**  

```vyrn
-- vyrn: 12
struct Point
    [doc: "x coordinate"]
    x: number
    [doc: "y coordinate"]
    y: number = 0
end

let p = Point { x = 1 }
print(p._fielddocs.x)   -- "x coordinate"
```

- Field-level `[doc: "..."]` only (not `deprecated`).
- Each instance gets a **`_fielddocs`** table mapping field names to doc strings.
- `--dump` on the struct constructor shows `; field name doc "..."` lines.  

## Numeric `for` (1.6.106)  

`for i = a, b [, step] do ... end` follows Lua: `a`, `b` and `step` (default `1`) are evaluated once before the loop. A positive step runs while `i <= b`, a negative step while `i >= b`, so `for i = 5, 1, -1` gives `5 4 3 2 1` and `for i = 1, 5, -1` runs zero times. Float steps work the same way (`for i = 1, 0, -0.25`). A step whose sign is not known at compile time (a variable, parameter or expression) picks the direction once when the loop starts. A zero step raises `'for' step is zero` when the loop starts (catchable with `pcall`); a non-number step raises a comparison error. Before 1.6.106 the compiler always tested `i <= b`, so a negative-step loop never ran. A literal positive (or omitted) step compiles to the same bytecode as before; this is a compiler change only (no new opcode), so it holds on the PB VM and libvyrnrt (`.vyrnc`, Standalone, Compile). Vyrn has no `goto`: since 1.6.112 `goto name` is a compile error (`file:line: goto is not supported (Vyrn has no labels; use break or continue)`) and `::name::` is a compile error (`labels ('::name::') are not supported ...`); `goto` alone stays usable as a variable name. Use `break` / `continue`.  

## Generic `for` (1.6.77)  

`for v1, v2, ... in explist do ... end` follows Lua: `explist` is evaluated once and adjusted to three values `f, s, c` (a trailing call expands). Each iteration calls `f(s, c)`; the loop ends when the first result is `nil`, otherwise it is assigned to `c`. `pairs`, `ipairs`, `next`, `string.gmatch` and user closures all work. For compatibility, if `f` is a **table** the loop walks its array part (`for v in t` gives elements, `for i, v in t` gives index and element). Loop variables are local to the loop body. Known gap: closures created in the body share one slot per variable (not a fresh binding per iteration as in Lua 5.4).



## Added in v0.1.1  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Length | `#str`, `#table` | Array part length for tables |
| Sort | `table.sort(t)` or `table.sort(t, cmp)` | In-place; bubble sort is **stable** (equal keys keep order); default `<` or custom comparator (dialect ≥ 8) |
| Multi-return | `return a, b` / `let x, y = f()` | Extra/missing values become `nil` |

## Added in v0.3  

| Feature | Syntax | Notes |
|---------|--------|-------|
| `continue` | `continue` in `while` / `for` / `repeat` | Jump to next loop iteration |
| `const` | `const x: type = value` | Immutable local binding (compile-time reassignment check) |

Use `-- vyrn: 3` for scripts using `continue` or `const` (optional).  
Use `-- vyrn: 4` for scripts using string interpolation or `match` (optional).  
Use `-- vyrn: 5` for scripts using default parameter values (optional).  
REPL / `-e`: typed `let` (`let x: number = 1`) performs runtime type checks on globals.  

## Added in v0.4  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Interpolation | `"Hello, {name}!"` | Double-quoted strings only; `\{` `\}` escapes |
| `match` | `match expr` / `pat => stmt` / `else =>` / `end` | Literal patterns; desugars to if/elif |

## Added in v0.5  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Default parameters | `def f(x, y = 10)` | Literal defaults only; missing args filled at call time |

## Added in v0.6  

| Feature | Syntax | Notes |
|---------|--------|-------|
| REPL multiline | `...>` continuation | `match` / `def` / blocks may span lines in REPL and `--eval-file` |
| Expr defaults | `def f(x, y = outer + 1)` | Non-literal defaults evaluated at each call |

## Added in v0.7  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Closures | nested `def` / `local func` | Inner functions capture outer `let`/`local`; upvalues survive after outer returns |

## Added in v0.8  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Anonymous functions | `def(x) ... end`, `function(x) ... end` | Function expressions; dialect >= 8 for `def (...)` in `.vyrn` |
| Custom sort | `table.sort(t, cmp)` | Optional comparator; `cmp(a,b)` must return boolean |

## Added in v0.9  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Protected call | `pcall(f, ...)` | Returns `true, result` or `false, err` |
| Error | `error(msg)` | Abort callable; catch with `pcall` |

## Added in v0.9.1  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Recursive local function | `local function f()` with upvalues | Self-binding uses `OP_CLOSURE` in prologue |
| Assert | `assert(v [, msg])` | Returns `v` on success; catchable via `pcall` |

## Added in v0.9.2  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Random seed | `math.randomseed(n)` | Resets PRNG (PureBasic `RandomSeed`) |
| Iterator functions | `ipairs(t)`, `pairs(t)` | First-class; returns `iter, state, var` for manual loops |

## Added in v0.9.3  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Table foreach | `table.foreach(t, f)` | Calls `f(k, v)` for each pair; stops and returns if `f` returns non-`nil` (Lua 5.0 style) |
| Sort stability | `table.sort` | Documented: implementation uses stable bubble sort |

## Added in v0.9.4  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Shared upvalues | closures over same `let` | Multiple closures capture one cell (Lua semantics) |
| Upvalue field assign | `t.x = v` in closure | Table field writes use upvalue, not global |
| Table map / filter | `table.map(t, f)`, `table.filter(t, f)` | `map` → new array; `filter` → new table of kept entries |
| Eval loop completeness | `for` / `while` in `--eval-file` | `ReplSourceComplete` no longer double-counts `while`/`for` |

## Added in v0.9.5  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Nested upvalues | closures in nested `def` | `OP_CLOSURE` honors `encFrame` for grandparent captures |
| Table reduce / find | `table.reduce(t, init, f)`, `table.find(t, f)` | `f(acc,k,v)` fold; `find` returns `k, v` or `nil` |
| Eval `while` | `while cond do ... end` | Same completeness fix as `for` in `--eval-file` |

## Added in v0.9.6  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Multi return types | `def f() -> number, string` | Runtime check per return position; fewer annotations than values → only annotated slots checked |
| Table index | `table.index_of(t, v)` | 1-based search in array part; returns index or `nil` |
| String split limit | `string.split(s, delim [, limit])` | Optional third arg merges remainder into last segment |

## Added in v0.9.7  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Typed destructure from calls | `let a: number, b: number = pair()` | Left-side runtime checks after multi-assign; complements `->` return types on callee |
| `table.find_index` | `table.find_index(t, v)` | Alias of `table.index_of` |

## Added in v0.9.8  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Tuple return types | `def f() -> (number, string)` | Parenthesized sugar for comma-separated return annotations |
| Binding type errors | `let a: number, b: string = ...` | Runtime message includes `binding #N` |
| Legacy `function()` in `.vyrn` | `pcall(function() ... end)` | Allowed at any dialect; `def()` anonymous still requires dialect ≥ 8 |

## Added in v0.9.9  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Tuple let types | `let (a, b): (number, string) = f()` | Parenthesized binding + type list |
| Parameter type errors | `def f(x: number)` | Runtime message includes `parameter #N` |

## Added in v1.0.0

| Feature | Syntax | Notes |
|---------|--------|-------|
| `struct` | `struct Point ... end` | Typed table constructor; `Point { x = 1 }` call syntax |
| `import` | `import m from "path"` | Sugar over `require`; script-local binding |
| Table call syntax | `f { k = v }` | Lua-style call with table literal argument |

## Added in v1.1.0  

| Fix / feature | Notes |
|---------------|-------|
| `--` line comments | After a statement ending in an identifier, a comment on the **next line** is no longer parsed as postfix `--` |
| Chained table assign | `matrix[i][j] = value` and deeper index chains |
| `global` lists | `global a, b` (comma-separated); stray `global C0global C9` is a compile error |

## Added in v1.1.1

| Feature | Syntax | Notes |
|---------|--------|-------|
| Struct field errors | — | `field 'y' expected number, got string` |
| Optional struct fields | `y: number = 0` | dialect ≥ 10 |
| Struct methods | `def length(self) ... end` | Attached per instance; dialect ≥ 10 |
| `enum` | `enum Color { Red, Green }` or `end` form | Global table `Color.Red == 0`; dialect ≥ 10 |

## Added in v1.1.2

| Feature | Syntax | Notes |
|---------|--------|-------|
| Named import | `import { a, b } from "path"` | Desugars to `require` + field bindings; dialect ≥ 10 |

## Added in v1.2.0  

| Feature | Syntax | Notes |
|---------|--------|-------|
| `[doc: "..."]` | Before `def` / `struct` | Metadata; `--dump` shows `; doc "..."` |
| `import * as m` | `import * as M from "path"` | dialect ≥ 11 |
| `import { a as b }` | Rename on import | dialect ≥ 10 |
| Struct type names | `def f(p: Vec2)` | Custom ident → runtime `table` check; dialect ≥ 11 |

## Added in v1.3.0  

| Feature | Syntax | Notes |
|---------|--------|-------|
| `@doc("...")` | Before `def` / `struct` | Sugar for `[doc: "..."]`; dialect ≥ 12 |
| `[deprecated]` | Before `def` / `struct` | Compile-time `[warn]`; `--dump` shows `; deprecated` |
| Struct field `[doc]` | Before field name | Instance `_fielddocs` table; dialect ≥ 12 |
| `enum Name: number` | After enum name | Explicit member type; dialect ≥ 12 |
| Chained `.` access | `a.b.c` | Member chains in expressions |
| `--unlimited` | CLI flag | Disables loop/instruction/call-depth limits (`0` = unlimited) |
| Script header `unlimited` | `-- vyrn: 12 unlimited` | Same as `--unlimited` |
| `--max-loops N` / `--max-ins N` | CLI flags | Override execution limits per run |
| Script header `bench` | `-- vyrn: 12 bench` | Same raised limits as `--bench` |

## Added in v1.3.1  

| Feature | Notes |
|---------|-------|
| Dynamic globals | Compiler + VM global tables ReDim in chunks of 128 |
| Dynamic locals | Per-function local name/slot tables ReDim in chunks of 64 |

## Added in v1.3.2  

| Feature | Notes |
|---------|-------|
| GC root expansion | Marks closed upvalues; stack scan includes active frame locals and open upvalue slots |
| `--strict` / header `strict` | Compile-time literal checks for `let`/`const`, param defaults, annotated `return` |
| CLI `--strict` | Same as script header `strict` |

## Added in v1.4.0  

| Feature | Notes |
|---------|-------|
| Strict inference | `--strict` tracks locals + arithmetic/compare/concat at compile time |
| `file` type alias | Parsed as `table`; for `io.open` results |
| IO file objects | `io.open` returns table with `_handle`, `:read`, `:write`, `:close`, `:flush`, `:lines` |
| `io.*` compatibility | `io.read(f)`, `io.close(f)` accept table or legacy number handle |

## Added in v1.4.4 – v1.4.7  

| Project | Description |
|------|------|
| Struct infer in paren calls | `(cb)(p)` and `(cb)(Vec2{…})` pass strict checks; `CompileTable` pushes struct id when `ActiveStructLiteralFuncId` is set |
| Multiline call style | `cb` on one line and `(args)` on the next compile as one call (except `let` initializers; see `LineBoundPostfix`) |
| `LineBoundPostfix` | Only on `let` rhs: blocks postfix `()`/`{}` from attaching across lines (fixes `let cb = twice` + `(cb)(3)` misparsed as `twice(cb)`) |
| Ident call strict | Expression statements `foo(arg)` route through `CompileCall` for compile-time arg checks |
| Paren callee strict | Compile-time checks for dynamic/upvalue `(cb)(arg)` |
| Upvalue func metadata | `FuncIdForBinding`, `EnclosingFuncIds` chain; `ResolveCalleeFuncId` for non-ident callees |

## Added in v1.4.8  

| Feature | Notes |
|---------|-------|
| Strict struct error names | Mismatches show struct names (e.g. `expected Vec2, got number`) for parameters and `let name: Struct` bindings |

## Added in v1.4.9  

| Feature | Notes |
|---------|-------|
| Runtime struct type names | `OP_CHECK_TYPE` reports struct names (e.g. `expected Vec2, got number`); struct instances store `_typename` |
| Runtime struct identity | When `_typename` is present, parameter checks compare struct names (e.g. `Vec2` vs `Point`) |

## Added in v1.5.0  

| Feature | Notes |
|---------|-------|
| `OP_CHECK_RET` struct names | Return type `-> Vec2` uses struct id encoding; errors show struct names |
| Plain table vs struct | Struct parameters/returns require `_typename`; anonymous tables fail at runtime |
| Struct field read strict | `v.x` updates compile-time infer from struct metadata (`let n: number = v.x`) |
| Eval `--strict` header | `RunEval` / `--eval-file` parses script header flags including `strict` |

## Added in v1.5.1  

| Feature | Notes |
|---------|-------|
| Strict struct returns | `return` under `--strict` checks `-> Vec2` at compile time; `return callee()` compares struct return metadata |

## Added in v1.5.9  

| Feature | Syntax | Notes |
|---------|--------|-------|
| `vyrn build` | `build [target] [-f build.vyrn] [--force]` | Evaluates `global build` table; runs `cmd` per target; `[skip]` when `outs` are up to date |
| `vyrn bundle` | `bundle <entry.vyrn> [-o out.vyrn]` | Inlines `require` / `import` graph into one script |
| `--tree-shake` | bundle flag | Prunes unused `def` exports per named import graph |
| `--source-map` | bundle flag | Writes `<out>.map` JSON (version 1; stub mappings) |
| `vyrn serve` | `serve <script.vyrn> [--port N] [--duration SEC]` | WebSocket server on `127.0.0.1`; script defines optional handlers |
| `on_ws_connect` / `on_ws_message` / `on_ws_close` | global `def` | Message handler return value is sent as text reply; `on_ws_connect` returning `false` responds with HTTP 403 (no upgrade) |
| `on_tick(dt)` | global `def` | ~100ms poll callback; `dt` in seconds |
| `ws.send` / `ws.broadcast` | builtins | Push text to one or all connected clients |

## Added in v1.5.10  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Opcode histogram | `--opcode-hist` / header `opcode-hist` | Top-20 opcode counts after run; diagnostic only |
| Increment peephole | `i = i + 1`, `i += 1`, `i -= 1`, `i -= 1` | `INC_LOCAL` / `DEC_LOCAL` (or global) instead of load/add/store |

## Added in v1.5.11  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Tuple call fast path | `let a, b = f()` | `CALL_SET_MULTI` when callee return arity matches binding count (single RHS expr) |
| Observed return arity | `return a, b` | Inferred arity for unannotated `def` used by the fast path |

## Added in v1.5.12  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Global tuple call fast path | REPL `let a, b = f()` | `CALL_SET_MULTI_GLOBAL` |
| Augment peephole | `i += C`, `i = i + C` | constant `C` ≠ 1 |
| Build mtime skip | `ins = {...}` in target | skip when outs newer than ins + dep outs |

## Added in v1.6.0  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Coroutines | `coroutine.create(f)`, `coroutine.resume(co, ...)`, `coroutine.yield(...)`, `coroutine.status(co)` | Table-backed snapshots; main thread save/restore |
| Yield statement | `yield expr` | Opcode `OP_YIELD` (#56); `yield` outside coroutine is a runtime error |

## Added in v1.6.1  

| Feature | Syntax | Notes |
|---------|--------|-------|
| Coroutine wrap | `coroutine.wrap(f)` | Returns a function that resumes the coroutine; same `true, ...` / `false, err` convention as `resume` |
| Running coroutine | `coroutine.running()` | Returns the active coroutine table, or `nil` on the main thread |
| Yieldable check | `coroutine.isyieldable()` | `true` while executing inside a coroutine |
| Error propagation | `coroutine.resume` / wrap call | On error: `false, message`, coroutine status `dead` |

## Added in v1.6.2  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Multi-return as call arg | `print(f())`, `g(a(), b)` | Last arg expands all returns; earlier multi-return args keep first value only |
| Coroutine close | `coroutine.close(co)` | Suspended → dead; running → `false, err`; dead → `true` |

## Added in v1.6.3  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Builtin multi-return args | `print(coroutine.resume(co))` | `returnArity` on builtins; variable builtins use `OP_CALL_MULTRET` |
| WS + coroutine | `on_ws_message` + `coroutine.resume` | Staged handler |

## Added in v1.6.5  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Non-callable call error | `x()` when `x` is not a function | Runtime `attempt to call a <type> value` (tables included) |
| Statement-bound postfix calls | `f(x)` or `(cb)(p)` then newline `(...)` | Expression statements (IDENT-led and paren-led) do not glue a next-line `(...)` / `{...}` onto the previous result |
| Upvalue call without meta warn | `w()` when upvalue lacks callable/FuncId meta | Compile-time `[warn]`; as of 1.6.6 call-arg sites also expand via conservative VAR |
| Non-tail return truncation | `return f(), g` / `yield f(), g` | Mid multi-return expressions keep only the first result |
| Late upvalue FuncId/struct | `cb = accept` then nested `cb(p)` under `--strict` | Store refreshes FuncId / file / struct metadata for later call sites |
| Strict multi-return bytecode | `CALL_MULTRET` / `TRUNC_LAST_CALL` | Nested builtin calls compile explicit stack behavior; `OP_CALL` no longer scans for a misplaced function |

## Added in v1.6.6  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Call-before-bind wrap expand | `print(w())` before `w = coroutine.wrap(f)` | No-meta upvalue calls use conservative VAR (`_varret_unknown`) + `[warn]`; outer call gets `CALL_MULTRET` |
| Indirect no-meta hygiene | `(w)()`, `w{}` | Flag cleared on `.` / `[]`; paren/brace call sites warn like IDENT |
| File-start LineBound | first stmt `print(...)` | Regression for `TokPos=0` / `CurLine` |
| `select` / `unpack` | `select(n, a, b, ...)`, `select("#", ...)`, `table.unpack` / `unpack` | Explicit-arg `select` (no `...` varargs yet); VAR arity |
| Strict wrap/upvalue matrix | `strict_wrap_upvalue_matrix` | Early / late / before-bind / paren / late FuncId |

## Added in v1.6.7  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Varargs | `def f(a, ...)`, `...`, `select("#", ...)` | Extras packed into `__va`; `OP_UNPACK_LOCAL` expands |
| Strict no-meta upvalue | statement / `return w()` under strict | Hard error; call-arg sites still warn + conservative VAR |
| Runtime type checks | `OP_CHECK_TYPE` / `OP_CHECK_RET` | Emitted only under `--strict` / `vyrn: N strict` (non-strict annotations are unchecked at runtime) |
| `table.pack` / `next` | `table.pack(...)`, `next(t [, k])` | Pack sets `n`; `next` is VAR multi-ret |
| WS client timeouts | test runner TcpClient | 5s connect/read |

## Added in v1.6.8  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Struct dense-only SET | `OP_SET_STRUCT_FIELD` | No string dual-write; `.field` still dense get |
| Struct `t["x"]` / `pairs` | StructMeta + TableGet/NextPair | Named keys via `_typename`; compile-known `t["field"]` → struct field ops |
| Dense-only follow-ups | method / REPL / wrap | `self` typed; methods after fields; REPL keeps struct meta; user `wrap` ≠ builtin |
| Leaf user-call setup | VM | Skip pack/param copy when non-vararg and args complete |
| Numeric opcode fast path | VM | In-place number arith; insn map base cache |

## Added in v1.6.9  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| `ipairs` skips struct fields | `ipairs(p)` | Starts after field count; pure structs yield nothing; use `pairs` for names |
| Strict bracket field assign | `p["x"] = v` under `--strict` | Same field-type check as `p.x = v` when key is a string literal |
| Dense-only edge tests | `struct_dense_compat`, REPL chunks | Dynamic keys, pairs meta, ipairs extra slot |
| Struct field bench | `bench_struct_field.vyrn` | Hot `.field` / dense literal path |

## Added in v1.6.10  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| `table.fields(t)` | `table.fields(p)` | Struct → ordered names; plain table → non-`_` string keys; ID `-270` |
| Table hash overflow band | bootstrap libs | Overflow starts past inline metas; no stale get from empty probe slots |
| Bench limits | `bench_limits.txt` | Caps for `bench_struct_field`, `bench_multret_wrap`, tighter `benchmark.vyrn` |
| `--dump` dense slots | `; dense N name` | 1-based dense index for `GET/SET_STRUCT_FIELD` |
| Strict dynamic bracket | `p[k]=v` under `--strict` | Non-literal / unknown key → hard error; literal known fields still type-check |
| `_typename` | StructMeta | Runtime identity for `pairs` / type checks; omitted from `table.fields` |

## Added in v1.6.11  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Native DLL C ABI 2 | `include/vyrn.h` / `Vyrn.dll` | multi-ret, globals, table get/set, limits, print logger |
| Embed host ID range | `-200..-263` | Excluded from `Builtin_IdToSlot` so host callbacks dispatch correctly |

## Added in v1.6.12  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Native DLL C ABI 3 | `include/vyrn.h` / `Vyrn.dll` | error codes, `vyrn_copy_string`, coroutine host APIs |
| C++ full demo | `examples/native/cpp/demo.cpp` | multi / table / logger / coroutine / error codes |

## Added in v1.6.13  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| StructMeta cache | table meta | `tid→smid` cache; refresh on `_typename` set / clear |
| GC mark by metaIdx | GC | alive/marked arrays; no list scan per `MarkTable` |
| Faster call/return stack | VM | in-place RETURN/YIELD; move returns onto call slot; PlaceReturnsAt for builtins |
| Flat user CALL dispatch | VM | Ordinary script `OP_CALL*` continue in the same `RunFunc` loop (no nested host call); `pcall` / host invoke still nest |
| `OP_CALL_KNOWN` | VM / compiler | Known non-closure `def`/`let` callee: skip callee load; insn `b` = funcId |
| `OP_LE_LOCAL_K_JMP` | VM / peephole | `local[a&255] <= const[(a>>8)&255]`; else jump to `b` |
| `OP_LE_LOCAL_I_JMP` | VM / peephole | same with u8 immediate in `a` mid-byte |
| `OP_LOAD_LOCAL_SUB_K` | VM / peephole | push `local[a] - const[b]` |
| `OP_LOAD_LOCAL_SUB_I` | VM / peephole | push `local[a] - b` (u8 imm) |
| `OP_RETURN_LOCAL` | VM / peephole | return `local[a]` (fused load+return) |
| `OP_CALL_KNOWN_1` | VM / peephole | `CALL_KNOWN` with argc=1; `a`=funcId |
| `OP_CALL2_ADD_KNOWN` | VM / peephole | `f(local-imm1)+f(local-imm2)`; `a`=funcId, `b` packs lid/imm1/imm2 |
| `OP_CALL2_ADD_RET` | VM / peephole | same as `CALL2_ADD_KNOWN`, then return 1 from the current frame |
| `fastBaseImm` | Compiler / VM | Prologue `LE_LOCAL_I_JMP`+`RETURN_LOCAL` → call sites skip frame when arg ≤ imm |
| `OP_LE_JMP_FALSE` / `OP_LT_JMP_FALSE` | VM / peephole | pop2 + compare; jump to `a` if false (`b=1` swaps for GE/GT) |
| Stack Drop / PushNumber | VM | POP/jumps avoid CopyValue; LEN/PUSH_*/LOAD_* write stack directly |
| LOAD_LOCAL number fast-path | VM | number locals/globals/enclosing via `PushNumber` |
| get2d/set2d RB emit | Compiler | bare-ident + row-base → no POP/SWAP reshape |
| Power-of-2 table hash | `HashStringKey` / probe | `& (cap-1)` when capacity is 2ⁿ; number keys skip string `KeyEquals` |
| Dense / string GET_TABLE | VM | peek-stack dense number path; separate string-key branch |
| SET_TABLE / SET_STRUCT_FIELD peek | VM | leave table on stack; dense number → `TableSetDense` |
| GET2D_RB dense number | VM | peek + `TryGetDenseNumber` (no triple Pop) |
| Skip get2d/set2d method load | Compiler | inline path does not emit `table.get2d` GET_TABLE |
| `OP_GET2D_RB_LLL` / `SET2D_RB_LLLL` | peephole | locals-packed 2D get/set (no LOAD×3/4) |
| `OP_GET_TABLE_LL` / `SET_TABLE_LL_K` | peephole | `t[k]` / `t[k]=const` from local lids |
| `OP_ACCUM_MUL_GET2D_LLL` | peephole | `sum += get2d_lll * get2d_lll` |
| `OP_STORE_MUL_LOCAL_SUB_I` | peephole | `local[dst]=(local[sub]-imm)*local[mul]` |
| `OP_LE_LOCAL_LOCAL_JMP` / `INC_LOCAL_JMP` | peephole | counted-loop compare / inc+back-edge |
| `OP_ADD_LOCAL_LOCAL_STORE` | peephole | `local[dst]+=local[src]` |
| Nil-stub call elision | Compiler | empty `return` funcs skip args; `PUSH_NIL`+`POP` deleted |
| CALL_KNOWN fallback insert | Compiler | if upvalues appear during args, insert callee LOAD before args |
| CALL_KNOWN nested defer | Compiler | `f(g())` stacks deferred callee loads so both sites can emit `CALL_KNOWN` |
| Dense number CopyValue skip | Value | `TableSetDense` / `TableTryGetDense` avoid string field assign |
| Open-address hash probe | Value | first empty slot ends probe (no tombstones) |
| GC clear marks | GC | scan `TableAlive[]` instead of `ForEach` tables list |
| In-place CONCAT | `OP_CONCAT` | `string..string` / `string..number` / `number..string` without generic BinaryOp |

## Added in v1.6.26  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| `tonumber` | `tonumber(v [, base])` | Decimal string or integer with base 2..36 |
| math | `max`/`min` n-arg; `log`/`exp`/`log10`; `math.huge` | Complements existing `math.pi` |
| path | `isdir` / `isfile` / `ext` / `mkdir` | Windows helpers |
| table | `keys` / `values` / `copy` | Shallow copy for number/string keys |

## Added in v1.6.27  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| string | `contains` / `match` / find+gsub multi-ret | Plain substring (not Lua patterns) |
| math | `modf` / `atan`[,`atan2`] | Multi-ret `modf` |
| table | `slice` / `move` | Lua-like array helpers |

## Added in v1.6.28  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| string | `byte` range multi-ret | Cap `#LuaLite_MaxReturnTypes`; OOB → nil |
| table | `clear` | Keeps table alive |
| os | `exit([code])` | CLI process exit; unsafe in embeds |
| io.lines | eager table | Documented (not Lua iterator); strip `\r` |
| Strict wrap returns | `return w()` | Inner FuncId stashed on wrap binding |
| EQ peepholes | `EQ_JMP_FALSE` / `GET_TABLE_LL_EQ_K_JMP` | Sieve-style `t[k] == const` |
| Version SoT | `VERSION` file | Aligns Dialect / NuGet / pack_release |

## Added in v1.6.29  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| table.insert mid | `insert(t,pos,v)` | Shifts array tail |
| math.random fix | `random(m,n)` | Inclusive `m..n` |
| math | `asin` / `acos` / `clamp` | Domain-checked inverse trig |
| path.cwd | `path.cwd()` | GetCurrentDirectory |
| Typed yield | `yield` under `--strict` | Matches `->` / `return` checks |
| SET_TABLE_LL_K_ADD | peephole | Sieve clear stride |
| vyrn_version | native API | Product string; ABI stays 3 |

## Added in v1.6.30  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Console flush | Runtime / CLI | Avoids missing `[timing]` under redirected stdout |
| create→resume types | `coroutine.create` + typed `resume` | Stashes worker FuncId for `--strict` |
| Stdlib boundary | Builtins.md | Explicit out-of-scope: `debug.*`, `string.pack`, … |

## Added in v1.6.31  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| create rebind types | `co = coroutine.create(g)` | Infer-stash `coroutine.thread` + worker FuncId |
| Embed error table | `VYRN_ERR_*` | Documented in Embed.md |
| typed_tour coroutines | examples/vyrn | yield / wrap / resume / rebind |

## Added in v1.6.33  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Minigame isolation | embed host | Continue after `on_tick` script error |

## Added in v1.6.35  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| math | `sign` / `lerp` / `remap` / `atan2` | Game-tick helpers; `atan2` ≡ two-arg `atan` |
| path | `mkdirs` / `rmdir` | Recursive parents / recursive remove |
| xpcall / GC | `xpcall`, `collectgarbage` | msgh on failure; `count` = live table count |

## Added in v1.6.36  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| CLI smoke timeouts | run_tests | External process + WS port poll |
| IDE compile gate | `build_ide.ps1` | Local full gate / `vyrn-pb`; not on SaaS runners |
| Cooperative cancel | `vyrn_request_cancel` | ABI 5; IDE Stop; `VYRN_ERR_CANCELLED` |

## Added in v1.6.37  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| string | `replace` / `padleft` / `padright` | Plain replace with optional count; pad helpers |
| table / path | `table.assign` / `path.abspath` | Shallow merge into dst; absolute path |

## Added in v1.6.38  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| raw* | `rawget` / `rawset` / `rawequal` | Direct table access; identity eq for tables/funcs |
| os.setenv | `os.setenv(name, value\|nil)` | CLI only; DLL/IDE reject like `os.exit` |

## Added in v1.6.39  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| path | `path.chdir` | Change cwd |
| io | `file:seek` / `io.seek` | Byte seek set/cur/end |

## Added in v1.6.40  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| Upvalue mutate | `++` / `+=` / `x = x ± N` | Unified `EmitNameNumericDelta`; no `INC_GLOBAL` shadow |
| WS surface | `send` string id / `send_binary` / HTTP www | Opcode-2 + max-clients refuse |
| Native header | `include/vyrn.h` | File banner: ABI, string lifetime |

## Added in v1.6.41  

| Feature | Syntax / API | Notes |
|---------|--------------|-------|
| path size/mtime/copy | `path.size` / `mtime` / `copy` | File metadata + copy |
| file:read byte count | `f:read(n)` / `io.read(n)` | Lua-like; legacy `io.read(handle, mode)` kept |
| WS handshake hygiene | serve accept path | Id assigned on upgrade; probes skip `on_ws_close` |

## Limits  

Canonical hard caps for the PB compiler / VM and VYBC load (libvyrnrt shares the same bytecode rules unless noted).  

### Compile unit / bytecode

| Limit | Value | Notes |
|-------|------:|-------|
| Functions per program | **64** | `#Vyrn_MaxCompiledFuncs`. Includes `<main>`, nested `def` / closures, and functions from every loaded `.vyrnc` / `require` module merged into the same VM. Exceeding it is not a soft compile error today — fixed insn/metadata slabs can **Invalid memory access**; keep well under 64 per unit or split with `require`. |
| Instructions per function (slot) | **8192** | `#Vyrn_MaxInsnPerFunc`. A larger function may load only as the **last** function in a blob (spill into the next slot window); otherwise VYBC load reports too large / split it. |
| Constants per function (slot) | **512** | `#Vyrn_MaxConstPerFunc`. Same last-function spill rule as instructions. |
| Global constant pool (compile) | starts **4096**, grows | `Vyrn_MaxConstants`; ReDim as needed. |
| Parameters per function | **32** | `#Vyrn_MaxFuncParams`. Embed C API max args: `VYRN_MAX_ARGS` **16** (`include/vyrn.h`). |
| Locals + parameters per function | **65535** | Ship / VYBC refuse overflow; compiler arrays start smaller and grow. Capturing local index ≥ 256 writes VYBC v4. |
| Upvalues per function | **255** | `#Vyrn_MaxUpvaluesPerFunc`; pass-through captures count. Compile error with `file:line`. |
| Enclosing / nesting depth | **16** | `#Vyrn_MaxEnclosingDepth`. A 17th nested function: `functions nested too deeply (limit 16 enclosing functions)`. |
| Return-type annotations | **16** | `#Vyrn_MaxReturnTypes` (separate from the 4096 runtime multi-value cap). |
| `let` destructure binds | **32** | `#Vyrn_Compiler_MaxLetBinds`. |
| Assignment targets | **64** | `too many assignment targets (max 64)`. |
| Struct metas / fields | **64** / **32** | `#Vyrn_MaxStructMetas` / `#Vyrn_MaxStructFields` (PB and libvyrnrt). |
| Opcode table | **86–100** | Load accepts `#Vyrn_MinOpcodeTable`..`#Vyrn_MaxOpcode`; newer tables rejected. |
| Source file size | none | Whole file → one string (`Vyrn_Runtime_ReadFile`, whole-file read since 1.6.150). Bounded by RAM / host string limits, not a Vyrn constant. |

### Runtime  

| Limit | Value | Notes |
|-------|------:|-------|
| Call depth | **256** default | `Vyrn_MaxCallDepth`. `--unlimited` / header `unlimited` lifts it; hard ceiling **200000** frames (`#Vyrn_FrameHardCap`). |
| Loop / instruction counters | **none** by default | Since 1.6.112. Opt in: `--max-loops N` / `--max-ins N`, `vyrn_set_limits` / `vyrnrt_set_limits`. `--bench` raises a set limit to 2e9. |
| Multi-values | **4096** | Returns, `...`, `select`, `table.unpack`, `pcall` / `xpcall`, coroutine resume / yield / wrap. `table.unpack` over 4096 raises `too many results to unpack`. |
| Stack / locals / globals | grow | Initial stack **4096**, locals **256**, globals **512**; ReDim on demand. |
| Dense table int keys (PB) | up to **2²⁵** | Larger int keys go to the hash tail. libvyrnrt dense max **2²⁴**. |
| `#t` / array length | no cap | First-boundary length (1.6.105+); no 4096 ceiling. |
| Wall clock | `--timeout SEC` | Sampled periodically; host cancel via `vyrn_request_cancel`. |

## Developer tools  

| Flag | Purpose |
|------|---------|
| `--dump` | Print bytecode for a script (compile only) |
| `--repl` | Interactive read-eval-print loop |
| `-e` / `--eval` | Evaluate source (multi-line ok; REPL-style global `let`) |
| `--batch` | No “Press Enter” pause; for CI and scripts |
| `--bench` | Raise VM loop/instruction limits for long benchmarks |
| `--unlimited` | Disable loop, instruction, and call-depth limits (trusted scripts only) |
| `--strict` | Compile-time literal type checks (`let`/`const`/defaults/`return`) |
| `--timing` | Print `[timing] elapsed_ms=… instructions=…` after run |
| `--opcode-hist` | Print opcode execution histogram (top 20; profile only) |
| `--timeout SEC` | Wall-clock limit (sampled every `#LuaLite_GCInterval` steps) |
| `--max-loops N` | Override max back-edge / instruction-step loop guard |
| `--max-ins N` | Override max executed instructions |
| `build` | Run declarative `build.vyrn` targets (`[build]` / `[skip]`) |
| `bundle` | Merge entry + dependencies; optional `--tree-shake`, `--source-map` |
| `serve` | WebSocket server; optional `on_ws_*` / `on_tick` / `ws.*` in script |
