-- Define a test string containing ASCII, emoji, and Kanji characters
local test_str = "Hi 👋 元気"

print("--- Lua Unicode Test Suite ---")
print("Original String: " .. test_str)

-- 1. Byte Length vs. Character Length
-- The '#' operator or string.len counts raw bytes
local byte_len = #test_str
-- utf8.len counts actual Unicode characters/code points
local char_len = utf8.len(test_str)

print("Byte length (#): " .. byte_len)         -- 14 bytes
print("Character length: " .. char_len)        -- 7 characters

-- 2. Iterating Over Characters
print("\nCharacter Iteration:")
for offset, code_point in utf8.codes(test_str) do
  print(string.format("offset=%d, code_point=U+%04X", offset, code_point))
end

-- 3. Debug: dump raw bytes
print("\nRaw bytes (hex):")
for i = 1, #test_str do
  io.write(string.format("%02X ", string.byte(test_str, i)))
end
print()

-- 4. Debug: dump code points
print("\nCode points (hex):")
for _, cp in utf8.codes(test_str) do
  io.write(string.format("U+%04X ", cp))
end
print()

-- 5. Sanity check: print each code point as a separate line with its byte length
print("\nPer-code-point byte length:")
for offset, cp in utf8.codes(test_str) do
  local next_offset = utf8.offset(test_str, 2, offset)
  local nbytes
  if next_offset then
    nbytes = next_offset - offset
  else
    nbytes = #test_str - offset + 1
  end
  print(string.format("  U+%04X -> %d byte(s)", cp, nbytes))
end