local function binary_search(arr, target)
    local left, right = 1, #arr

    while left <= right do
        local mid = left + ((right - left) // 2)
        local val = arr[mid]

        if val == target then
            return mid
        elseif val < target then
            left = mid + 1
        else
            right = mid - 1
        end
    end

    return nil -- Not Found
end

local nums = { 2, 5, 8, 12, 16, 23, 38, 56, 72, 91 }
print(binary_search(nums, 23)) -- Output: 6
print(binary_search(nums, 99)) -- Output: nil