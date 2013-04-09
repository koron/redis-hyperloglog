module('murmurhash2', package.seeall)

local function str2int(s, n)
  local v = 0
  for i = 0, 3 do
    local b = s:byte(n + i)
    if not b then
      break
    end
    v = bit.lshift(v, 8) + b
  end
  return v
end

function murmurhash2(key, seed)
  local len = key:len()

  local m = 0x5bd1e995
  local r = 24

  local h = bit.bxor(seed, len)

  local i
  for i = 1, len, 4 do
    local k = str2int(key, i)
    if i + 3 > len then
      h = bit.bxor(h, k)
      h = bit.bor(h * m, 0)
      break
    end
    k = bit.bor(k * m, 0)
    k = bit.bxor(k, bit.rshift(k, r))
    k = bit.bor(k * m, 0)
    h = bit.bor(h * m, 0)
    h = bit.bxor(h, k)
  end

  h = bit.bxor(h, bit.rshift(h, 13))
  h = bit.bor(h * m, 0)
  h = bit.bxor(h, bit.rshift(h, 15))

  if h < 0 then
    h = h + 4294967296
    return h
  end
  return h
end
