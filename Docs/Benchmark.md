# Benchmark  

**Test Date:** 2026  
**Vyrn Version:** 1.6.104 (LuaLiteVM) – PureBasic 6.41 (C Backend)  

## Test Environment  

| Item     | Specification                              |
|----------|--------------------------------------------|
| OS       | Windows 11 Home                            |
| CPU      | 13th Gen Intel Core i5-13400 (2.50 GHz)    |
| Memory   | 16.0 GB                                    |

## Benchmark: Fibonacci(35)  

Two implementations were tested:  

1. **Recursive** (classic tree recursion – highly call-intensive)  
2. **Iterative** (linear loop)  

Correct result for Fib(35) = **9,227,465**  

### 1. Recursive Fibonacci  

#### 1.1 thinbasic 1.14.0  

Script  

```thinbasic
FUNCTION Fib(BYVAL n AS LONG) AS LONG
  IF n <= 1 THEN
    FUNCTION = n
  ELSE
    FUNCTION = Fib(n - 1) + Fib(n - 2)
  END IF
END FUNCTION
```

| Run | Time (raw) |
| --- | --- |
| 1 | 42,152,202 |
| 2 | 60,321,203 |
| 3 | 58,783,786 |
| 4 | 69,688,027 |
| 5 | 41,653,851 |
| Avg | 54,519,814 |

#### 1.2 Vyrn 1.6.104  

Script  

```vyrn
def Fib(n: number) -> number
    if n <= 1 then
        return n
    end

    return Fib(n - 1) + Fib(n - 2)
end
```

Test Result  

| Run | Time (ms) | Instructions |
| --- | --- | --- |
| 1 | 1,523 | 21,979,531 |
| 2 | 1,520 | 21,979,531 |
| 3 | 1,846 | 21,979,531 |
| 4 | 1,523 | 21,979,531 |
| 5 | 1,551 | 21,979,531 |
| Avg | 1,593 | --- |

Observation: Vyrn is approximately 34× faster than ThinBasic on this recursive workload.  

Note: This test is for reference only; Vyrn does not yet possess the full range of features found in ThinBasic.  

### 2. Iterative Fibonacci  

#### 2.1 thinbasic 1.14.0  

Script  

```thinbasic
FUNCTION FibIter(BYVAL n AS LONG) AS LONG
  DIM a AS LONG, b AS LONG, i AS LONG, t AS LONG
  a = 0 : b = 1
  FOR i = 1 TO n
    t = a + b
    a = b
    b = t
  NEXT i
  FUNCTION = a
END FUNCTION
```

Test Result  

| Run | Time (raw) |
| --- | --- |
| 1 | 294 |
| 2 | 197 |
| 3 | 171 |
| 4 | 207 |
| 5 | 354 |
| Avg | 245 |

#### 2.2 Vyrn 1.6.104  

Script  

```vyrn
def Fib(n: number) -> number
    let a: number = 0
    let b: number = 1
    for i = 2, n do
        let c: number = a + b
        a = b
        b = c
    end
    return b
end
```

Test Result  

| Run | Time (ms) | Instructions |
| --- | --- | --- |
| 1 | 4 | 410 |
| 2 | 4 | 410 |
| 3 | 3 | 410 |
| 4 | 3 | 410 |
| 5 | 3 | 410 |
| Avg | 3.4 | --- |
