local Trie = {}
Trie.__index = Trie

function Trie.new()
    return setmetatable({
        root = { children = {}, is_end = false }
    }, Trie)
end

-- Insert Word
function Trie:insert(word)
    local node = self.root
    for i = 1, #word do
        local ch = word:sub(i, i)
        if not node.children[ch] then
            node.children[ch] = { children = {}, is_end = false }
        end
        node = node.children[ch]
    end
    node.is_end = true
end

-- Internal helper: Traverse along the prefix to the corresponding node; return `nil` if not found
function Trie:_find_node(prefix)
    local node = self.root
    for i = 1, #prefix do
        local ch = prefix:sub(i, i)
        node = node.children[ch]
        if not node then
            return nil
        end
    end
    return node
end

-- Check if the complete term exists
function Trie:search(word)
    local node = self:_find_node(word)
    return node ~= nil and node.is_end
end

-- Check if a prefix starting with this exists
function Trie:starts_with(prefix)
    return self:_find_node(prefix) ~= nil
end

-- Autocomplete: Retrieve all terms starting with the prefix
function Trie:autocomplete(prefix)
    local start_node = self:_find_node(prefix)
    local results = {}
    if not start_node then
        return results
    end

    local function dfs(node, current_word)
        if node.is_end then
            table.insert(results, current_word)
        end
        -- Sort keys ensure a stable output order
        local keys = {}
        for ch in pairs(node.children) do
            table.insert(keys, ch)
        end
        table.sort(keys)

        for _, ch in ipairs(keys) do
            dfs(node.children[ch], current_word .. ch)
        end
    end

    dfs(start_node, prefix)
    return results
end

-- === Example ===
local trie = Trie.new()
for _, w in ipairs({ "cat", "can", "cut", "car", "card", "bat" }) do
    trie:insert(w)
end

print("search('car'):", trie:search("car"))           -- true
print("search('ca'):", trie:search("ca"))             -- false
print("starts_with('ca'):", trie:starts_with("ca"))   -- true

local suggestions = trie:autocomplete("ca")
print("autocomplete('ca'):", table.concat(suggestions, ", "))
-- Output: can, car, card, cat