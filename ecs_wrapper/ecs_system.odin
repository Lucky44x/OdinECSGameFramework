package ecs

import ecs "../../ode_ecs"
import types "../../datatypes"
import "core:fmt"

SystemEntry :: struct {
    callback: proc(ecs.entity_id, []rawptr),
    resources: []rawptr,
    view: ^ecs.View,
    iterator: ^ecs.Iterator
}

SystemMap: map[proc(ecs.entity_id, []rawptr)]int
SystemEntries: []SystemEntry

init_ecs_systems :: proc(
    MAX_SYSTEMS: int
) {
    SystemEntries = make([]SystemEntry, MAX_SYSTEMS)
    SystemMap = make(map[proc(ecs.entity_id, []rawptr)]int)
}

deinit_ecs_systems :: proc() {
    //Clear each and every registered System (also from memory)
    for entry in SystemEntries {
        if entry.callback == nil do continue

        delete(entry.resources)
        ecs.view_terminate(entry.view)
        free(entry.iterator)
    }

    delete(SystemEntries)
    delete(SystemMap)
}

put_system :: proc(
    db: ^ecs.Database,
    callback: proc(ecs.entity_id, []rawptr),
    priority: int,
    comps: []typeid,
    resources: []string = {},
) {
    actualComps: []^ecs.Shared_Table = make([]^ecs.Shared_Table, len(comps))
    for i := 0; i < len(comps); i += 1 {
        rawTab, _ := types.registry_get(&ComponentRegistry, comps[i])
        actualComps[i] = cast(^ecs.Shared_Table) rawTab^
    }

    if SystemEntries[priority].callback != nil {
        fmt.printfln("Could not register System at priority %i: Priority, already used, registering one priority later", priority)
        put_system(db, callback, priority + 1, comps, resources)
        return
    }

    //Do Resource precaching
    SystemEntries[priority].resources = make([]rawptr, len(resources))
    for i := 0; i < len(resources); i += 1 {
        globalRes, _ := types.registry_get(&GlobalResourceRegistry, resources[i])

        SystemEntries[priority].resources[i] = rawptr(globalRes)
    }

    SystemEntries[priority].callback = callback
    
    SystemEntries[priority].view = new(ecs.View)
    SystemEntries[priority].iterator = new(ecs.Iterator)

    ecs.view_init(SystemEntries[priority].view, db, actualComps)
    ecs.iterator_init(SystemEntries[priority].iterator, SystemEntries[priority].view)

    SystemMap[callback] = priority
}

run_systems :: proc() {
    for i := 0; i < len(SystemEntries); i += 1 {
        //Run for every registered System in order of priority
        system: ^SystemEntry = &SystemEntries[i]
        if system.callback == nil do continue

        //Iterate through Entities
        for ecs.iterator_next(system.iterator) {
            eid := ecs.get_entity(system.iterator)

            //Call per-entity callback
            system.callback(eid, system.resources)
        }

        //Reset Iterator
        ecs.iterator_reset(system.iterator)
    }
}