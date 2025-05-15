# This is a small Game-Framework

it isn't meant to do much and quite honestly, I am wholly unsure about it's performance, but you can be sure of one thing:
It's mostlikely gonna tank your performance at least in comparission to the raw ECS Implementation from [ode_ecs](https://github.com/odin-engine/ode_ecs)
   
The issue this library is meant to solve, is my personal lazieness, essentially just providing some shorthand commands to use instead of the cumbersome creation of views, iterators, entities and component tables inside ode_ecs. This library does that for you. The only thing you gotta provide is a Type and like magic the engine is gonna handle the rest for you.

With this Framework    
Stuff like this (some stuff like all Database related stuff omitted, since it isn't really important for the point):
```ODIN
import ecs "ode_ecs"

DRAG_COEFF :: 0.75

c_Transform :: Vector2
c_Velocity :: Vector2

t_Transform: ecs.Table(c_Transform)
t_Velocity: ecs.Table(c_Velocity)

v_MoverSystem: ecs.View
it_MoverSystem: ecs.Iterator

init :: proc() {
    ecs.table_init(&t_Transform)
    ecs.table_init(&t_Velocity)

    ecs.view_init(&v_MoverSystem, { &t_Transform, &t_Velocity })
    ecs.iterator_init(&it_MoverSystem, &v_MoverSystem)
}

update :: proc() {
    s_mover_system()
}

s_mover_system :: proc() {
    for ecs.iterator_next(&it_MoverSystem) {
        eid := ecs.get_entity(&it_MoverSystem)

        transform := ecs.get_component(&t_Transform, eid)
        velocity := ecs.get_component(&t_Velocity, eid)

        transform += velocity
        velocity *= DRAG_COEFF
    }

    ecs.iteraor_reset(&it_MoverSystem)
}
```

**BECOMES THIS:**

```ODIN
import ecs "engine/libs/engine"
import eng "engine"

//Yes you DO have to use structs, due to some limitations
c_Transform :: struct{ pos: Vector2 }
c_Velocity :: struct{ vel: Vector2 }

DRAG_COEFF : f32 = 0.75

init :: proc() {
    engine.init(/* Plus all the init stuff */)

    //Components should be registered first
    engine.register_component(c_Transform)
    engine.register_component(c_Velocity)

    //Resources have to be registered before Systems
    engine.register_resource(&DRAG_COEFF, "DRAG")

    //Register a System with a priority (the lower, the earlier the system runs in the frame)
    engine.register_system(
        s_mover_system,
        0,
        { c_Transform, c_Velocity },
        { "DRAG" }
    )
}

update :: proc() {
    engine.run_systems()
}

//This is a default method signature for a system
s_mover_system :: proc(eid: ecs.entity_id, resources: []rawptr) {
    transform := engine.get_component(c_Transform, eid)
    velocity := engine.get_component(c_Velocity, eid)
    drag := engine.cast_passed_resource(f32, resources[0])

    transform.pos += velocity.vel
    velocity.vel *= drag^ //Dereference just to be sure
}
```

BUT: odin isn't magic, and it certainly isn't very friendly when it comes to type related stuff, so some things you will still have to do on your own:

- **Deinitilization (Termination) of ode_ecs component Tables**   
During the Initilization of the Engine, it will ask you for a termination proc. This is just a pointer that gets called when the engine tries to unload everything it has loaded, meaning inside the function it points to, you should use `engine.get_component_table($T)` to terminate all the Components you have created. Otherwise you're gonna get memory leaks

- **Casting global Resources**   
When registering a System, you can ask the system to pass you references to "Global Resources" that you've defined beforehand. These will come in the form of a `[]rawptr` which are essentially just pointers to the `GlobalResource` Carrier-Structs. The issue lies with odin not being able to pass an arbitrary amount of parameters or types into a function, so I had to resort to this. It gets worse tho:  
To get the actual pointer from these raw-pointers you can use the function `engine.cast_passed_resource($T, rawptr)` this will return a pointer of type `^T` where `T` is defined in the function call.   
**_"But how do I know which pointer is which resource?"_** I hear you ask... Well, the engine will pass the pointers to you in the same order as you've requested them during System registration... neat right?