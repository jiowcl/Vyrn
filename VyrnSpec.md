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

## Developer tools  

| Flag | Purpose |
|------|---------|
| `--dump` | Print bytecode for a script (compile only) |
| `--repl` | Interactive read-eval-print loop |
| `-e` / `--eval` | Evaluate source (multi-line ok; REPL-style global `let`) |
| `--batch` | No “Press Enter” pause; for CI and scripts |
| `--bench` | Raise VM loop/instruction limits for long benchmarks |
| `--unlimited` | Disable loop, instruction, and call-depth limits (trusted scripts only) |
| `--max-loops N` | Override max back-edge / instruction-step loop guard |
| `--max-ins N` | Override max executed instructions |