package datatypes

import "base:runtime"

Error :: union {
    RegistryError,
    PoolError,
    runtime.Allocator_Error
}