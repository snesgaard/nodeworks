moon.chain = function(w,h,effect)
  -- called as moonshine.chain(effect)'
  if h == nil then
    effect, w,h = w, love.window.getMode()
  end
  assert(effect ~= nil, "No effect")

  local front, back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
  local buffer = function()
    back, front = front, back
    return front, back
  end

  local disabled = {} -- set of disabled effects
  local chain = {}
  chain.resize = function(w, h)
    front, back = love.graphics.newCanvas(w,h), love.graphics.newCanvas(w,h)
    return chain
  end

  chain.draw = function(func, ...)
    -- save state
    local canvas = love.graphics.getCanvas()
    local shader = love.graphics.getShader()
    local fg_r, fg_g, fg_b, fg_a = love.graphics.getColor()

    -- draw scene to front buffer
    love.graphics.setCanvas({buffer(), stencil=true}) -- parens are needed: take only front buffer
    love.graphics.clear(love.graphics.getBackgroundColor())
    func(...)
    gfx.push()
    gfx.origin()
    -- save more state
    local blendmode = love.graphics.getBlendMode()

    -- process all shaders
    love.graphics.setColor(fg_r, fg_g, fg_b, fg_a)
    love.graphics.setBlendMode("alpha", "premultiplied")
    for _,e in ipairs(chain) do
      if not disabled[e.name] then
        (e.draw or moonshine.draw_shader)(buffer, e.shader)
      end
    end

    -- present result
    love.graphics.setShader()
    love.graphics.setCanvas(canvas)
    love.graphics.draw(front,0,0)
    gfx.pop()

    -- restore state
    love.graphics.setBlendMode(blendmode)
    love.graphics.setShader(shader)
  end

  chain.next = function(e)
    if type(e) == "function" then
      e = e()
    end
    assert(e.name, "Invalid effect: must provide `name'.")
    assert(e.shader or e.draw, "Invalid effect: must provide `shader' or `draw'.")
    table.insert(chain, e)
    return chain
  end
  chain.chain = chain.next

  chain.disable = function(name, ...)
    if name then
      disabled[name] = name
      return chain.disable(...)
    end
  end

  chain.enable = function(name, ...)
    if name then
      disabled[name] = nil
      return chain.enable(...)
    end
  end

  setmetatable(chain, {
    __call = function(_, ...) return chain.draw(...) end,
    __index = function(_,k)
      for _, e in ipairs(chain) do
        if e.name == k then return e end
      end
      error(("Effect `%s' not in chain"):format(k), 2)
    end,
    __newindex = function(_, k, v)
      if k == "parameters" or k == "params" or k == "settings" then
        for e,par in pairs(v) do
          for k,v in pairs(par) do
            chain[e][k] = v
          end
        end
      else
        rawset(chain, k, v)
      end
    end
  })

  return chain.next(effect)
end
