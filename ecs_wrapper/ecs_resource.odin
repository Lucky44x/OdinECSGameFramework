package ecs

import types "../datatypes"
import "core:fmt"
import "core:mem"
import "base:intrinsics"

GlobalResourceEntry :: struct {
    ptr: rawptr,
    type: typeid
}

GlobalResourceRegistry: types.Registry(string, GlobalResourceEntry)

init_ecs_resources :: proc() {
    err := types.registry_init(&GlobalResourceRegistry, ecs_resource_deletion_handler, 200)
    if err != nil do panic(fmt.aprintf("Could not initialize global resource Registry: %e", err))
}

deinit_ecs_resources :: proc() {

    err := types.registry_destroy(&GlobalResourceRegistry)
    if err != nil do panic(fmt.aprintf("Could not deinitialize global resource Registry: %e", err))
}

put_ecs_resource :: proc(
    val: ^$T,
    label: string,
    loc := #caller_location
) {
    assert(!types.registry_has(&GlobalResourceRegistry, label), fmt.aprintf("Resource with label %s is already registered", label), loc)

    entry := GlobalResourceEntry{
        ptr = rawptr(val),
        type = T
    }

    _, err := types.registry_put(&GlobalResourceRegistry, label, entry)
    if err != nil do panic(fmt.aprintf("Could not insert into resource registry: %e", err))
}

cast_resource_to_ptr :: proc(
    $T: typeid,
    ptr: rawptr
) -> ^T {
    return cast(^T)ptr
}

get_ecs_resource :: proc(
    $T: typeid,
    label: string,
    loc := #caller_location
) -> ^T {
    assert(types.registry_has(&GlobalResourceRegistry, label), "Resource was not found or hasn't been registered", loc)

    entry, err := types.registry_get(&GlobalResourceRegistry, label)
    if err != nil do return nil

    if entry.type != T do panic(fmt.aprintf("Types do not match up, expected: %v, got %v", typeid_of(T), entry.type))

    return cast_resource_to_ptr(T, entry.ptr)
}

pop_resource :: proc(
    label: string
) {
    err := types.registry_remove(&GlobalResourceRegistry, label)
    if err != nil do fmt.printfln("Error during resource removal: %s could not be removed: %e", label, err)
}

ecs_resource_deletion_handler :: proc(
    data: ^GlobalResourceEntry
) {
    free(data)
}