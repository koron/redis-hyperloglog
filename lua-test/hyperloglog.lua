require('murmurhash2')

local function dump_table(t)
  print(t)
  for k, v in pairs(t) do
    print('  ' .. k .. '=' .. v)
  end
end

local function dump_string(store)
  for i = 1, store:len() do
    print('  #' .. i .. ' ' .. store:byte(i))
  end
end

----------------------------------------------------------------------------

local function calc_params(bits)
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

local function raw_union(values)
  local retval = {}
  for i = 1, max_len(values) do
    local max = max_bytes(values, i)
    table.insert(retval, max)
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

local function union_helper(values, bits)
  local m, alpha = calc_params(bits)
  local all_estimates = grep(raw_union(values), gt0)
  local sum = estimate_sum(all_estimates)
  local len = table.maxn(all_estimates)
  local estimate = alpha * m * m / (sum + m - len)
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

local function count(value, bits)
  return union_helper({value}, bits)
end

----------------------------------------------------------------------------

local function rho(n, bits)
  local bits_in_hash = 32 - bits
  if n == 0 then
    return bits_in_hash + 1
  else
    return bits_in_hash - math.floor(math.log(n) / math.log(2))
  end
end

local function hash_info(value, bits)
  local m = calc_params(bits)
  local hash = murmurhash2.murmurhash2(value, 0)
  return hash, m, hash % m, rho(hash / m, bits)
end

local function update(s, n, v)
  return s:sub(1, n) .. string.char(v) .. s:sub(n + 2)
end

function add(store, value, bits)
  local hash, m, func_name, new_value = hash_info(value, bits)
  if store:len() < m then
    store = store .. string.rep('\x00', m - store:len())
  end
  local existing_value = store:byte(func_name + 1)
  if new_value > existing_value then
    store = update(store, func_name, new_value)
  end
  return store
end

----------------------------------------------------------------------------

bits = 4
max = 1000

s = ''
for i = 1, max do
  s = add(s, 'item' .. i, bits)
end

print('Stage #1')
print('  len='..s:len())
print('  count='..count(s, bits))

for i = 1, max / 2 do
  s = add(s, 'item' .. i, bits)
end

print('Stage #2')
print('  len='..s:len())
print('  count='..count(s, bits))
