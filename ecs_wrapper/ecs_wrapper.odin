package ecs

import "core:fmt"

/*
Initializes the Wrapper (component, system and resources systems)
*/
init_ecs_wrapper :: proc(
    COMPONENT_TERMINATION_CALLBACK: proc(),
    MAX_SYSTEMS: int = 500
) {
    init_ecs_components(COMPONENT_TERMINATION_CALLBACK)
    init_ecs_resources()
    init_ecs_systems(MAX_SYSTEMS)
}

deinit_ecs_wrapper :: proc(

) {
    deinit_ecs_components()
    deinit_ecs_resources()
    deinit_ecs_systems()
}