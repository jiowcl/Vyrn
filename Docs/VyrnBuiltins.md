# VyrnBuiltins  

Unless noted, missing or wrong-typed arguments yield `nil` (or an error string via `Vyrn_LastError` for stricter APIs). Multi-return helpers use var arity (`#BUILTIN_RET_ARITY_VAR`).  

## Globals  

| Call | Returns | Notes |
|------|---------|--------|
| `print(...)` | — (0 values) | Space-separated args; a table with `__tostring` uses that metamethod (not used by concat / `ValueToString`); otherwise `ValueToString`; newline |
| `type(v)` | string | `"nil"` / `"boolean"` / `"number"` / `"string"` / `"table"` / `"function"` |
| `tostring(v)` | string | Coerce to string; tables with `__tostring` use that metamethod (Lua 5.4: a string or a number, the number formatted like `tostring`; other types raise `'__tostring' must return a string`). Tables without a metatable still pretty-print `{...}`. |
| `tonumber(v [, base])` | number\|nil | Number as-is; a string with a Lua 5.4 numeral (decimal, exponent, hex, hex float; whitespace and sign allowed; 1.6.113); with `base` 2..36 an integer (leading `-` allowed); else `nil` |
| `require(mod)` | module | Load/cache a module. Search order (1.6.136): script dir, `VYRN_PATH`, `<exe dir>/lib`, `<exe dir>/../lib`, cwd. Default `package.path` includes `lib/?.vyrn`. Service clients are under `lib/`; see also VyrnSpec) |
| `readline([prompt])` | string\|nil | Read a line from stdin (optional string prompt, no newline; `nil` on EOF). **1.7.13:** also bound on libvyrnrt / Ship Compile (id `-136`; previously PB VM only). Trailing CR/LF are stripped. EOF is Ctrl+Z then Enter on a Windows console, and Ctrl+D on Linux. The PB VM uses `Input()` (Unicode); libvyrnrt reads raw stdin bytes (the console code page on Windows), same path as `io.read("*l")` but the line may grow past that 4096-byte buffer. |
| `pcall(f, ...)` | `ok, ...` | Protect call; first result is boolean success |
| `xpcall(f, msgh, ...)` | `ok, ...` | Like `pcall`; on failure calls `msgh(err)` for the payload |
| `error(msg [, level])` | — | Abort with message. 1.6.77: a string message gets a Lua-style `file:line: ` prefix (level 1 = caller of `error`, 2 = its caller, 0 = none; `pcall(error, msg)` adds none). Non-string messages are stringified. |
| `assert(v [, msg])` | `v, ...` | Error if `v` is `nil`/`false` |
| `timer()` | number | High-resolution elapsed seconds (monotonic) |
| `collectgarbage([opt])` | bool\|number\|nil | `"collect"` (default) → run GC, `true`; `"count"` → approximate heap in KB (1.6.79: PB VM sums table headers + hash/dense storage; libvyrnrt also adds string bytes, so values are the same order of magnitude but not equal across runtimes; 1.6.93: both add live closure and upvalue-cell bytes, and unreachable closures / cells are collected, so `count` goes down after a collection; libvyrnrt tables were not freed until 1.6.107). 1.6.104: the PB VM frees unreachable tables and reuses their ids/storage; `count` = live table metadata + dense/hash regions + strings stored in tables + closures/cells (it excludes the stack, globals array, code/constants, free-list capacity and strings not stored in tables); libvyrnrt did not free tables until 1.6.107. 1.6.107: libvyrnrt also frees unreachable tables (FIFO id reuse), `"collect"` runs a full table + closure collection, and `count` covers only live tables, their strings and closures/cells, so it drops after a collection on both runtimes (values still differ between runtimes). |
| `select(index, ...)` / `select("#", ...)` | var | Lua-style select; `select("#")` with no varargs is `0` (1.6.77). |
| `rawget(t, k)` | value\|nil | Direct table get (`TableGet`); bypasses `__index`; StructMeta field bridge same as raw `t[k]` |
| `rawset(t, k, v)` | table | Direct table set; returns `t`; key must be number or string |
| `rawequal(a, b)` | bool | Identity / raw equality; tables and functions compare by identity. Never calls `__eq` (1.6.139). `==` may call `__eq` when both operands are tables. |
| `rawlen(v)` | integer | 1.6.140: raw length of a table or string (Lua 5.4). Tables use the first-border array length; strings use UTF-8 byte length. Does not call `__len`. Errors `bad argument #1 to 'rawlen' (table or string expected)`. ID `-369`. |
| `setmetatable(t, mt\|nil)` | table | 1.6.138: attach or clear `t`'s metatable (Lua 5.4); errors if the current mt has a `__metatable` field. Returns `t`. IDs `-367` / `-368`. |
| `getmetatable(obj)` | value\|nil | 1.6.138 / 1.6.139: if `obj` is a table, return `mt.__metatable` when present, else the metatable or nil. If `obj` is a string, return the shared string type metatable (`getmetatable("").__index == string`; `__metatable` protection is honoured). Numbers and booleans return nil. `setmetatable` still requires a table; Lua's `debug.setmetatable` is not provided, so the string type metatable object cannot be replaced. |
| `unpack(t [, i [, j]])` | var | Alias of `table.unpack` (up to 4096 values, see table) |
| `ipairs(t)` | iter, t, 0 | Array iterator factory. 1.6.140: the iterator uses `t[i]` / `__index` (Lua 5.4 `lua_geti`). A packed array with no metatable stays on the cheap path (a nil-type check on hits). There is no `__ipairs` (removed in Lua 5.4). |
| `pairs(t)` | iter, t, nil | Hash/array iterator factory. 1.6.140: if `t` has a metatable with `__pairs`, `pairs(t)` calls `mt.__pairs(t)` and returns up to three values (missing results are nil). A table with no metatable (or no `__pairs`) uses the default iterator (one HasMt load). Non-tables still error immediately `table expected` (Lua delays that error until `next()`). The fourth Lua 5.4 to-be-closed return is not implemented. |
| `next(t [, k])` | `k, v` or nil | Next key/value in table (raw; does not call `__index` or `__pairs`) |

Internal iterators `ipairs_iter` / `pairs_iter` / `coroutine.wrap_call` are implementation details.  

## math  

Numeric arguments accept numeric strings as in Lua 5.4 (1.6.117).  

Angles for `sin`/`cos`/`tan` are **radians**.

| Call | Returns | Notes |
|------|---------|--------|
| `math.floor(n)` | integer\|float | Toward −∞; integer when the result fits (1.6.116) |
| `math.ceil(n)` | integer\|float | Toward +∞; integer when the result fits (1.6.116) |
| `math.abs(n)` | integer\|float | Absolute value; integer abs wraps on `mininteger` (1.6.116) |
| `math.sqrt(n)` | number | Square root (`n >= 0`) |
| `math.max(...)` | number | N-arg max (at least one number) |
| `math.min(...)` | number | N-arg min (at least one number) |
| `math.sin(n)` / `math.cos(n)` / `math.tan(n)` | number | Trig |
| `math.deg(n)` / `math.rad(n)` | number | Radians ↔ degrees |
| `math.pow(a, b)` | number | `a ^ b` (C `pow`, the same as the `^` operator since 1.6.113) |
| `math.fmod(a, b)` | number | Floating modulo; zero divisor raises `bad argument #2 to 'fmod' (zero)` |
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
| `math.randomseed(n)` | — (0 values) | Seed PRNG |
| `math.pi` | float | π constant (float subtype, 1.6.116) |
| `math.huge` | float | IEEE `inf` (1.6.116; was `1E308`) |
| `math.maxinteger` / `math.mininteger` | integer | `2^63-1` / `-2^63` (1.6.116) |
| `math.type(x)` | string\|nil | `"integer"` / `"float"` / `nil` (1.6.116) |
| `math.tointeger(x)` | integer\|nil | Exact integer conversion; strings accepted (1.6.116) |
| `math.ult(m, n)` | boolean | Unsigned `<` on two integers (1.6.116) |

## string

Indices are **1-based**. Negative indices count from the end (Lua-style) where supported. Since 1.6.112 lengths and positions are **UTF-8 bytes** on both runtimes, as in Lua (`#"héllo"` is `6`); use [`utf8`](#utf8) for characters.  

| Call | Returns | Notes |
|------|---------|--------|
| `string.len(s)` | number | Length in UTF-8 bytes (same as `#s`) |
| `string.upper(s)` / `string.lower(s)` | string | ASCII case fold (Lua C locale; other characters unchanged) |
| `string.sub(s, i [, j])` | string | Byte substring (a cut inside a character is lossy on the PB VM) |
| `string.find(s, pattern [, init [, plain]])` | `start, end, captures…`\|nil | Lua 5.4 pattern find (1.6.75); `plain=true` → literal substring |
| `string.match(s, pattern [, init])` | captures…\|nil | Lua 5.4 pattern match; returns all captures (or the whole match) |
| `string.gmatch(s, pattern)` | iterator | Lua iterator (1.6.77): each call returns the next match (whole match, or all captures as multiple values; `nil` when done). Use `for w in string.gmatch(s, "%a+")` / `for k, v in string.gmatch(s, "(%w+)=(%w+)")`. |
| `string.rep(s, n [, sep])` | string | Repeat `n` times; `n <= 0` returns `""` (Lua 5.4, 1.6.130). Optional separator `sep` between copies (1.6.115, Lua 5.2+) |
| `string.reverse(s)` | string | Reverse (bytes on libvyrnrt like Lua; characters on the PB VM) |
| `string.trim(s)` | string | Strip leading/trailing whitespace |
| `string.char(...)` | string | Bytes → string; `string.char(string.byte(s, 1, -1))` round-trips UTF-8 (a lone byte >= 128 is lossy on the PB VM). Use `utf8.char` for code points |
| `string.byte(s [, i [, j]])` | number…\|nil | Byte codes `s[i..j]` (multi-ret; OOB → nil); default `i=1`, `j=i`; negative `i` / `j` count from the end (1.6.106: `string.byte(s, 1, -1)` gives every byte, `string.byte(s, -1)` the last) |
| `string.format(fmt, ...)` | string | Lua 5.4 format: `%d %i %u %c %o %x %X %e %E %f %g %G %a %A %q %s %%`, flags, width, precision (see the note below) |
| `string.gsub(s, pattern, repl [, n])` | `result, count` | Lua 5.4 pattern replace; `repl` string (`%0`–`%9`, `%%`), table, or function; second return is replacement count |
| `string.replace(s, old, new [, n])` | string | Plain replace; optional max count `n` (default all); empty `old` → unchanged `s` |
| `string.padleft(s, width [, pad])` | string | Left-pad to `width` (default pad `" "`); no-op if already long enough |
| `string.padright(s, width [, pad])` | string | Right-pad to `width` (default pad `" "`); no-op if already long enough |
| `string.pack(fmt, ...)` | string | Lua 5.4 binary pack (1.7.7, builtins `-374`). See the pack note below |
| `string.unpack(fmt, s [, pos])` | values…, next pos | Lua 5.4 binary unpack (1.7.7, `-375`); `pos` is 1-based |
| `string.packsize(fmt)` | number | Size of a fixed-length format (1.7.7, `-376`); errors on `s` / `z` |
| `string.startswith(s, prefix)` | bool | Prefix test |
| `string.endswith(s, suffix)` | bool | Suffix test |
| `string.contains(s, sub)` | bool | Substring test |
| `string.split(s, delim [, limit])` | table | Array of segments |

**`string.pack` / `unpack` / `packsize` (1.7.7).** The format language matches Lua 5.4.8: endian `<` `>` `=`, alignment `!` / `!n` (default max alignment is 1 until `!`), options `bBhHlLjJT`, `i[n]` / `I[n]` (`n` in 1..16), `f` `d` `n`, `c[n]`, `s[n]`, `z`, `x`, `Xop`, and spaces. `packsize` is complete. `pack` / `unpack` only succeed when every stored byte is representable: **both official runtimes reject a NUL (`0x00`)** because values are C / PB strings without a length field. The official **PB VM** also rejects **invalid UTF-8**. Format `z` always needs a trailing NUL, so `pack` / `unpack` of `z` raise a clear storage error (Lua would succeed). `pack("x")`, short `c[n]` (zero-padded), and integer/float layouts that contain `0x00` likewise cannot be stored; `packsize` still reports their size. Prefer `<` / `>` and `i4` / `I4` / `f` / `d` in portable tests: `l` / `L` are 4 bytes on Windows (LLP64) and 8 on Linux x64, and `=` / `T` / `!` without a size follow the host. libvyrnrt can store invalid UTF-8 that is not a NUL (a runtime difference); do not rely on that in portable scripts.  

## utf8  

Lua 5.4 `utf8` library (1.6.112), strict mode, on both runtimes. Positions are 1-based UTF-8 byte offsets, the same as `#` and `string.*`.

| Call | Returns | Notes |
|------|---------|--------|
| `utf8.char(...)` | string | Code points → UTF-8 string (`0` to `0x10FFFF`, surrogates `0xD800`-`0xDFFF` rejected; Lua strict mode) |
| `utf8.len(s [, i [, j [, lax]]])` | number \| `nil, pos` | Characters that start in `s[i..j]`; on invalid UTF-8 returns `nil` and the byte position of the first bad byte |
| `utf8.codepoint(s [, i [, j [, lax]]])` | number… | Code points of the characters that start in `s[i..j]` (default `i=1`, `j=i`); invalid UTF-8 raises `invalid UTF-8 code` |
| `utf8.offset(s, n [, i])` | number \| nil | Byte position where the `n`-th character (counted from `i`) starts; `n = 0` finds the start of the character at `i`; negative `n` counts back |
| `utf8.codes(s [, lax])` | iterator | `for p, c in utf8.codes(s)` gives each byte position and code point; invalid UTF-8 raises |

`utf8.charpattern` is bound (1.6.117; leading `\0` omitted because Vyrn strings drop NUL — pattern starts at `\x01`). 1.7.4: optional `lax` (Lua 5.4; truthy like Lua) on `len` / `codepoint` / `codes` accepts surrogates and code points up to `0x7FFFFFFF` when the byte sequence is well-formed, and still rejects overlong / truncated / lone-continuation input. `utf8.offset` has no `lax` in Lua 5.4.8. The PB VM cannot store those non-Unicode sequences in strings (lossy UTF-8); libvyrnrt can when raw bytes exist. Internal iterator id -373. `utf8.char` still rejects surrogates and values above `0x10FFFF`. On the PB VM each `utf8.codes` step re-encodes the string (O(n) per step); use `utf8.codepoint(s, 1, -1)` for long strings in hot loops.  

## crypto  

Always available (1.6.119), like `utf8` — not gated on `--strict`. Digests and HMAC hash the **UTF-8 bytes** of the string argument and return **lowercase hex**. `crypto.random(n)` returns the lowercase hex of `n` CSPRNG bytes (not raw bytes), so results stay NUL-safe on both runtimes.  

| Call | Returns | Notes |
|------|---------|--------|
| `crypto.md5(s)` | string | MD5 digest as 32 hex chars (RFC 1321) |
| `crypto.sha1(s)` | string | SHA-1 digest as 40 hex chars (FIPS 180-4) |
| `crypto.sha256(s)` | string | SHA-256 digest as 64 hex chars (FIPS 180-4) |
| `crypto.hmac(algo, key, msg)` | string | HMAC hex; `algo` is `md5`, `sha1`, or `sha256` (case-insensitive) |
| `crypto.tohex(s)` | string | Lowercase hex of the UTF-8 bytes of `s` |
| `crypto.fromhex(hex)` | string | Decode hex to a string; raises on odd length, bad digits, NUL, or invalid UTF-8 |
| `crypto.tobase64(s)` | string | RFC 4648 Base64 (with `=` padding) |
| `crypto.frombase64(b64)` | string | Decode Base64; raises on invalid input, NUL, or invalid UTF-8 |
| `crypto.random(n)` | string | Hex of `n` cryptographically strong random bytes (`n` integer `0..1000000`) |
| `crypto.crc32(s)` | number | IEEE CRC-32 of the UTF-8 bytes (unsigned 32-bit value) |
| `crypto.tobase64_file(path[, opts])` | string \| `nil, err` | RFC 4648 Base64 of the file's raw bytes (1.6.126) |
| `crypto.tohex_file(path[, opts])` | string \| `nil, err` | Lowercase hex of the file's raw bytes |
| `crypto.frombase64_file(path, b64[, opts])` | `true` \| `nil, err` | Decode Base64 and write raw bytes to `path` (overwrite) |
| `crypto.fromhex_file(path, hex[, opts])` | `true` \| `nil, err` | Decode hex and write raw bytes to `path` (overwrite) |
| `crypto.md5_file(path[, opts])` | string \| `nil, err` | MD5 hex of the file's raw bytes |
| `crypto.sha1_file(path[, opts])` | string \| `nil, err` | SHA-1 hex of the file's raw bytes |
| `crypto.sha256_file(path[, opts])` | string \| `nil, err` | SHA-256 hex of the file's raw bytes |
| `crypto.crc32_file(path[, opts])` | number \| `nil, err` | IEEE CRC-32 of the file's raw bytes |

**File helpers (1.6.126).** These read or write the file in native code (PB `ReadData` / `WriteData`, libvyrnrt `fopen`) so NUL and non-UTF-8 bytes never pass through a Vyrn string. Use them for images, archives, or any binary payload. `opts.max` is the maximum file (or decoded) size in bytes; default **64 MiB**, hard cap **1 GiB**. A missing or non-regular file, a read/write failure, an oversize file, or invalid Base64/hex returns `nil, err` (same data-error style as `zlib`). Bad argument types and an out-of-range `opts.max` **raise**. This is deliberately different from string `frombase64` / `fromhex`, which still raise on invalid input, NUL, or invalid UTF-8 — those APIs only produce strings. Directory paths count as "file not found". File-to-file zlib helpers are documented in the [zlib](#zlib) section (1.6.129).

**Byte safety.** PB strings cannot hold a NUL byte or invalid UTF-8. `fromhex` / `frombase64` therefore raise on both runtimes when the decoded bytes contain a NUL or are not valid UTF-8, so scripts see the same errors. Digests never return raw binary. Not provided: `sha512`, raw-byte digest variants, or a binary `random` that can embed NUL.  

**Implementations.** PB: Fingerprint (MD5/SHA1/SHA2-256), Base64Encoder/Decoder, OpenCryptRandom; HMAC and CRC-32 are portable. libvyrnrt: `vyrnrt_crypto.c` (no external deps); CSPRNG is **BCryptGenRandom on Windows** and **`/dev/urandom` elsewhere**.  

## http  

**Capability-gated (1.6.120 / 1.6.121).** Network access is **off by default**. Enable with CLI `--allow-net` (all hosts) or `--allow-net=host1,host2` (exact host, optional `:port`), or `vyrn_set_capabilities(vm, VYRN_CAP_NET)` / `vyrnrt_set_capabilities(VYRNRT_CAP_NET)` plus optional `vyrn_set_net_allowlist` / `vyrnrt_set_net_allowlist`. Without the capability, every `http.*` call **raises** `network access is disabled (use --allow-net)`. A disallowed host **raises** `network access to host X is not allowed`.  

| Call | Returns | Notes |
|------|---------|--------|
| `http.get(url [, opts])` | table | `nil, err` | GET; `opts` may set `headers`, `timeout` (seconds), `encoding`, `save_path`, `on_chunk` |
| `http.post(url, body [, opts])` | table | `nil, err` | POST; body is a string; `opts` as above (body in opts also accepted). `http.post(url, { multipart = ... })` or `{ body_path = ... }` is also accepted |
| `http.request(opts)` | table | `nil, err` | `opts.method` (GET/POST/PUT/PATCH/DELETE), `opts.url` (required), `headers`, `body`, `body_path`, `save_path`, `timeout`, `encoding`, `multipart`, `max`, `max_total`, `on_chunk` |
| `http.stream(opts)` | table | `nil, err` | Same as `http.request`, but `opts.on_chunk` is required |
| `http.sse_events(text)` | array, leftover | raises | Parse SSE text into event tables; second return is the unparsed remainder |
| `http.serve(opts)` | table | raises | **1.6.156.** HTTP/1.1 listen (single-threaded). Needs `--allow-listen` / `VYRN_CAP_LISTEN`. Returns `{served=n}` when the accept loop stops |

**HTTP server (1.6.156).** `http.serve` is a separate capability from `http.get` / `request`. Enable with CLI `--allow-listen` (loopback binds only: `127.0.0.1`, `localhost`, `::1`) or `--allow-listen=host1,host2`, or `vyrn_set_capabilities` / `vyrnrt_set_capabilities` bit **`VYRN_CAP_LISTEN` / `VYRNRT_CAP_LISTEN` = 4** plus optional `vyrn_set_listen_allowlist` / `vyrnrt_set_listen_allowlist`. C# hosts use `VyrnVm.CapListen` and `SetListenAllowlist` / `GetListenAllowlist` ([Embed](Embed.md)). Without the capability, `http.serve` **raises** `http listen is disabled (use --allow-listen)`. A disallowed bind host **raises** `listen address X is not allowed`.  

`opts` fields: `host` (default `"127.0.0.1"`), `port` (1..65535, required), `handler` (function), `static_root` (directory string), `max_requests` (stop after N handled connections), `duration_ms` (wall-clock stop; see below). At least one of `handler` or `static_root` is required. The accept loop is blocking and single-threaded (no TLS).  

**Stop rules (1.6.159).** `max_requests > 0` and/or `duration_ms > 0` end the accept loop when hit (whichever comes first). **`duration_ms = 0`** (key present) means **forever** until process exit / Ctrl+C — the 30 s safety cap does **not** apply. If **both** `max_requests` and `duration_ms` are omitted (or non-number), the runtime still stops after **30 s** as a safety cap so forgetful scripts and CI do not hang. Negative `duration_ms` **raises**.  

`handler(req)` receives `{method=, path=, body=, headers={}}`. Return a string (status 200, `text/plain`), a table `{status=, body=, content_type=}`, or `nil` to fall through to `static_root`. Static paths reject `..` and absolute / drive forms; `/` maps to `index.html`. Official PB (Windows `NetworkServer`) and libvyrnrt (Winsock / POSIX sockets) share this API.  

**Multipart / form-data (1.6.127).** `opts.multipart` is an array of parts. Each part is a table with a required `name` and **exactly one** of `value` (text), `path` (file, read natively), `base64`, or `hex`. Optional `filename` and `content_type` apply to file / base64 / hex parts (`filename` defaults to the path's basename or `blob`; `content_type` defaults to `application/octet-stream`). A random `----VyrnForm` + 32-hex boundary is generated (retried if it appears in a payload). The request `Content-Type` is set to `multipart/form-data; boundary=...` and **replaces** any user `Content-Type`. `opts.body` and `opts.multipart` are mutually exclusive (raises). If `method` is omitted, multipart defaults to **POST**. `GET` / `HEAD` with multipart **raises**. File, base64, and hex bytes stay in native memory so NUL / non-UTF-8 never pass through a Vyrn string. `opts.max` is the per-part payload cap (default 64 MiB, hard cap 1 GiB). `opts.max_total` caps the encoded body including part headers (same default and hard cap).  

**Error policy (multipart).** Bad arguments (wrong types, missing `name`, more than one source, `body`+`multipart`, GET/HEAD) **raise**. A missing file, I/O failure, oversize part or body, or invalid base64 / hex returns **`nil, err`** (`http: file not found`, `http: part too large`, `http: invalid base64`, ...). Capability, host allowlist, timeout, and the redirect policy are unchanged: **307 / 308 resend the binary body**; 301 / 302 (non-GET/HEAD) and 303 switch to GET and drop it. Official Windows PB and both libvyrnrt stacks (WinHTTP / libcurl) share this behaviour. Non-Windows PB has no binary request-body transport (raises `http: binary request body is not supported on this platform`).  

**Raw file body / download-to-file (1.6.137).** `opts.body_path` sends a file's raw bytes as the request body (opened `rb`; no CRLF translation). The call does **not** invent a `Content-Type` — set one in `opts.headers` when the server requires it (Adobe pre-signed PUT uses the asset `mediaType`). Mutually exclusive with `opts.body` and `opts.multipart` (raises). Cannot be used with `GET` / `HEAD` (raises). `opts.max` caps the file size (default 64 MiB, hard cap 1 GiB). `opts.save_path` writes the raw response bytes to a file (opened `wb`; no CRLF translation) and sets `body` in the returned table to `""`. Mutually exclusive with `opts.on_chunk` (raises). `opts.max` also caps a `save_path` response; an oversize body returns `nil, err` and does **not** write a partial file. Official name is `body_path` / `save_path` only (no `body_file` / `out_path` aliases).  

**Error policy (body_path / save_path).** Bad types and the exclusive / GET-HEAD combinations **raise**. A missing file, I/O failure, or oversize file / response returns **`nil, err`** (`http: file not found`, `http: cannot open file`, `http: cannot read file`, `http: file too large`, `http: cannot write file`, `http: response body too large`). Official Windows PB (WinHTTP) and both libvyrnrt stacks (Windows WinHTTP / Linux libcurl) share this behaviour. Non-Windows PB raises `http: binary request body is not supported on this platform` when a binary body would be sent.  

**Response table.** `{ status = <int>, body = <string>, headers = { [name] = value, ... } }`. Header names keep the casing returned by the OS stack. On **network failure** (DNS, connection refused, no response) the call returns `nil, errmsg` — it does **not** raise. HTTP 4xx/5xx still return a response table.  

**Body encoding.** Default `encoding="text"`: the response bytes must be valid UTF-8 with no NUL, otherwise the call **raises** and suggests `opts.encoding='base64'` or `'hex'`. With `base64` / `hex`, the body field is the encoded form (identical on PB and libvyrnrt; hex is lowercase).  

**Streaming / SSE (1.6.128).** `opts.on_chunk` is a function called with each encoded chunk of the **final** (non-redirect) response body, on the VM thread. If it is set, `body` in the returned table is `""` (chunks are delivered to the callback, not accumulated). Return boolean **`false`** from the callback to stop early and close the connection; a missing return (`nil`) continues. Only boolean `false` stops. Errors raised in the callback propagate after handles are closed. Calling `http.get` / `post` / `request` / `stream` from `on_chunk` **raises** `http: cannot start a request from on_chunk`. `http.stream(opts)` is the same as `http.request` but requires `on_chunk`.  

Text mode buffers an incomplete trailing UTF-8 sequence across chunks and flushes a complete prefix each time; a leftover incomplete sequence at end-of-body **raises** the usual invalid UTF-8 error (unless the callback already stopped). Hex encodes each raw chunk independently (concatenating hex strings recovers the full body). Base64 buffers to a 3-byte boundary so concatenating the chunk encodings also recovers the full body; the last short group is flushed with padding when the stream ends.  

`http.sse_events(text)` parses WHATWG Server-Sent Events: `data:`, `event:`, `id:`, `retry:`, multi-line `data` joined with `\n`, comment lines starting with `:`, and `\n` / `\r\n` / `\r` line endings. A blank line dispatches one event table `{ event, data, id?, retry? }`. `event` defaults to `"message"` when omitted. `retry` is a number when the field is all digits. A leading UTF-8 BOM is skipped. The OpenAI `data: [DONE]` convention is left to the caller (it is just an event whose `data` is `"[DONE]"`). The second return is the unparsed leftover (incomplete event or partial line), so a stream consumer can do `acc = acc .. chunk; evs, acc = http.sse_events(acc)`.  

**Timeout.** `opts.timeout` is seconds (default 30, cap 600) and is an **overall** deadline for the whole request: connect, send, redirects, waiting for headers, reading the body, and time spent in `on_chunk`. There is no separate idle-timeout option. Expiry returns `nil, "http request timed out"` after cleanup. Official Windows PB already enforced this overall deadline with async WinHTTP; a streaming libvyrnrt request (WinHTTP or libcurl) uses the same overall deadline across hops and chunks. A non-streaming libvyrnrt WinHTTP request still uses per-operation `WinHttpSetTimeouts` (unchanged).  

**TLS / platforms.** `http://` and `https://` URLs are accepted. **Windows PB (1.6.123)** and libvyrnrt on Windows use **WinHTTP** (system trust store) so timeouts, encoding, headers, and redirect policy match. Non-Windows PB still uses asynchronous `HTTPRequest` / `HTTPMemory` and **raises** `http: streaming is not supported on this platform` if `on_chunk` is set, and `http: binary request body is not supported on this platform` for `body_path` / multipart. Linux libvyrnrt uses **libcurl** when CMake finds CURL (`VYRNRT_HAS_CURL`); otherwise soft-fails after allowlist checks (stub). Proxies follow the OS default. Capability, host allowlist, and redirect policy are unchanged: `on_chunk` is invoked only for the final response body, never for a 3xx hop that will be followed.  

**Allowlist / redirects (1.6.121–1.6.123).** `--allow-net=host1,host2` restricts requests to those exact hosts (case-insensitive); a bare host entry matches any port, `host:port` matches that port only. Plain `--allow-net` leaves the list empty (all hosts). Allowlist is checked on the **requested URL** before the call. **With a non-empty allowlist:** Windows PB and libvyrnrt (WinHTTP / libcurl) **disable auto-follow** and manually follow up to **5** redirects, re-checking each hop **before it is sent** (a disallowed hop raises `network access to host X is not allowed` and the target receives no request). Non-Windows PB `HTTPRequest` auto-follows then **re-validates** every `Location` in the header chain (same raise / hop cap; a hop may already have been sent). **Empty allowlist:** stacks keep default follow. Manual HTTPS + redirect + allowlist smoke (not CI): `scripts/http_https_smoke.ps1`.

**Security.** Bare `--allow-net` allows SSRF-style requests to any URL the process can reach (including cloud metadata). Prefer `--allow-net=...` host lists, short-lived CLI flags, and embedders that set capabilities only for trusted scripts. CI uses a loopback `HttpListener` only.  

## json  

**Always available (1.6.123).** No capability flag. Same API on the PB VM and libvyrnrt.  

| Call | Returns | Notes |
|------|---------|--------|
| `json.encode(value [, opts])` | string | **Raises** on circular tables, functions / unsupported types, NaN/Inf, or nesting deeper than 64. `opts.pretty = true` (or any truthy `pretty`) pretty-prints with 2-space indent. |
| `json.decode(s)` | value or `nil, err` | Soft-fail on invalid JSON or trailing garbage (does **not** raise). |
| `json.null` | table | Unique identity table; JSON `null` decodes to this value (`==` works). |

**Numbers.** An integer-subtype value encodes without a decimal (`1`). A float always has a decimal or exponent (`1.0`) so `math.type` is preserved on decode. A decode token with no `.` / `e` / `E` that fits int64 becomes an integer; otherwise a float.  

**Tables.** A table is encoded as a JSON array if and only if its keys are exactly `1..#t` (an empty table is `[]`). Otherwise it is an object; keys must be strings or numbers (numbers are emitted as JSON string keys). Lua `nil` encodes as `null`.  

**Schema validation (1.6.158).** Not a builtin — use `require("jsonschema")` (`lib/jsonschema.vyrn`, `lib/VERSION` 1.2.0). Draft-07 subset.  

## zlib  

**Always available (1.6.124).** Same API and **byte-identical** compressed output on the PB VM and libvyrnrt. Implementation is vendored miniz 3.0.2 (MIT) in `native/rt/third_party/miniz/`, wrapped by `native/rt/src/vyrn_z.c`. There is no system zlib/libz dependency. libvyrnrt links `vyrn_miniz` statically. The Windows PB VM loads `vyrn_miniz.dll` from the executable directory (or the current working directory) via `OpenLibrary`; `scripts/build_vyrn_miniz.ps1` builds it and the usual rebuild / pack / smoke scripts copy it next to the exe or `Vyrn.dll`. Linux libvyrnrt does not need that DLL.  

Formats: zlib (RFC 1950) via `compress` / `decompress`; raw deflate (RFC 1951) via `deflate` / `inflate`; gzip (RFC 1952) via `gzip` / `gunzip`. miniz `window_bits` is only ±15, so gzip is a raw deflate body plus a 10-byte header and a CRC32+ISIZE footer.  

| Call | Returns | Notes |
|------|---------|--------|
| `zlib.compress(s [, level|opts])` | string or `nil, err` | zlib format. Second argument may be a level integer **0..9** (default **6**) or an options table. |
| `zlib.decompress(s [, opts])` | string or `nil, err` | zlib format. |
| `zlib.deflate(s [, level|opts])` | string or `nil, err` | Raw deflate. |
| `zlib.inflate(s [, opts])` | string or `nil, err` | Raw inflate. |
| `zlib.gzip(s [, level|opts])` | string or `nil, err` | gzip format. |
| `zlib.gunzip(s [, opts])` | string or `nil, err` | gunzip. |
| `zlib.adler32(s [, init])` | number | Adler-32 of the UTF-8 bytes (default init **1**); integer subtype. |
| `zlib.compress_file(src, dst[, opts])` | `true` or `nil, err` | zlib format. |
| `zlib.decompress_file(src, dst[, opts])` | `true` or `nil, err` | zlib format. |
| `zlib.deflate_file(src, dst[, opts])` | `true` or `nil, err` | Raw deflate. |
| `zlib.inflate_file(src, dst[, opts])` | `true` or `nil, err` | Raw inflate. |
| `zlib.gzip_file(src, dst[, opts])` | `true` or `nil, err` | gzip format. |
| `zlib.gunzip_file(src, dst[, opts])` | `true` or `nil, err` | gunzip. |

**File helpers (1.6.129).** These compress or decompress a file in native code (shared `vyrn_z.c` streaming; no Vyrn strings), so NUL and non-UTF-8 never pass through the VM. The destination is written to a sibling `*.vyrnz.tmp` and **replaced only on success**; on failure the original destination is left unchanged and the temporary file is deleted. An existing destination is overwritten only after a successful compress or decompress. Paths are UTF-8. Same-path source and destination **raises**.  

`opts.level` is 0..9 (default **6**) on the compressors. `opts.max` caps **output** bytes (default **64 MiB**, hard cap **1 GiB**) — this is the bomb guard for decompress, and also limits compressed size. It is larger than the string zlib default of 16 MiB because files are not held in a Vyrn string. There is no Base64 or hex on disk: the files are raw bytes. Interop with the string APIs is via `crypto.tobase64_file` / `crypto.frombase64_file` (or hex). Missing / non-regular source, I/O errors, corrupt input, and output over `max` return **`nil, err`**. Bad argument types, an empty path, an out-of-range `level` / `max`, and using the same path for source and destination **raise**.  

**Encoding (same convention as http / crypto).** Compressed bytes are never returned as a raw string — the PB VM cannot hold a NUL or invalid UTF-8. Default: uncompressed input is UTF-8 text; compressed output is **base64**. Options:  

- `opts.level` — compressors only; integer 0..9, default 6.
- `opts.encoding` — `"base64"` (default) or `"hex"`: how compressed bytes are represented (compress output / decompress input).
- `opts.input` — `"text"` (default), `"base64"`, or `"hex"`: how uncompressed input is decoded.
- `opts.output` — `"text"` (default), `"base64"`, or `"hex"`: how uncompressed output is encoded.
- `opts.max` — maximum decompressed bytes (default 16 MiB, hard cap 1 GiB). Protects against compression bombs.  

**Errors.** Bad arguments (wrong types, bad level, bad encoding name, `max` out of range, empty file path, same-path source and destination, missing `vyrn_miniz.dll` on Windows PB) **raise**. Compressor failure, corrupt input, output larger than `max`, I/O errors on the file helpers, and decompressed **text** that contains a NUL or is not valid UTF-8 return **`nil, err`** (same policy as `json.decode` and http data errors). Use `opts.output='base64'` or `'hex'` when the payload is arbitrary binary. File helpers never return payload bytes as strings.

**crc32.** Use `crypto.crc32` (IEEE CRC-32; same polynomial as miniz). `zlib.crc32` is not provided, so there is only one CRC API.  

## table

Array part is 1-based. Dense 2D helpers store row-major cells (see VyrnSpec “Flat 2D matrices”).  

**Length (`#t`, 1.6.105 / 1.6.139).** `#t` is the first border: the smallest `n >= 0` with `t[n+1] == nil` (for a table without holes, the element count). There is no size cap: before 1.6.105 both the PB VM and libvyrnrt stopped counting at 4096. The same length is the default end for `table.insert` / `table.remove` / `table.concat` / `table.sort` / `table.unpack` / `table.slice` / `table.index_of`. With holes the result is the first border, which may differ from Lua's (Lua may return any border). Since 1.6.139, a table with a metatable that defines `__len` uses that metamethod (the result may be any type, as in Lua 5.2+). Tables without a metatable keep the first-border path (one HasMt flag load). Strings use `#s` / `string.len(s)` and do not go through `__len`.  

| Call | Returns | Notes |
|------|---------|--------|
| `table.insert(t, [pos,] v)` | — (0 values) | Insert into array part; mid-`pos` shifts tail (Lua-like) |
| `table.remove(t [, pos])` | value\|nil | Remove; default last; OOB / empty → nil |
| `table.concat(t [, sep [, i [, j]]])` | string | Join array segment |
| `table.sort(t [, cmp])` | — (0 values) | In-place stable sort; optional `cmp(a,b)` → bool |
| `table.foreach(t, f)` | nil | Call `f(k,v)`; stop if non-`nil` return. PB VM and libvyrnrt (1.6.108); a non-table `t` or non-function `f` raises `bad argument #1/#2 to 'foreach' (...)` |
| `table.map(t, f)` | table | New array of `f(v)` / mapped values |
| `table.filter(t, f)` | table | Keep entries where `f` is truthy |
| `table.reduce(t, init, f)` | value | Fold `f(acc, k, v)`; PB VM and libvyrnrt (1.6.108); `f` is argument #3 |
| `table.find(t, f)` | `k, v` or nil | First pair where `f(k, v)` is truthy; PB VM and libvyrnrt (1.6.108) |
| `table.index_of(t, v)` / `table.find_index(t, v)` | number\|nil | First index in `1..#t` whose element equals `v` (numbers, strings and booleans by value, tables by identity), else `nil`; a non-table `t` raises `bad argument #1 to 'index_of' (table expected)`. PB VM and libvyrnrt (`.vyrnc`, Standalone, Compile) since 1.6.106. |
| `table.pack(...)` | table | Values + `n` field |
| `table.unpack(t [, i [, j]])` | var | Spread `t[i..j]` (default `1..#t`). Limit (PB VM and libvyrnrt, 1.6.106; was 16): at most **4096** values; a longer range raises `too many results to unpack` (catchable with `pcall`). |
| `table.fields(t)` | table | Struct field names / string keys |
| `table.keys(t)` | table | Array of all keys (iteration order) |
| `table.values(t)` | table | Array of all values |
| `table.copy(t)` | table | Shallow copy (number/string keys) |
| `table.assign(dst, src [, …])` | table | Shallow-copy number/string keys from each `src` into `dst`; returns `dst` |
| `table.slice(t [, i [, j]])` | table | New array of `t[i..j]` (1-based) |
| `table.move(a, f, e, t [, b])` | table | Copy `a[f..e]` onto `b` (default `a`) at index `t`; returns dest |
| `table.clear(t)` | nil | Remove all entries; table stays alive |
| `table.create(nseq [, nrec])` | table | Empty table with optional array / hash size hints (Lua 5.5; 1.7.1). `nseq` is required, `nrec` defaults to 0. Hints reserve capacity only: `#t` is 0 after create, and no slots are filled. A missing, non-number, or negative argument raises `bad argument #1/#2 to 'create' (number expected)` / `(non-negative number expected)`; a hint larger than the dense cap (2^24) raises `(table too large)`. PB VM and libvyrnrt (catchable with `pcall`). Builtin id -372 (additive; dialect 12 / ABI 9 unchanged). |
| `table.create2d(rows, cols [, fill])` | table | Dense `rows×cols` (default fill `0`) |
| `table.get2d(t, row, col, cols)` | value | Read cell (often fused to `OP_GET2D`). Since 1.6.108 a non-table `t` raises `bad argument #1 to 'get2d' (table expected)`, and a non-number or < 1 `row` / `col` / `cols` raises `bad arguments to 'get2d' (table, row, col, cols expected)` (PB VM and libvyrnrt, catchable with `pcall`) |
| `table.set2d(t, row, col, cols, val)` | nil | Write cell (often fused to `OP_SET2D`); bad arguments raise like `get2d` (`... to 'set2d' (table, row, col, cols, value expected)`) |

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
| `os.time([t])` | number | Unix time now, or from a local date table (Lua-style). `year` is required; defaults: `month`/`day` = 1, `hour` = 12, `min`/`sec` = 0. Bad fields raise. |
| `os.date([fmt [, time]])` | string\|table | Format time. `*t` / `!*t` return a Lua-style date table (`year`…`sec`, `wday` 1=Sunday, `yday`, `isdst`). Non-string `fmt` raises. **Platform:** libvyrnrt uses `localtime` / `gmtime` (`isdst` from `tm`). PB uses fixed Windows TZ bias and always sets `isdst=false`. |

| `os.difftime(t2, t1)` | number | `t2 - t1` seconds |
| `os.getenv(name)` | string\|nil | Environment variable |
| `os.setenv(name, value)` | bool | Set env var; `nil` value removes it. CLI only — `Vyrn.dll` / IDE (`BlockOsExit`) → runtime error |
| `os.remove(path)` | bool | Delete file |
| `os.rename(old, new)` | bool | Rename/move |
| `os.execute(cmd)` | bool | Run shell command. **Platform:** official PB VM uses `cmd.exe /c` on Windows. libvyrnrt leaves this **disabled** unless built with `-DVYRNRT_OS_EXECUTE=ON`; when disabled, `os.execute()` is `false` and `os.execute(cmd)` is `nil` and runs nothing. Prefer capability-gated `process.run` (1.6.144) for argv spawn without a shell. |
| `os.exit([code])` | — | Terminate process (CLI). In `Vyrn.dll` embeds: runtime error (does not kill host) |

## path

Path helpers. **Separators:** `path.join` and a root `dirname` use `\` on Windows (`_WIN32` / official PB VM) and `/` on Linux libvyrnrt; parsers accept either. The official PB VM always normalizes to `\`.  

Since **1.6.125** `normalize`, `abspath`, `chdir`, `size`, `mtime`, and `copy` are also bound on libvyrnrt (same nil/false error policy as the PB VM). `normalize` only rewrites separators to the host style; it does not collapse `.` or `..`.  

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
| `path.listdir(p [, include_dirs])` | table | File names in `p`. If `include_dirs` is truthy (1.7.6), subdirectory names are included too (`.` / `..` omitted). Default is files only. |
| `path.glob(pattern)` | table | Glob matches |

## coroutine

Lua 5.x–style subset. Coroutine objects are tables with internal `_co_*` fields.

| Call | Returns | Notes |
|------|---------|--------|
| `coroutine.create(f)` | thread | Suspended coroutine |
| `coroutine.resume(co, ...)` | `ok, ...` | Resume; first result is success |
| `coroutine.yield(...)` | … | Yield from inside coroutine |
| `coroutine.status(co)` | string | `"suspended"` / `"running"` / `"normal"` (resumed another coroutine, 1.6.90) / `"dead"` / … |
| `coroutine.wrap(f)` | function | Resume wrapper (Lua 5.4, 1.6.142): calling it returns only the yielded or returned values (no leading `true`). Errors, including `cannot resume dead coroutine`, are re-raised; use `pcall(w)` to catch them. |
| `coroutine.running()` | thread\|nil | Active coroutine |
| `coroutine.isyieldable()` | bool | True when inside a coroutine |
| `coroutine.close(co)` | bool | Close / tear down. Known difference from Lua 5.4: a coroutine that already died with an error returns `true` (Lua returns `false, err`); |

## ws

**Both official runtimes (1.6.157).** CLI `serve` hosts a WebSocket server (ungated; PB parity). On libvyrnrt use `vbc_run serve <blob.vyrnc>` or `vyrnrt_serve_blob` after main (also used by Linux/`--exe` hosts). Plain `GET` without a WebSocket upgrade may serve static files from the script directory (or `--www`); `/` maps to `client.html`. No TLS.  

| Call | Returns | Notes |
|------|---------|--------|
| `ws.send(client, msg)` | bool | Text frame; `client` number or decimal string id |
| `ws.send_binary(client, msg)` | bool | Binary frame; payload is raw string bytes |
| `ws.broadcast(msg)` | number | Broadcast text; returns send count |

Handlers: `on_ws_connect(client_id)` (return `false` -> 403), `on_ws_message` / `on_ws_binary` (string return is echoed), `on_ws_close`, `on_tick(dt_ms)`. Incoming **binary** frames call `on_ws_binary` when defined; otherwise they fall back to `on_ws_message`. When the client table is full (64), new TCP connects are closed and a console line notes the limit.  

## Out of scope (intentionally not provided)

These stay out of the stdlib so the VM stays small for embed / game hosts:

| Area | Reason |
|------|--------|
| `debug.*` | No debug library; use host tooling / dumps (`--dump`) |
| `string.pack` / `string.unpack` | Binary pack format is large; prefer host buffers |
| `os.setlocale` / `os.tmpname` | Locale and temp-name semantics are host-owned |

If a host needs these, register them via embed/`vyrn_register` rather than growing the core.  
