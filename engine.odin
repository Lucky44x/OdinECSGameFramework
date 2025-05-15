package engine

import "ecs_wrapper"
import "core:fmt"
import ecs "libs/ode_ecs"

c_Active_State :: struct{
    state: bool
}

@(private)
ComponentTerminationCallback: proc()

/*
Initializes the ENGINE and the underlying ECS-Wrapper.
REQUIRED:
You have to specify a COMPONENT_TERMINATION_FUNCTION, which will be called during deinitialization of the ECS_Components
Due to odins strongly typed nature, you'll have to implement the termination of the underlying tables yourself
To do this, the engine exposes the get_component_table($T) function, which should return the correct Table to you, for deinitialization purposes
*/
init_engine :: proc(
    DB: ^ecs.Database,
    COMPONENT_TERMINATION_FUNCTION: proc(),
    MAX_ENTITIES: int = 5000,
    MAX_SYSTEMS: int = 500
) {
    ComponentTerminationCallback = COMPONENT_TERMINATION_FUNCTION

    ecs_wrapper.init_ecs_wrapper(deinit_builtin_components, MAX_SYSTEMS)

    register_component(c_Active_State, DB, MAX_ENTITIES)
}

/*
Deinitializes the engine and it's underlying structures
*/
deinit_engine :: proc(
    DB: ^ecs.Database
) {
    ecs_wrapper.deinit_ecs_wrapper()
}

@(private)
deinit_builtin_components :: proc() {
    ecs.table_terminate(get_component_table(c_Active_State))

    ComponentTerminationCallback()
}

/*
Creates an entity with the given Components and returns it's entity ID
*/
create_entity :: proc(
    db: ^ecs.Database,
    default_state: bool = false
) -> ecs.entity_id {
    eid, _ := ecs.create_entity(db)

    state : ^c_Active_State = add_component(c_Active_State, eid)
    state.state = default_state

    return eid
}

/*
Register a System into the ECS-World
Expects:
- db: the ode_ecs Database to work with
- callback: the actual function which should be executed
- priority: the priority in the frame time execution
- comps: the array of component Types that this system should request
- resources: the array of GlobalResourceTypes this system should request
*/
register_system :: ecs_wrapper.put_system

/*
Register a type as a component-type
Expects:
- T: the type you want to register
- db: the database to work on
- entity_cap: the maximum number of entities this component should expect
*/
register_component :: ecs_wrapper.put_ecs_component

/*
Registers the passed pointer as a Global Resource under it's type (Only one Resource per type is allowed)
Expects:
- val: The Pointer to the resource that should be registered
- label: The label under which this resource should be registered
*/
register_resource :: ecs_wrapper.put_ecs_resource

/*
Adds the given component to the given entity, and returns it's reference
Expects:
- T: The type of the component
- eid: The Entity-ID
*/
add_component :: ecs_wrapper.add_component_to_entity

/*
Returns the pointer to the component of the provided type on the provided entity
Expects:
- T: The type of the component
- eid: The Entity-ID
*/
get_component :: ecs_wrapper.get_ecs_component

/*
Returns the Table reference belonging to this component
Expects:
- T: the type of component you want the Table of

** ONLY INTENTED FOR DEINIT PURPOSES... USE AT YOUR OWN RISK **
*/
get_component_table :: ecs_wrapper.get_ecs_component_table

/*
Returns the pointer to the provided GobalResource
Expects:
- T: the typeid of the type you are requesting
- label: the label under which the resource you are requesting was registered
*/
get_resource :: ecs_wrapper.get_ecs_resource


/*
Removes/Unregisters the provided resource
Expects:
- label: the label of the resource to be removed
*/
remove_resource :: ecs_wrapper.pop_resource

/*
Cast a rawptr, passed into your system, back to a proper Pointer to your Registered Global Resource
NOTE:
This function should be called for all of your resources that you registered during it's registration phase
It expects you to provide the correct type as the first argument
You can infer the type by looking at the order of the types you requested at system registration, as the system keeps this order intact
*/
cast_passed_resource :: proc(
    $T: typeid,
    resource: rawptr
) -> ^T {
    resEntry: ecs_wrapper.GlobalResourceEntry = cast(ecs_wrapper.GlobalResourceEntry)resource

    if resEntry.type != T {
        fmt.printfln("The provided type %v does not match the recorded type %v... \n Please make sure you are casting the resources in THE SAME order, as when you registered them into the system", T, resEntry.type)
        return nil
    }

    return ecs_wrapper.cast_resource_to_ptr(T, resEntry.ptr)
}