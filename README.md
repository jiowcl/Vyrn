# Vyrn  

**Tiny, Elegant, and Fast — A Modern Lua-inspired Programming Language Implemented in PureBasic.**  

**Vyrn** is a concise, lightweight programming language designed for small-scale applications and embedded scripting. Built entirely in **PureBasic**,  it keeps the familiar elegance of Lua while adding its own modern features and packaging paths.  

![GitHub](https://img.shields.io/github/license/jiowcl/Vyrn.svg)
![PureBasic](https://img.shields.io/badge/language-PureBasic-blue.svg)

## Features  

- **Ultra Lightweight**: Minimal footprint with zero extra dynamic libraries needed.  
- **Pure $PureBasic Implementation**: Seamlessly embeddable into host applications written in PureBasic or C.  
- **Lua-Inspired Syntax**: Familiar, clean, and quick to learn for Lua developers.  
- **Optional Typing**: `parameter` / `return` / `binding` / `struct annotations` (runtime checks; `--strict` for compile-time).  
- **Built for Embedding**: Designed specifically for scriptable apps, game engine logic, and small tooling.  
- **Developer Tooling**: `vyrn build`, `vyrn bundle` (tree-shake + source-map), `vyrn serve` (WebSocket), REPL, `--dump`, `--strict`, `--bench`, `--timing`.  
- **Syntax Highlighting IDE**: Designed specifically for Vyrn's unique grammar and built-in functions.  

## Environment  

- Windows 10/11 above (recommend)  
- PureBasic 6.41/6.5 above (recommend)  

## How to Build  

Building requires PureBasic Compiler and test under Windows 11.  
Module features require PureBasic 5.20 and above.  

## Example  

Vyrn supports both Lua and Vyrn's own syntax.  

```vyrn
-- vyrn: 12
-- Vyrn (Optional Typing)
@doc("Receive a name and return a personalized greeting.")
def greet(name: string) -> string
    return "Hello, " .. name .. "!"
end

@doc("Calculate and return the weighted bonus.")
def calculate_bonus(score: number) -> number
    return score * 1.1
end

print(greet("Vyrn"))
print(calculate_bonus(100))

-- Output:
-- Hello, Vyrn!
-- 110
```

```lua
-- Lua
-- Receive a name and return a personalized greeting.
function greet(name)
    return "Hello, " .. name .. "!"
end

-- Calculate and return the weighted bonus.
function calculate_bonus(score)
    return score * 1.1
end

print(greet("Vyrn"))
print(calculate_bonus(100))

-- Output:
-- Hello, Vyrn!
-- 110
```

More examples are in `examples/vyrn/`.  
For a full typing demonstration see `examples/vyrn/typed_tour.vyrn` (uses -- vyrn: 12 strict).  

## Shipping & Deployment  

| Path | Product | What it produces |
|------|---------|------------------|
| **Standalone** | Vyrn.Standalone | Bundled script + `Vyrn.dll` + launcher to distributable folder / EXE (full language & stdlib) |
| **Compile** | Vyrn.Compile | `.vyrnc` bytecode (VYBX) + generated C + `libvyrnrt` CMake project to single native EXE (no DLL, cross-platform) |

```powershell
# Standalone (full VM via DLL)
vyrn standalone app.vyrn -o dist\app --build-exe --batch

# Compile to native (bytecode + C runtime)
vyrn compile app.vyrn -o build\app --exe --batch
# or portable / linux-x64 target
vyrn compile app.vyrn -o out --target linux-x64 --batch
```

Not all VM features on Windows can be compiled into C.  

## Language Snapshot  

| Feature | Notes |
| --- | --- |
| `def` / `let` / `elif` / `const` / `continue` | Modern keywords (legacy `function` / `local` / `elseif` still accepted) |
| Optional types | `def f(x: number) -> string`, multi-return, typed destructuring |
| `struct` / `enum` | Typed constructors, methods, optional fields |
| `match` | Pattern matching (desugars to `if`/`elif`) |
| String interpolation | `"Hello, {name}!"` |
| Closures & upvalues | Full lexical capture, shared upvalues |
| Varargs | `def f(a, ...)`, `select`, `table.pack` / `unpack` |
| Protected calls | `pcall`, `xpcall`, `error`, `assert` |
| Coroutines | Full subset + `yield` statement |

## History  

- 2016: Vyrn (LuaLiteVM) was initially written in `PowerBasic 10.04`.  
- 2018: Rewritten in `FreeBasic 1.05` using `FBEdit`.  
- 2024: Rewritten in the latest version of `PureBasic` and renamed to `Vyrn`.  
- 2025: Added optional `typing`, `structs/enums`, `coroutines`, `strict mode`, `build/bundle/serve`, native `C ABI`, extensive stdlib and performance work.  
- 2026: Added packaging paths — Vyrn.Standalone (bundled script + Vyrn.dll to distributable EXE) and Vyrn.Compile (.vyrnc bytecode + generated C + libvyrnrt to single native executable, cross-platform) and released the official standalone Vyrn IDE (syntax highlighting, code editing, run/debug integration).

## Credits  

- Eros Olmi (BINT32)  
- TJ (luna)  
- airtrack (luna)  

## License  

Copyright (c) 2016-2026 Ji-Feng Tsai.  
Code released under the MIT license.  

## Donation  

If this application help you reduce time to coding, you can give me a cup of coffee :)  

[![paypal](https://www.paypalobjects.com/en_US/TW/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=3RNMD6Q3B495N&source=url)  

[Paypal Me](https://paypal.me/jiowcl?locale.x=zh_TW)  
