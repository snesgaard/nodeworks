# Rules
* System are defined by a single top-level function
* Events are data, to be read by the systems
* Render is visualization of the systems data structure. This includes UI.

# Rationale
I want to try and escape the callback/event-loop structure inherient in the current ECS design. There a couple of reasons for this:

* Concurrency is a pain
* Control structure is spread out, and prone to be flag driven and bug prone.

Most of this arises from my experience in Ludum Dare, where a highly controlled gameflow of a turn-based was really a pain to implement.

# Design

Systems will most likely be written in the following manner

```lua
function system(ctx)
  -- Setup, in case the system want to acquire resources
  setup(ctx)
  -- Main loop where all the game logic happens
  while ctx:alive() do
    loop(ctx)
  end
  -- Release of all acquired resources
  shutdown(ctx)
end
```

The idea is that the system function will be wrapped in a coroutine, such that async behaviour can be supported.

System maintains a data structure in ctx, ala what's currently being done. When the system is drawn, the data structure is visualized.

# Events

Events will no longer directly trigger any code. Whenever a event is generated, it is put on a queue. Then when a system is being processed, it can request the latest events:

```lua
local function handle_events(ctx, key_event)
  if key_event.key == "left" then
    ctx.selected = ctx.selected - 1
    return true
  elseif key_event.key == "right" then
    ctx.selected = ctx.selected + 1
    return true
  end
end

function loop(ctx)
  local key_events = ctx:read_event("keypressed")

  for _, event in ipairs(key_events) do
    if handle_events(event) then
      ctx:consume(event)
    end
  end

  coroutine.yield()
end
```

The advantage of doing events this way, is that it is 100% under the programmers control when and how events are handled. No need for flags to ascertain the system state, as the state is 100% known at all times.

## Lifetime
The question of how long an event should be persist is a bit more complicated in a callback-less system. For event-loops it is simple, once all callbacks have been invoked for the event, the event is removed. But things are not so simple here.

For instance consider:

```lua
function game_loop()
  system_a() -- Wants event B
  system_b() -- Generates event B
  system_c()
end
```

Here system_a is called before system_b, but wants the events generated by B. This means the events from B needs to be retained through one more pass of the game loop. But no more, since we do not want system_a() to register the same event twice.

### Proposal
Lifetime can be manage via a simple rule. When the event encounters a system it has seen before, it dies. This includes the original emitter.

## Higher order events
Higher order events, are events that are triggered by other events. If we consider external events like keypresses and timestepping to be 0th order events, then things like collisions are a higher order event.

E.g. player presses the left button and moves the main character which then collides with the level geometry. Collisions would be a 1st order event (keypressed -> collision).

The reason this distinction is interesting is that higher order events can have their processing delayed with the proposed architecture.

Consider this:

```lua
function main()
  system_a() -- Listen for player damage.
  system_b() -- Listens for collision info, damages player on collision
  system_C() -- moves player on keypressed, generates collision event
end
```
If implemented with a simple pass going through the entire event chain (keypressed ->collision->damage) could take multiple passed through the game loop, which is not ideal.

An idea would be to take multiple passes through the gameloop. The 0th order pass is done with the actual timestep dt, the rest is done with dt=0.

While this can potentially waste resources in trying to fetch events multiple times, it also has some design upsides.

First being of course it fixes the potential latency associated with higher order events. Secondly it encourages systems to be written in robust manner, with it being callable with all sorts of event configurations. Normally one has to be careful only to call update once, but here it doesn't matter since functions are written to be called multiple times.

Only thing is that one has to take care that events are only passed to each system once.

### Proposal
Similar to the event loop, systems are called until all events have been exhausted.

# Event waiting

An interesting side-effect of the proposed design is that it re-introduces the option of async waiting for events.

```lua
function system(ctx, entity)
  while ctx.alive do
    nw.animation.play(entity, "throw")
    while ctx.alive and ctx:event_count(entity, equal, "animation_Done") > 0 do end
  end
end
```

Notice that since events listening no longer needs to be predeclared, we listen for specific events with an object as the root.

In the event-loop approach, the system would have to process all "animation_done" events, which is inefficient and leads to quite a lot of boilerplate code.

# Rendering
Rendering should preferably be done in an immediate mode style, rather than retained mode. To elaborate, in retained separate graphics object are allocated and those are rendered. In immediate mode, the rendering is generated directly from the game state itself.

While these might sound similar they are in fact very different. With immediate mode, the rendering is by default in sync with the game state and can be actively be put out of sync (e.g. for animations). With retained mode the rendering is by default out of sync, and must be activaly put into sync.

In other words immediate mode does the correct thing by default, and the retained mode doesn't. Besides this, it is much more intuitive for me personally to just have a function that accepts the game state as an argument and creates the rendering. Is also much more flexible.

## Interface with One-Function Systems

In the event-loop based ECS, drawing is simply another event which is caught by the system callback and triggers the event. This design is no longer an directly an option, and other designs must be considered.

### As events

In this design, drawing is invoked as any other event:

```lua

local function do_draw(ctx, draw_args, entity)
  -- Perform drawing logic here
end

function sprite_system(ctx)
  local pool = ctx:pool{nw.component.sprite}

  while ctx.alive do
    for _, draw_args in ipairs(ctx:read_event("draw")) do
      for _, entity in ipairs(pool) do
        do_draw(ctx, draw_args, entity)
      end
    end
  end
end
```

This has the upside of needing no additional logic or infrastructure. It simply uses what's already there.

The disadvantage is that all drawing systems must now always actively respond to the draw event. So for instance if a menu is currently waiting for an event or some subroutine call, these must now invoke the drawing call of the parent. Otherwise the parent rendering will be lost.

```lua

local function draw_main_menu()
  -- main menu draw goes here
end

local function draw_sub_menu()
  draw_main_menu()
  -- sub menu draw goes here
end

local function sub_menu_logic(ctx)
  while ctx.alive do
    -- submenu logic until return
    for _, _ in ipairs{ctx:read_event("draw")} do draw_sub_menu(ctx) end
    coroutine.yield()
  end
end

local function main_menu_logic()
  while ctx.alive do
    -- Main logic goes here
    if ctx.go_to_sub_menu then
      local action = sub_menu_logic(ctx)
      -- Do stuff with action here.
    end
    for _, _ in ipairs{ctx:read_event("draw")} do draw_sub_menu(ctx) end
    coroutine.yield()
  end
end
```

So while this is a bit verbose, and requires that the submenu knows of the main, it also provides a lot of control, and explicity. What you see is what you get.

### As stack

As part of setup allocation the system will register one or more functions which can draw it's state. If we take the above subroutine implementation it would look like this:

```lua
local function draw_main_menu() end

local function draw_sub_menu() end

local function sub_menu_logic(ctx)
  ctx:push("draw", draw_sub_menu)
  while ctx.alive do
    -- Sub menu logic
  end
  ctx:pop("draw")
end

function main_menu_logic(ctx)
  ctx:push("draw", draw_main_menu)

  while ctx.alive do
    -- Handle logic
    if ctx.go_to_sub_menu then
      sub_menu_logic(ctx)
    end
  end

  ctx:pop("draw")
end
```

The context ctx would then have a method for invoking registered drawers in love.draw.

This has the advantage that the submenu is now completely independent of the main menu. The disadvantage is that we have now introduce a resource allocation/deallocation in our code.

For the sprite system, it would look like this:

```lua
local function draw(pool)
  for _, entity in ipairs(pool) do do_draw(entity) end
end

function sprite_system(ctx)
  local pool = ctx:pool{nw.component.sprite}
  ctx:push("draw", draw, pool)
  while ctx.alive do coroutine.yield() end
  ctx:pop("draw")
end
```

# Examples

Some examples on how different systems may be implemented with the proposed design.

## Tween

Here we shall illustrate the implementation of the tween system.

### Basic
```lua
local function handle_update(ctx, dt, entity)
  local tween = entity % nw.component.tween
  if tween:update(dt) then
    ctx:emit("tween_done", entity)
  end
end

local function loop(ctx, pool)
  for _, dt in ipairs(ctx:read_event("update")) do
    for _, entity in ipairs(pool) do
      handle_update(ctx, dt, entity)
    end
  end
  coroutine.yield()
end

function tween_system(ctx)
  local pool = ctx:pool{nw.component.tween}

  while ctx.alive do loop(ctx, pool) end
end
```
### Union

```lua
local function handle_update(dt, entity, ctx)
  local tween = entity % nw.component.tween
  if tween:update(dt) then ctx:emit("tween_done", entity) end
end

function tween_system(ctx)
  local pool = ctx:pool{nw.component.tween}

  while ctx.alive do
    local update = ctx:read_event("update")
    set.union(update, pool, handle_update, ctx)
    coroutine.yield()
  end
end
```

So basically the system will try to read the update event and advance all tween timers. This means that only at the 0th order pass will there be any update events.

# Async/Promises

At times it might be necessary for a system to spin off non-blocking work. Either persistent or otherwise. Let us say for instance that in the menu main we open a help menu, which does not block. Meaning both has to run at the same time.

Another example could be resource loading.

A classic way of handling such an issue is the async/promise model. Whatever needs doing is spun off in a thread (coroutine) and a promise object is returned to the caller. This object will eventually contain the results of the computation.

```lua
function count_to_ten(ctx, limit)
  local counter = 0

  while ctx.alive and counter <= limit do
    for _, _  in ipairs(ctx:read_event("update")) do
      counter = counter + 1
    end
  end

  return counter
end

function system(ctx)
  local number = 10
  local promise = ctx:async(count_to_ten, number)

  while ctx.alive and not promise:done() do
    coroutine.yield()
  end

  if promise:done() then
    local count = promise:result()
    return count == number
  else
    promise:stop()
  end
end

```

# Entities
While the event-loop of the ECS is something I would like to get away from, the entity component part is still good. The idea of composition is great, and adressing using the component constructors.

An important part of ECS is the ability to query groups of entities with similar components. Referred to as pooling

For instance a tween system would want query all entities with a tween component.

A simple way of achieving pooling would be for the system to explicity request a certain pool. E.g.

```lua

function sprite_render_system(ctx)
  local pool = ctx:pool{nw.component.sprite, nw.component.position}
  while ctx.alive do
    -- Drawing logic
  end
end
```

After this call the context creates a new pool instance which contains all entities with the specified components. This pool instance will live alongside the system, and be updated according to changes in the game entities state.

Alternatively pools can be computed every time it is needed. This would eliminate the need for lifetime management, at the cost of more computation.

## Component Tables

While entities should have roughly the same interface (an object with setter and getter), it should not store any state itself. Instead it should be simultanuously ID and API for accessing tables where the data is actually stored.

A component table is basically a table were all entities with a given component is stored, e.g. position. This way it is very easy to create and maintain entity pools, as we only have to check the specific component tables for matching entities.

Alternatively entities can still store state, and the component tables simply keep track of which entities have what components. Would achieve the same, but keep open the posibility of local entities

## Lifetime

Entities are fundementally a fairly global data structure whose lifetimes are not necessarily tied to the system that spawned them.

Entities can also be operated on by a large variety of systems, not just the one that spawned it.

As such lifetime has be explicity managed via create, destroy.



# TODO

* [x] Events
* [ ] Entities
* [ ] Async/Promise
* [ ] Drawing stack