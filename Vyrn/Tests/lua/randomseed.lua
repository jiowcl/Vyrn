math.randomseed(99)
local a = math.random(1, 50)
math.randomseed(99)
local b = math.random(1, 50)
print("seed", a, b)
assert(a == b)

math.randomseed(99)
local seq = ""
for i = 1, 3 do
  seq = seq .. math.random(1, 9)
end
math.randomseed(99)
local seq2 = ""
for i = 1, 3 do
  seq2 = seq2 .. math.random(1, 9)
end
print("seq", seq, seq2)
assert(seq == seq2)
