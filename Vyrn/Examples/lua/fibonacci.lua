-- Run: Vyrn.exe "fibonacci.lua" --unlimited

-- Fibonacci Sequence Test: Calculate the 35th term (Fibonacci 35).
function Fib(n)
    if n <= 1 then
        return n
    end

    return Fib(n - 1) + Fib(n - 2)
end

function RunBenchmark()
    print("Start Fibonacci benchmark...")
    local result = Fib(35)

    -- The correct answer should be 9227465
    print("Complete! Result: ", result) 
end

RunBenchmark()