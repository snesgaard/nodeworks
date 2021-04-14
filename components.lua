local function health(health)
  return {value=health, max=health}
end

--------------------------------------------------

local timer = {}
timer.__index = timer

function timer.create(duration)
  return setmetatable({duration=duration, time=time}, timer)
end

function timer:update(dt)
  self.time = self.time - dt
  return self.time <= 0
end

function timer:reset()
  self.time = self.duration
end

--------------------------------------------------

local tick = {}
tick.__index = tick

function tick.create(ticks)
  return setmetatable({max=ticks, value=ticks}, tick)
end

function tick:update()
  self.value = self.value - 1
  return self.value <= 0
end

function tick:reset()
  self.value = self.max
end

--------------------------------------------------

local function multiplier(scale) return scale end

--------------------------------------------------

local function addition(value) return value end

--------------------------------------------------

local poison = ecs.assemblage{tick, timer, multiplier, addition}

--------------------------------------------------

local function shield() return true end

--------------------------------------------------

local function charge() return true end

--------------------------------------------------

local function target(target) return target end

--------------------------------------------------

local function user(user) return user end

--------------------------------------------------

local damage = {}
damage.__index = damage

function damage.create(args)
    local this = {__damage}

    for key, val in pairs(args) do
        this.__damage[key] = val
    end

    return setmetatable(this, damage)
end

function damage:total()
    return self:physical() + self:elemental()
end

function damage:physical()
    return self.__damage.physical or 0
end

function damage:elemental()
    return self.__damage.elemental or 0
end

function damage:is_physical()
    return self.__damage.physical ~= nil
end

function damage:is_elemental()
    return self.__damage.elemental ~= nil
end

function position(x, y) return vec2(x, y) end

function velocity(x, y) return vec2(x, y) end


--------------------------------------------------
return {
    addition=addition,
    multiplier=multiplier,
    health=health,
    timer=timer,
    tick=tick,
    poison=poison,
    charge=charge,
    shield=shield,
    target=target,
    user=user,
    position=position,
    velocity=velocity
}
