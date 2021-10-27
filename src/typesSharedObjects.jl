#
# types.jl --
#
# Type definitions for the Julia interface to the C libraries of TAO, a Toolkit
# for Adaptive Optics.
#
#------------------------------------------------------------------------------
#
# This file is part of TAO software (https://git-cral.univ-lyon1.fr/tao)
# licensed under the MIT license.
#
# Copyright (C) 2018-2021, Éric Thiébaut.
#

"""

`TaoBindings.AbstractHighResolutionTime` is the parent type of time types with
a resolution of one nanosecond, that is [`TaoBindings.TimeSpec`](@ref) and
[`TaoBindings.HighResolutionTime`](@ref).

"""
abstract type AbstractHighResolutionTime end

"""

The structure `TaoBindings.HighResolutionTime` is the Julia equivalent to the
TAO `tao_time_t` structure.  Its members are `sec`, an integer number of
seconds, and `nsec`, an integer number of nanoseconds.

Also see [`TaoBindings.TimeSpec`](@ref).

"""
struct HighResolutionTime <: AbstractHighResolutionTime
    sec::Int64
    nsec::Int64
end

"""

The structure `TaoBindings.TimeSpec` is the Julia equivalent to the C
`timespec` structure.  Its members are `sec`, an integer number of seconds, and
`nsec`, an integer number of nanoseconds.

Also see [`TaoBindings.HighResolutionTime`](@ref).

"""
struct TimeSpec <: AbstractHighResolutionTime
    sec::_typeof_timespec_sec
    nsec::_typeof_timespec_nsec
end

const Ctime_t = _typeof_timespec_sec

"""
    TaoBindings.LockMode(val)

is used to denote the lock mode of a lockable object (see
[`TaoBindings.Lockable`](@ref)).  Constants `TaoBindings.UNLOCKED`
`TaoBindings.READ_ONLY`, and `TaoBindings.READ_WRITE` are the different
possibilities.

"""
struct LockMode
    mode::Cint
end

const UNLOCKED   = LockMode(0)
const READ_ONLY  = LockMode(1)
const READ_WRITE = LockMode(2)

"""

`TaoBindings.AbstractSharedObject` is the super-type of all objects stored in
shared memory.

"""
abstract type AbstractSharedObject end

"""

Type `TaoBindings.SharedObject` is used to represent a generic shared TAO
object in Julia.  TAO shared objects implement the `obj.key` syntax with the
following properties:

| Name              | Const. | Description                                                |
|:------------------|:-------|:-----------------------------------------------------------|
| `accesspoint`     | yes    | Address of the server owning the object                    |
| `lock`            | no     | Type of lock owned by the caller                           |
| `owner`           | yes    | Name of the server owning the object                       |
| `shmid`           | yes    | Identifier of the shared memory segment storing the object |
| `size`            | yes    | Number of bytes allocated for the shared object            |
| `type`            | yes    | Type identifier of the shared object                       |

Column *Const.* indicates whether the property is constant during shared object
lifetime.

!!! warn
        Properties should all be considered as read-only by the end-user and never
    directly modified or unexpected behavior may occur.

"""
mutable struct SharedObject <: AbstractSharedObject
    ptr::Ptr{AbstractSharedObject}
    lock::LockMode
    final::Bool    # a finalizer has been installed
    # Provide a unique inner constructor which forces starting with a NULL
    # pointer and no finalizer.
    SharedObject() = new(C_NULL, UNLOCKED, false)
end

"""

Type `TaoBindings.SharedArray{T,N}` is a concrete subtype of `DenseArray{T,N}`
which includes all arrays where elements are stored contiguously in
column-major order.  TAO shared arrrays implement the `arr.key` syntax with the
following properties:

| Name              | Const. | Description                                                |
|:------------------|:-------|:-----------------------------------------------------------|
| `accesspoint`     | yes    | Address of the server owning the object                    |
| `counter`         | no     | Serial number of the shared array                          |
| `lock`            | no     | Type of lock owned by the caller                           |
| `owner`           | yes    | Name of the server owning the object                       |
| `shmid`           | yes    | Identifier of the shared memory segment storing the object |
| `size`            | yes    | Number of bytes allocated for the shared object            |
| `timestamp`       | no     | Time-stamp  of the shared array                            |
| `type`            | yes    | Type identifier of the shared object                       |

Column *Const.* indicates whether the property is constant during shared object
lifetime.

!!! warn
    Properties should all be considered as read-only by the end-user and never
    directly modified or unexpected behavior may occur.

"""
mutable struct SharedArray{T,N} <: DenseArray{T,N}
    ptr::Ptr{AbstractSharedObject}
    arr::Array{T,N}
    lock::LockMode
    final::Bool    # a finalizer has been installed
end

"""

Union `TaoBindings.AnySharedObject` is defined to represent any shared objects
in `TaoBindings` because shared arrays and shared cameras inherit from
`DenseArray` and `AbstractCamera` respectively, not from
`TaoBindings.AbstractSharedObject`.

"""
const AnySharedObject = Union{AbstractSharedObject,SharedArray}

# The following is to have a complete signature for type statbility.
const DynamicArray{T,N} = ResizableArray{T,N,Vector{T}}

"""

`TaoBindings.Lockable` is the union of types of TAO objects that implement
read/write locks.  Methods [`TaoBindings.rdlock`](@ref),
[`TaoBindings.wrlock`](@ref), [`TaoBindings.unlock`](@ref), and
[`TaoBindings.islocked`](@ref) are applicable to such objects.

"""
const Lockable = Union{AbstractSharedObject,SharedArray}

"""

The singleton type `Basic` is a *trait* used to indicate that the version
provided by Julia must be used for a vectorized method.

This *hack* is to avoid calling methods that may be inefficient in a specific
context.  For instance BLAS `lmul!(A,B)` for small arrays.

"""
struct Basic end

#------------------------------------------------------------------------------
