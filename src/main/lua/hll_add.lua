--[[

USAGE:

    redis-cli --eval hll_add.lua {key} , {bits} {hash_value}

*   `key`  - key (name) of counter.
*   `bits` - parameter for counter size (1-32).
*   `hash_value` - calculated hash (unsigned 32bits int)

--]]

local function hll_rho(n, bits)
  local bits_in_hash = 32 - bits
  if n == 0 then
    return bits_in_hash + 1
  else
    return bits_in_hash - math.floor(math.log(n) / math.log(2))
  end
end

local function hll_calc(hash_value, bits)
  local m = math.pow(2, bits)
  return hash_value % m, hll_rho(hash_value / m, bits)
end

local function hll_add(key, bits, hash_value)
  local index, value = hll_calc(hash_value, bits)
  local current = string.byte(redis.call('GETRANGE', key, index, index))
  if current == nil or value > current then
    redis.call('SETRANGE', key, index, string.char(value))
  end
  --return { index, value }
  return index
end

return hll_add(KEYS[1], tonumber(ARGV[1]), tonumber(ARGV[2]))
