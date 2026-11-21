local function knapsack_01(weights, values, capacity)
    local n = #weights
    -- Create an (n+1) x (capacity+1) DP table, initialized to 0.
    local dp = {}
    for i = 0, n do
        dp[i] = {}
        for w = 0, capacity do
            dp[i][w] = 0
        end
    end

    for i = 1, n do
        local wt = weights[i]
        local val = values[i]
        for w = 0, capacity do
            if wt <= w then
                dp[i][w] = math.max(dp[i - 1][w], dp[i - 1][w - wt] + val)
            else
                dp[i][w] = dp[i - 1][w]
            end
        end
    end

    return dp[n][capacity]
end

local weights = { 2, 3, 4, 5 }
local values  = { 3, 4, 5, 6 }
print(knapsack_01(weights, values, 5)) -- Output: 7（weights 2+3=5，values 3+4=7）