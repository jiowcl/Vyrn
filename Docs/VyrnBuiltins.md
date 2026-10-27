# VyrnBuiltins  

Unless noted, missing or wrong-typed arguments yield `nil` (or an error string via `Vyrn_LastError` for stricter APIs). Multi-return helpers use var arity (`#BUILTIN_RET_ARITY_VAR`).  

## Globals  

| Call | Returns | Notes |
| ------ | --------- | -------- |
| `print(...)` | `nil` | Space-separated `tostring` of each arg; newline |
| `type(v)` | string | `"nil"` / `"boolean"` / `"number"` / `"string"` / `"table"` / `"function"` |
| `tostring(v)` | string | Coerce to string |
| `tonumber(v [, base])` | number\|nil | Number as-is; decimal string (optional `base` 2..36 for integers); else `nil` |
| `require(mod)` | module | Load/cache a module (see import/`require` behavior in VyrnSpec) |
| `readline([prompt])` | string | Read a line from stdin |
| `pcall(f, ...)` | `ok, ...` | Protect call; first result is boolean success |
| `xpcall(f, msgh, ...)` | `ok, ...` | Like `pcall`; on failure calls `msgh(err)` for the payload |
| `error(msg [, level])` | — | Abort with message. 1.6.77: a string message gets a Lua-style `file:line: ` prefix (level 1 = caller of `error`, 2 = its caller, 0 = none; `pcall(error, msg)` adds none). Non-string messages are stringified. 1.6.77 String messages are now prefixed with a Lua-style `file:line: ` (level 1 = the caller of `error`, 2 = the caller's caller, 0 = no prefix; `pcall(error, msg)` also results in no prefix). |
| `assert(v [, msg])` | `v, ...` | Error if `v` is `nil`/`false` |
| `timer()` | number | High-resolution elapsed seconds (monotonic) |
| `collectgarbage([opt])` | bool\|number\|nil | `"collect"` (default) → run GC, `true`; `"count"` → approximate heap in KB (1.6.79: PB VM sums table headers + hash/dense storage; libvyrnrt also adds string bytes, so values are the same order of magnitude but not equal across runtimes) |
| `select(index, ...)` / `select("#", ...)` | var | Lua-style select; `select("#")` with no varargs is `0` (1.6.77). When there are no variable parameters `select("#")` 為 `0`。 |
| `rawget(t, k)` | value\|nil | Direct table get (`TableGet`); no metamethods (Vyrn has none); StructMeta field bridge same as `t[k]` |
| `rawset(t, k, v)` | table | Direct table set; returns `t`; key must be number or string |
| `rawequal(a, b)` | bool | Strict equality; tables/functions by identity (unlike `==`, which is false for tables) |
| `unpack(t [, i [, j]])` | var | Alias of `table.unpack` |
| `ipairs(t)` | iter, t, 0 | Array iterator factory |
| `pairs(t)` | iter, t, nil | Hash/array iterator factory |
| `next(t [, k])` | `k, v` or nil | Next key/value in table |

Internal iterators `ipairs_iter` / `pairs_iter` / `coroutine.wrap_call` are implementation details.  

## math  

Angles for `sin`/`cos`/`tan` are **radians**.

| Call | Returns | Notes |
|------|---------|--------|
| `math.floor(n)` | number | Toward −∞ |
| `math.ceil(n)` | number | Toward +∞ |
| `math.abs(n)` | number | Absolute value |
| `math.sqrt(n)` | number | Square root (`n >= 0`) |
| `math.max(...)` | number | N-arg max (at least one number) |
| `math.min(...)` | number | N-arg min (at least one number) |
| `math.sin(n)` / `math.cos(n)` / `math.tan(n)` | number | Trig |
| `math.deg(n)` / `math.rad(n)` | number | Radians ↔ degrees |
| `math.pow(a, b)` | number | `a ^ b` |
| `math.fmod(a, b)` | number | Floating modulo |
| `math.round(n)` | number | Nearest integer |
| `math.log(n)` | number | Natural log (`n > 0`) |
| `math.log10(n)` | number | Base-10 log (`n > 0`) |
| `math.exp(n)` | number | `e^n` |
| `math.modf(n)` | `i, f` | Integer and fractional parts (toward zero) |
| `math.asin` / `acos` | number\|nil | Inverse trig; domain `[-1,1]` else nil |
| `math.atan(y [, x])` | number | `atan(y)` or IEEE `atan2(y, x)` |
| `math.atan2(y, x)` | number | Alias of two-arg `math.atan` (IEEE order) |
| `math.clamp(n, lo, hi)` | number | Clamp `n` into `[lo,hi]` (swaps if `lo>hi`) |
| `math.sign(n)` | number | `-1` / `0` / `1` |
| `math.lerp(a, b, t)` | number | `a + (b - a) * t` (t not clamped) |
| `math.remap(v, inLo, inHi, outLo, outHi)` | number | Linear map; if `inHi==inLo` returns `outLo` |
| `math.random([m [, n]])` | number | No args: discrete ≈`[0,1)`; `random(n)` → `1..n`; `random(m,n)` → `m..n` inclusive |
| `math.randomseed(n)` | nil | Seed PRNG |
| `math.pi` | number | π constant |
| `math.huge` | number | Large finite (`1E308`), not IEEE ∞ |

## string

Indices are **1-based**. Negative indices count from the end (Lua-style) where supported.

| Call | Returns | Notes |
|------|---------|--------|
| `string.len(s)` | number | Byte/character length |
| `string.upper(s)` / `string.lower(s)` | string | Case fold |
| `string.sub(s, i [, j])` | string | Substring |
| `string.find(s, pattern [, init [, plain]])` | `start, end, captures…`\|nil | Lua 5.4 pattern find (1.6.75); `plain=true` → literal substring |
| `string.match(s, pattern [, init])` | captures…\|nil | Lua 5.4 pattern match; returns all captures (or the whole match) |
| `string.gmatch(s, pattern)` | iterator | Lua iterator (1.6.77): each call returns the next match (whole match, or all captures as multiple values; `nil` when done). Use `for w in string.gmatch(s, "%a+")` / `for k, v in string.gmatch(s, "(%w+)=(%w+)")`. Available as a Lua iterator since 1.6.77 |
| `string.rep(s, n)` | string | Repeat |
| `string.reverse(s)` | string | Reverse |
| `string.trim(s)` | string | Strip leading/trailing whitespace |
| `string.char(...)` | string | Code points → string |
| `string.byte(s [, i [, j]])` | number…\|nil | Byte codes `s[i..j]` (multi-ret; OOB → nil); default `i=1`, `j=i` |
| `string.format(fmt, ...)` | string | Limited `printf`-style format |
| `string.gsub(s, pattern, repl [, n])` | `result, count` | Lua 5.4 pattern replace; `repl` string (`%0`–`%9`, `%%`), table, or function; second return is replacement count |
| `string.replace(s, old, new [, n])` | string | Plain replace; optional max count `n` (default all); empty `old` → unchanged `s` |
| `string.padleft(s, width [, pad])` | string | Left-pad to `width` (default pad `" "`); no-op if already long enough |
| `string.padright(s, width [, pad])` | string | Right-pad to `width` (default pad `" "`); no-op if already long enough |
| `string.startswith(s, prefix)` | bool | Prefix test |
| `string.endswith(s, suffix)` | bool | Suffix test |
| `string.contains(s, sub)` | bool | Substring test |
| `string.split(s, delim [, limit])` | table | Array of segments |

## table

Array part is 1-based. Dense 2D helpers store row-major cells (see VyrnSpec “Flat 2D matrices”).

| Call | Returns | Notes |
|------|---------|--------|
| `table.insert(t, [pos,] v)` | nil | Insert into array part; mid-`pos` shifts tail (Lua-like) |
| `table.remove(t [, pos])` | value\|nil | Remove; default last; OOB / empty → nil |
| `table.concat(t [, sep [, i [, j]]])` | string | Join array segment |
| `table.sort(t [, cmp])` | nil | In-place stable sort; optional `cmp(a,b)` → bool |
| `table.foreach(t, f)` | nil | Call `f(k,v)`; stop if non-`nil` return |
| `table.map(t, f)` | table | New array of `f(v)` / mapped values |
| `table.filter(t, f)` | table | Keep entries where `f` is truthy |
| `table.reduce(t, init, f)` | value | Fold `f(acc, k, v)` |
| `table.find(t, f)` | `k, v` or nil | First match |
| `table.index_of(t, v)` / `table.find_index(t, v)` | number\|nil | 1-based array search |
| `table.pack(...)` | table | Values + `n` field |
| `table.unpack(t [, i [, j]])` | var | Spread array segment |
| `table.fields(t)` | table | Struct field names / string keys |
| `table.keys(t)` | table | Array of all keys (iteration order) |
| `table.values(t)` | table | Array of all values |
| `table.copy(t)` | table | Shallow copy (number/string keys) |
| `table.assign(dst, src [, …])` | table | Shallow-copy number/string keys from each `src` into `dst`; returns `dst` |
| `table.slice(t [, i [, j]])` | table | New array of `t[i..j]` (1-based) |
| `table.move(a, f, e, t [, b])` | table | Copy `a[f..e]` onto `b` (default `a`) at index `t`; returns dest |
| `table.clear(t)` | nil | Remove all entries; table stays alive |
| `table.create2d(rows, cols [, fill])` | table | Dense `rows×cols` (default fill `0`) |
| `table.get2d(t, row, col, cols)` | value | Read cell (often fused to `OP_GET2D`) |
| `table.set2d(t, row, col, cols, val)` | nil | Write cell (often fused to `OP_SET2D`) |

## io

File handles are tables wrapping an internal slot. Modes follow common `"r"` / `"w"` / `"a"` (and `+` variants where implemented).

| Call | Returns | Notes |
|------|---------|--------|
| `io.open(path [, mode])` | file\|nil | Open file |
| `io.close([file])` | nil | Close handle / default output |
| `io.read(...)` | string\|nil | Read from default input (`"*l"` / `"*a"` / `"*n"` / byte count `n`) |
| `io.read_chunk([n])` | string\|nil | Bounded cooperative read |
| `io.seek(file [, whence [, offset]])` | number\|nil | Byte position; `whence` = `"set"` / `"cur"` / `"end"` |
| `io.write(...)` | nil | Write to default output |
| `io.flush([file])` | nil | Flush |
| `io.type(obj)` | string\|nil | `"file"` / `"closed file"` / nil |
| `io.input([file\|path])` | file\|nil | Get/set default input |
| `io.output([file\|path])` | file\|nil | Get/set default output |
| `io.lines([path])` | table | Eager array of lines (not a Lua-style iterator); strips trailing `\r` |
| `file:read` / `:write` / `:close` / `:flush` / `:lines` / `:read_chunk` / `:seek` | … | Methods on open file objects; `:read` accepts mode string or byte count `n`; `:lines` same eager-table semantics; `:seek` bytes from start |

## os

| Call | Returns | Notes |
|------|---------|--------|
| `os.clock()` | number | CPU/process seconds since start |
| `os.time([t])` | number | Unix time (optional table) |
| `os.date([fmt [, time]])` | string | Format time |
| `os.difftime(t2, t1)` | number | `t2 - t1` seconds |
| `os.getenv(name)` | string\|nil | Environment variable |
| `os.setenv(name, value)` | bool | Set env var; `nil` value removes it. CLI only — `Vyrn.dll` / IDE (`BlockOsExit`) → runtime error |
| `os.remove(path)` | bool | Delete file |
| `os.rename(old, new)` | bool | Rename/move |
| `os.execute(cmd)` | bool | Run shell command |
| `os.exit([code])` | — | Terminate process (CLI). In `Vyrn.dll` embeds: runtime error (does not kill host) |

## path

Windows-oriented helpers (normalize uses `\`).

| Call | Returns | Notes |
|------|---------|--------|
| `path.join(...)` | string | Join path segments |
| `path.dirname(p)` | string | Directory part (`"."` if empty) |
| `path.basename(p)` | string | File name |
| `path.exists(p)` | bool | File or directory exists |
| `path.isdir(p)` | bool | Directory exists |
| `path.isfile(p)` | bool | Regular file exists |
| `path.ext(p)` | string | Extension without dot (PB `GetExtensionPart`) |
| `path.mkdir(p)` | bool | Create directory (true if already a dir) |
| `path.mkdirs(p)` | bool | Create `p` and parents; true if ends as a directory |
| `path.rmdir(p)` | bool | Remove directory tree (recursive); true if absent afterward; refuses files |
| `path.cwd()` | string | Current working directory |
| `path.abspath(p)` | string | Absolute path (join cwd when relative; normalize separators) |
| `path.chdir(p)` | bool | Change working directory (must exist) |
| `path.size(p)` | number\|nil | File byte size (`nil` if missing / directory) |
| `path.mtime(p)` | number\|nil | Last-write Unix time (seconds); `nil` if missing |
| `path.copy(src, dst)` | bool | Copy file |
| `path.normalize(p)` | string | Slash normalize |
| `path.listdir(p)` | table | Directory entries |
| `path.glob(pattern)` | table | Glob matches |

## coroutine

Lua 5.x–style subset. Coroutine objects are tables with internal `_co_*` fields.

| Call | Returns | Notes |
|------|---------|--------|
| `coroutine.create(f)` | thread | Suspended coroutine |
| `coroutine.resume(co, ...)` | `ok, ...` | Resume; first result is success |
| `coroutine.yield(...)` | … | Yield from inside coroutine |
| `coroutine.status(co)` | string | `"suspended"` / `"running"` / `"dead"` / … |
| `coroutine.wrap(f)` | function | Resume wrapper |
| `coroutine.running()` | thread\|nil | Active coroutine |
| `coroutine.isyieldable()` | bool | True when inside a coroutine |
| `coroutine.close(co)` | bool | Close / tear down |

## ws

Used by the CLI `serve` WebSocket host. Plain `GET` without a WebSocket upgrade may serve static files from the script directory (or `--www`); `/` maps to `client.html`.

| Call | Returns | Notes |
|------|---------|--------|
| `ws.send(client, msg)` | bool | Text frame; `client` number or decimal string id |
| `ws.send_binary(client, msg)` | bool | Binary frame; payload is raw string bytes |
| `ws.broadcast(msg)` | number | Broadcast text; returns send count |

Incoming **binary** frames call `on_ws_binary(client_id, payload)` when defined; otherwise they fall back to `on_ws_message`. When the client table is full, new TCP connects are closed and a console line notes the limit.

## Out of scope (intentionally not provided)

These stay out of the stdlib so the VM stays small for embed / game hosts:

| Area | Reason |
|------|--------|
| `debug.*` | No debug library; use host tooling / dumps (`--dump`) |
| `string.pack` / `string.unpack` | Binary pack format is large; prefer host buffers |
| `os.setlocale` / `os.tmpname` | Locale and temp-name semantics are host-owned |
