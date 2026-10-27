# StyleGuide  

Vyrn types are **optional**. This guide keeps demos readable without forcing the whole corpus onto `strict`.

## When to annotate

| Site | Prefer |
|------|--------|
| `def` parameters and `->` returns | Annotate in public examples and library APIs |
| `struct` / `enum` fields | Always annotate |
| Hot-loop temps (`let i = 0`) | Bare is fine |
| Embed callbacks (`on_tick`, `on_ws_*`) | Annotate when the host contract is clear; otherwise bare |
| Language regression tests | Follow the test’s purpose (typed suite vs Lua-like) |

## Examples policy

1. Use `-- vyrn: 12` (or current dialect) on new `.vyrn` demos.
2. Type **surfaces**: `def` / `struct` / exported helpers.
3. Leave micro-bench loop bodies lightly typed if that matches the surrounding style.
4. Prefer `examples/vyrn/` for dialect demos; keep `examples/embed/` and `examples/native/` focused on host wiring.
5. **Strict tour:** `examples/vyrn/typed_tour.vyrn` (and `typed_tour_error.vyrn`) use `-- vyrn: 12 strict` for teaching checks. Do not add `strict` to fib/sieve/LCG benches.

Good:

```vyrn
-- vyrn: 12
def Fib(n: number) -> number
    if n <= 1 then
        return n
    end
    return Fib(n - 1) + Fib(n - 2)
end
```

Also good (temps bare):

```vyrn
def CreateArray(size: number, initialValue: number) -> table
    let arr = {}
    for i = 1, size do
        arr[i] = initialValue
    end
    return arr
end
```
