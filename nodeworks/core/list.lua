require "math"

local rng = love.math.random

local list = {}
list.__index = list

function list.__tostring(l)
  if #l == 0 then return "[]" end
  local s = "["
  for i = 1, #l - 1 do
    s = s .. tostring(l[i]) .. ", "
  end
  s = s .. tostring(l[#l]) .. "]"
  return s
end

function list.create(...)
  return setmetatable({...}, list)
end

function list.range(start, stop)
    local _start = stop and start or 1
    local _stop = stop or start

    local ret = list.create()
    for i = _start, _stop do
    ret[#ret + 1] = i
    end

    return ret
end

function list:__add(l2)
    return self:concat(l2)
end

function list:head() return self[1] end

function list:tail() return self[#self] end

function list:body() return self:sub(2) end

function list:random() return self[rng(#self)] end

function list:read(i) return self[i or 1] end

function list:insert(val, index)
  local ret = list.create(unpack(self))
  if not index then
    ret[#ret + 1] = val
  else
    local s = #ret
    for i = s, index, - 1 do
      ret[i + 1] = ret[i]
    end
    ret[index] = val
  end
  return ret
end

function list:erase(index)
  local ret = list.create(unpack(self))
  table.remove(ret, index)
  return ret
end

function list:sub(start, stop)

    if start < -1 then
        start = #self + start
    elseif start == 0 then
        start = 1
    end

    stop = stop or #self
    if stop < 0 then
        stop = #self + stop
    elseif stop == 0 then
        stop = #self
    end

    local ret = list.create()
    for i = start, stop do
        ret[#ret + 1] = self[i]
    end

    return ret
end

function list:size()
  return #self
end

function list:map(f, ...)
  local ret = list.create()
  for i = 1, #self do
    ret[i] = f(self[i], ...)
  end
  return ret
end

function list:argmap(f, ...)
    local ret = list.create()
    for i = 1, #self do
        ret[i] = f(i, self[i], ...)
    end
    return ret
end

function list:scan(f, seed)
    local ret = list.create()

    ret[1] = seed
    for i = 1, #self do
      ret[i + 1] = f(ret[i], self[i])
    end
    --ret[1] = nil

    return ret
end

function list:tap(f)
    f(self)
    return self
end

function list:reduce(f, seed)
    local f = f or function(a, b) return a + b end
    local init = seed and 1 or 2
    seed = seed or self[1]
    for i = init, #self do
    seed = f(seed, self[i])
    end
    return seed
end

function list:find(val)
  eval_f = type(val) == "function" and val or function(v) return v == val end
  for i = 1, #self do
    if eval_f(self[i]) then return self[i] end
  end
end

function list:argfind(val)
  eval_f = type(val) == "function" and val or function(v) return v == val end
  for i = 1, #self do
    if eval_f(self[i]) then return i end
  end
end

function list:reverse()
  local ret = list.create()
  for i = #self, 1, -1 do
    ret[#ret + 1] = self[i]
  end
  return ret
end

function list:filter(f, ...)
  local ret = list.create()
  for i = 1, #self do
    local val = self[i]
    if f(val, ...) then table.insert(ret, val) end
  end
  return ret
end

function list:argfilter(f, ...)
  local ret = list.create()
  for i = 1, #self do
    local val = self[i]
    ret[#ret + 1] = f(val, ...) and i or nil
  end
  return ret
end

function list:concat(...)
  local lists = {self, ...}
  local ret = list.create()
  for _, l in ipairs(lists) do
    for i = 1, #l do
      ret[#ret + 1] = l[i]
    end
  end
  return ret
end


function list:slice(start, stop)
  start = math.max(1, start or 1)
  stop = math.min(#self, stop or #self)
  local ret = list.create()
  for i = start, stop do
    ret[#ret + 1] = self[i]
  end
  return ret
end

function list:fill(val, start, stop)
  start = math.max(1, start or 1)
  stop = math.min(#self, stop or #self)
  local ret = list.create()
  for i = 1, start - 1 do
    ret[i] = self[i]
  end
  for i = start, stop do
    ret[i] = val
  end
  for i = stop + 1, #self do
    ret[i] = self[i]
  end
  return ret
end

function list.duplicate(val, num)
  local ret = list.create()
  for i = 1, num do
    ret[i] = val
  end
  return ret
end

function list:zip(...)
  local lists = list.create(self, ...)
  local ret = list.create()
  if #lists == 0 then return ret end
  local min_size = lists:map(list.size):reduce(math.min)
  for i = 1, min_size do
    local sub_ret = list.create()
    for j = 1, #lists do
      sub_ret[j] = lists[j][i]
    end
    ret[i] = sub_ret
  end
  return ret
end

function list:shuffle()
  local rng = love.math.random
  local ret = list.create()
  local indices = list.range(#self)
  local weight = indices:map(function() return rng() end)
  table.sort(indices, function(a, b) return weight[a] < weight[b] end)
  for _, i in pairs(indices) do
    ret[#ret + 1] = self[i]
  end
  return ret
end

function list:random()
    if #self < 1 then
        return
    end
    local rng = love.math.random
    return self[rng(1, #self)]
end

function list:sort(f)
  local ret = list.create(unpack(self))
  table.sort(ret, f)
  return ret
end

function list:argsort(f)
    f = f or function(a, b) return a < b end
    local ret = list.range(1, #self)
    table.sort(ret, function(i, j)
        return f(self[i], self[j])
    end)
    return ret
end
function list:unpack()
    return unpack(self)
end

function list:cycle(offset)
    local ret = list.create()
    local size = self:size()
    for i = 1, size do
        local index = (i + offset - 1) % size
        ret[i] = self[index + 1]
    end
    return ret
end

function list:__add(...)
    return self:concat(...)
end

function list:foreach(f, ...)
    for _, val in ipairs(self) do
        f(val, ...)
    end
    return self
end

function list:print()
    print(self)
    return self
end

function list:empty() return self:size() == 0 end

return list
