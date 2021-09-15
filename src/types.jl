#
# types.jl -
#
# Type definitions for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

# Julia type for a C enumeration.
const Cenum = Cint

# Julia type for `spinErr`, the type of the result returned by most functions
# of the Spinnaker SDK.
const SpinErr = Cenum

# Julia type for `bool8_t`, the type of booleans used in the Spinnaker SDK.
const SpinBool = UInt8

struct CallError <: Exception
    code::Cint
    func::Symbol
    name::Symbol # symbolic name of error
end

# `Handle` is the abstract type of Spinnaker objects handled by a "handle"
# which is the address of an opaque structure.
abstract type Handle end

# In the SDK all handle types are anonymous pointers (`void*`), but in the low
# level Julia interface, we use more specific pointers to avoid errors.
# `Ptr{<:OpaqueHandle}` is the super-type of all pointers to Spinnaker handles.
abstract type OpaqueHandle end
abstract type OpaqueSystem        <: OpaqueHandle end
abstract type OpaqueCamera        <: OpaqueHandle end
abstract type OpaqueCameraList    <: OpaqueHandle end
abstract type OpaqueInterface     <: OpaqueHandle end
abstract type OpaqueInterfaceList <: OpaqueHandle end
abstract type OpaqueNode          <: OpaqueHandle end
abstract type OpaqueNodeMap       <: OpaqueHandle end
abstract type OpaqueImage         <: OpaqueHandle end

mutable struct System <: Handle
    handle::Ptr{OpaqueSystem}
    function System()
        ref = Ref{Ptr{OpaqueSystem}}(0)
        err = @ccall lib.spinSystemGetInstance(
            ref::Ptr{Ptr{OpaqueSystem}})::SpinErr
        _check(err, :spinSystemGetInstance)
        return finalizer(_finalize, new(ref[]))
    end
end

mutable struct InterfaceList <: Handle
    handle::Ptr{OpaqueInterfaceList}
    system::System # needed to maintain a reference to the "system" instance
    function InterfaceList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty interface list.
        ref = Ref{Ptr{OpaqueInterfaceList}}(0)
        err = @ccall lib.spinInterfaceListCreateEmpty(
            ref::Ptr{Ptr{OpaqueInterfaceList}})::SpinErr
        _check(err, :spinInterfaceListCreateEmpty)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the interface list from the system.
        err = @ccall lib.spinSystemGetInterfaces(
            handle(sys)::Ptr{OpaqueSystem},
            handle(lst)::Ptr{OpaqueInterfaceList})::SpinErr
        _check(err, :spinSystemGetInterfaces)

        # Return the instanciated object.
        return lst
    end
end

mutable struct Interface <: Handle
    handle::Ptr{OpaqueInterface}
    system::System # needed to maintain a reference to the "system" instance
    function Interface(lst::InterfaceList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{Ptr{OpaqueInterface}}(0)
        err = @ccall lib.spinInterfaceListGet(
            handle(lst)::Ptr{OpaqueInterfaceList},
            (i - 1)::Csize_t,
            ref::Ptr{Ptr{OpaqueInterface}})::SpinErr
        _check(err, :spinInterfaceListGet)
        return finalizer(_finalize, new(ref[], sys))
    end
end

mutable struct CameraList <: Handle
    handle::Ptr{OpaqueCameraList}
    system::System # needed to maintain a reference to the "system" instance

    function CameraList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty camera list.
        ref = Ref{Ptr{OpaqueCameraList}}(0)
        err = @ccall lib.spinCameraListCreateEmpty(
            ref::Ptr{Ptr{OpaqueCameraList}})::SpinErr
        _check(err, :spinCameraListCreateEmpty)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list from the system.
        err = @ccall lib.spinSystemGetCameras(
            handle(sys)::Ptr{OpaqueSystem},
            handle(lst)::Ptr{OpaqueCameraList})::SpinErr
        _check(err, :spinSystemGetCameras)

        # Return the instanciated object.
        return lst
    end

    function CameraList(int::Interface)
        # Check argument and get object system.
        sys = check(system(check(int)))

        # Create an empty camera list.
        ref = Ref{Ptr{OpaqueCameraList}}(0)
        err = @ccall lib.spinCameraListCreateEmpty(
            ref::Ptr{Ptr{OpaqueCameraList}})::SpinErr
        _check(err, :spinCameraListCreateEmpty)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list from the system.
        err = @ccall lib.spinInterfaceGetCameras(
            handle(int)::Ptr{OpaqueInterface},
            handle(lst)::Ptr{OpaqueCameraList})::SpinErr
        _check(err, :spinInterfaceGetCameras)

        # Return the instanciated object.
        return lst
    end
end

mutable struct Camera <: Handle
    handle::Ptr{OpaqueCamera}
    system::System # needed to maintain a reference to the "system" instance
    function Camera(lst::CameraList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{Ptr{OpaqueCamera}}(0)
        err = @ccall lib.spinCameraListGet(
            handle(lst)::Ptr{OpaqueCameraList},
            (i - 1)::Csize_t,
            ref::Ptr{Ptr{OpaqueCamera}})::SpinErr
        _check(err, :spinCameraListGet)
        return finalizer(_finalize, new(ref[], sys))
    end
end

# FIXME: not yet interfaced

mutable struct NodeMap <: Handle
    handle::Ptr{OpaqueNodeMap}
    system::System # needed to maintain a reference to the "system" instance
end

mutable struct Node <: Handle
    handle::Ptr{OpaqueNode}
    system::System # needed to maintain a reference to the "system" instance
end

mutable struct Image <: Handle
    handle::Ptr{OpaqueImage}
    system::System # needed to maintain a reference to the "system" instance
end
