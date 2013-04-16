--[[

USAGE:

    redis-cli --eval hll_count.lua {keys...} , {bits}

*   `key`  - one ore omre keys of counter.
*   `bits` - parameter for counter size (1-32).

--]]

local function round(value)
  return math.floor(value + 0.5)
end

local function grep(t, f)
  local retval = {}
  for k, v in pairs(t) do
    if f(v) then
      table.insert(retval, v)
    end
  end
  return retval
end

local function gt0(v)
  return v > 0
end

----------------------------------------------------------------------------

local function get_params(bits)
  local m = math.pow(2, bits)
  local alpha = 0
  if m == 16 then
    alpha = 0.673
  elseif m == 32 then
    alpha = 0.697
  elseif m == 64 then
    alpha = 0.709
  else
    alpha = 0.7213 / (1 + 1.079 / m)
  end
  return m, alpha
end

local function max_len(values)
  local len = 0
  for k, v in pairs(values) do
    if len < v:len() then
      len = v:len()
    end
  end
  return len
end

local function max_bytes(values, pos)
  local max = 0
  for k, v in pairs(values) do
    local b = v:byte(pos)
    if b and max < b then
      max = b
    end
  end
  return max
end

local function raw_union(keys, maxlen)
  local retval = {}

  for i, v = pairs(keys) do
    local str = redis.call('GET', v)
    local len = math.min(str:len(), maxlen)
    for j = 1, len do
      local value = str:byte(j)
      local curr = retval[j]
      if curr == nil or value > curr then
        retval[j] = value
      end
    end
  end

  return retval
end

local function estimate_sum(list)
  local value = 0
  for k, score in pairs(list) do
    value = value + math.pow(2, -score)
  end
  return value
end

local function estimate_count(m, len, estimate)
  if estimate <= 2.5 * m then
    if len == m then
      return round(estimate)
    else
      return round(m * math.log(m / (m - len)))
    end
  elseif estimate <= math.pow(2, 32) / 30.0 then
    return round(estimate)
  else
    return round(math.pow(-2, 32) * math.log(1 - estimate / math.pow(2, 32)))
  end
end

local function hll_count(keys, bits)
  local m, alpha = get_params(bits)
  local all_estimates = grep(raw_union(keys, m), gt0)
  local sum = estimate_sum(all_estimates)
  local len = table.maxn(all_estimates)
  local estimate = alpha * m * m / (sum + m - len)
  return estimate_count(m, len, estimate)
end

return hll_count(KEYS, tonumber(ARGV[1]))
