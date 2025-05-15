package ecs

import ecs "../../ode_ecs"
import types "../../datatypes"
import "core:mem"
import "core:fmt"
import "base:intrinsics"

ComponentEntry :: rawptr
ComponentRegistry: types.Registry(typeid, ComponentEntry)
ComponentDeinitFunction: proc()

init_ecs_components :: proc(
    termination_function: proc()
) {
    ComponentDeinitFunction = termination_function
    types.registry_init(&ComponentRegistry, ecs_component_deletion_handler, 500)
}

deinit_ecs_components :: proc() {
    ComponentDeinitFunction()

    types.registry_destroy(&ComponentRegistry)
}

put_ecs_component :: proc(
    $T: typeid,
    db: ^ecs.Database,
    entity_cap: int,
    loc := #caller_location
) /*where intrinsics.type_is_struct(T)*/ {
    assert(intrinsics.type_is_struct(T), "Could not register Component, only Structs are allowed, due to typeid limitations", loc)
    registered, _ := types.registry_has(&ComponentRegistry, T)
    assert(!registered, fmt.aprintf("Component of type %v is already registered", type_info_of(T), allocator = context.temp_allocator), loc)

    table: ^ecs.Table(T) = new(ecs.Table(T))
    ecs.table_init(table, db, entity_cap)

    _, err := types.registry_put(&ComponentRegistry, T, rawptr(table))
    
    if err != nil do panic(fmt.aprintf("Could not load component of type %v into registry: %e", type_info_of(T), err, allocator = context.temp_allocator))
}

add_component_to_entity :: proc(
    $T: typeid,
    eid: ecs.entity_id,
    loc := #caller_location
) -> ^T {
    registered, _ := types.registry_has(&ComponentRegistry, T)
    assert(registered, fmt.aprintf("Component of type %v has not been registered", type_info_of(T), allocator = context.temp_allocator), loc)

    rawEntry, _ := types.registry_get(&ComponentRegistry, T)
    compTable := cast(^ecs.Table(T)) rawEntry^

    //Error handling is for pussies (just have ABSOLUTE faith in your code) (famous last words)
    ref, _ := ecs.add_component(compTable, eid)
    return ref
}

remove_component_from_entity :: proc(
    $T: typeid,
    eid: ecs.entity_id,
    loc := #caller_location
) {
    registered, _ := types.registry_has(&ComponentRegistry, T)
    assert(registered, fmt.aprintf("Component of type %v has not been registered", type_info_of(T), allocator = context.temp_allocator), loc)

    rawEntry, _ := types.registry_get(&ComponentRegistry, T)
    compTable := cast(^ecs.Table(T)) rawEntry^

    //Error handling is for pussies (just have ABSOLUTE faith in your code) (famous last words)
    ecs.remove_component(compTable, eid)
}

get_ecs_component :: proc(
    $T: typeid,
    eid: ecs.entity_id,
    loc := #caller_location
) -> ^T {
    assert(types.registry_has(&ComponentRegistry, T), fmt.aprintf("Component of type %v has not been registered", type_info_of(T), allocator = context.temp_allocator), loc)

    rawEntry, _ := types.registry_get(&ComponentRegistry, T)
    compTable := cast(^ecs.Table(T)) rawEntry^

    //Error handling is for pussies (just have ABSOLUTE faith in your code) (famous last words)
    ref := ecs.get_component(compTable, eid)
    return ref
}

get_ecs_component_table :: proc(
    $T: typeid,
    loc := #caller_location
) -> ^ecs.Table(T) {
    registered, _ := types.registry_has(&ComponentRegistry, T)
    assert(registered, fmt.aprintf("Component of type %v has not been registered", type_info_of(T), allocator = context.temp_allocator), loc)

    rawEntry, _ := types.registry_get(&ComponentRegistry, T)
    compTable := cast(^ecs.Table(T)) rawEntry^
    return compTable
}

@(private)
ecs_component_deletion_handler :: proc(
    data: ^ComponentEntry
) {
    //Force clear every table (using the actual termination fucntion from teh ECS Backend here is impossible, since that function requires Polymorphic parameter T which has to be compile time constant)
    free(data^)
}