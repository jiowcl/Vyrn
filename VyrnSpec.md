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
