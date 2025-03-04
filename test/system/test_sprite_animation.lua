---@module "3rd"
local third = require "3rd"
local T = third.test

---@module "nodeworks"
local nw = require "nodeworks"

local pa = nw.system.sprite_animation
local time = nw.system.time

local stack = nw.ecs.stack
local function get_slice(self, name) return self.slices[name] end

local idle = {
    {dt = 1, slices = {foo=nw.spatial(0, 0, 10, 20)}, slice_data = {}, get_slice=get_slice},
    {dt = 2, slices = {bar=nw.spatial(1, 2, 13, 7)}, slice_data = {}, get_slice=get_slice},
    {dt = 3, slices = {}, slice_data = {}, get_slice=get_slice}
}
local hit = {
    {dt = 1, slices = {}, slice_data = {}, get_slice=get_slice},
    {dt = 2, slices = {}, slice_data = {}, get_slice=get_slice}
}
local foo = {
    {dt = 1, slices = {baz=nw.spatial(0, 0, 10, 20)}, slice_data={}, get_slice=get_slice},
    {dt = 1, slices = {baz=nw.spatial(0, 0, 10, 20)}, slice_data={}, get_slice=get_slice},
    {dt = 1, slices = {}, slice_data={}, get_slice=get_slice},
}

local state_map = {
    idle = nw.video(idle):loop(),
    hit = nw.video(hit):once(),
    foo = nw.video(foo)
}

local test_components = {}

function test_components.foo(a) return a or 0 end

function test_components.unique_stuff(v) return v or 0 end


function pa.slice_assembly_from_properties()
    return {
        {test_components.foo}
    }
end


T("test_sprite_animator", function(T)
    stack.clear()
    
    local id = {}
    stack.set(nw.component.animation_map, id, state_map)
    nw.system.sprite_animation.play(id, "idle")

    T("is_done", function(T)
        T:assert(not pa.is_done(id))
        time.update(10)
        T:assert(not pa.is_done(id))

        nw.system.sprite_animation.play(id, "hit")

        T:assert(not pa.is_done(id))
        time.update(10)
        T:assert(pa.is_done(id))
    end)

    T("ensure", function(T)
        T:assert(not nw.system.sprite_animation.ensure(id, "idle"))
        T:assert(nw.system.sprite_animation.ensure(id, "hit"))
        T:assert(not nw.system.sprite_animation.ensure(id, "hit"))
    end)

    T("update", function(T)
        T:assert(stack.has(nw.component.frame, id))
        pa.update()
        T:assert(stack.has(nw.component.frame, id))
        T:assert(stack.get(nw.component.frame, id) == idle[1])

        time.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == idle[2])

        nw.system.sprite_animation.play(id, "hit")
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[1])

        time.update(1.5)
        pa.update()
        T:assert(stack.get(nw.component.frame, id) == hit[2])
        
        T("without_map", function(T)
            stack.remove(nw.component.animation_map, id)
            pa.update()
        end)
    end)

    T("slice_properties", function(T)
        nw.system.sprite_animation.play(id, "hit")
        nw.system.sprite_animation.play(id, "idle")
        
        T:assert(nw.system.collision.get_bump_world():countItems() == 1)
        T:assert(nw.dict.size(stack.get_table(test_components.foo)) == 1)

        nw.system.sprite_animation.play(id, "hit")

        T:assert(nw.dict.size(stack.get_table(test_components.foo)) == 0)
        T:assert(nw.system.collision.get_bump_world():countItems() == 0)
    end)

    T("slice_property_retain", function(T)
        -- Start animation
        nw.system.sprite_animation.play(id, "foo")
        local slice_dict = nw.system.sprite_animation.get_slice_dict(id)
        -- Get the baz hitboz and set some 
        local baz_id = slice_dict.baz
        T:assert(baz_id)
        stack.set(test_components.unique_stuff, baz_id)
        -- Advance to next frame in the animation
        time.update(1.5)
        pa.update()
        -- CHeck the component got carried over
        T:assert(stack.has(test_components.unique_stuff, baz_id))
        -- Advace to next frame, the baz hitbox should have been deleted
        time.update(1.0)
        pa.update()
        T:assert(not stack.has(test_components.unique_stuff, baz_id))
    end)
end)