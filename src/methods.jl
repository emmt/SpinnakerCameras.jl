#
# methods.jl -
#
# Implementation of methods for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

to_bool(x::SpinBool) = (x != zero(x))

"""
    SpinnakerCameras.isnull(arg)

yields whether `arg` is a null pointer of a Spinnaker object with a null
handle.

"""
isnull(obj::Handle) = isnull(handle(obj))
isnull(ptr::Ptr{T}) where {T} = (ptr == null_pointer(T))

null_pointer(::Type{T}) where {T} = Ptr{T}(0)
null_pointer(x) = null_pointer(typeof(x))

_handle_type(obj::Handle) = _handle_type(typeof(obj))
_handle_type(::Type{<:Handle})        = OpaqueHandle
_handle_type(::Type{<:System})        = OpaqueSystem
_handle_type(::Type{<:Camera})        = OpaqueCamera
_handle_type(::Type{<:CameraList})    = OpaqueCameraList
_handle_type(::Type{<:Interface})     = OpaqueInterface
_handle_type(::Type{<:InterfaceList}) = OpaqueInterfaceList
_handle_type(::Type{<:Node})          = OpaqueNode
_handle_type(::Type{<:NodeMap})       = OpaqueNodeMap
_handle_type(::Type{<:Image})         = OpaqueImage

"""
    SpinnakerCameras.handle(obj) -> ptr

yields the handle of Spinnaker object `obj`.  This function is for the
low-level interface, it shall not be used by the end-user.

"""
handle(obj::Handle) = getfield(obj, :handle)

_clear_handle!(obj::Handle) =
    setfield!(obj, :handle, Ptr{_handle_type(obj)}(0))

system(sys::System) = obj
system(obj::Handle) = getfield(obj, :system)

"""
    SpinnakerCameras.shortname(obj) -> str

yields the name of Spinnaker object `obj`.  The object type may be specified
instead.

"""
shortname(obj::Handle) = shortname(typeof(obj))
shortname(::Type{<:System}) = "object system"
shortname(::Type{<:Interface}) = "interface"
shortname(::Type{<:InterfaceList}) = "interface list"
shortname(::Type{<:CameraList}) = "camera list"
#shortname(::Type{<:Camera}) = "camera"

"""
    SpinnakerCameras.check(obj) -> obj

throws an exception if the handle of object `obj` is null, otherwise returns
the object.

"""
function check(obj::Handle)
    isnull(obj) && Error("Spinnaker ", shortname(obj), " has been finalized")
    return obj
end

# This version of `_finalize` implements the do-block syntax.  If the handle of
# object `obj` is not null, function `func` is called with the handle value and
# the object handle is set to null.
function _finalize(func::Function, obj::Handle)
    ptr = handle(obj)
    if ! isnull(ptr)
        _clear_handle!(obj)
        func(ptr)
    end
    return nothing
end

# Get length/size of some Spinnaker objects.
for (jl_func, type, c_func) in (
    (:length, :InterfaceList, :spinInterfaceListGetSize),
    #(:sizeof, :Image,         :spinImageGetSize),
    (:length, :CameraList,    :spinCameraListGetSize),)
    opaque_type = Symbol("Opaque", type)
    @eval begin
        function $jl_func(obj::$type)
            if isnull(obj)
                return 0
            else
                size = Ref{Csize_t}(0)
                err = @ccall lib.$c_func(
                    handle(obj)::Ptr{$opaque_type},
                    size::Ptr{Csize_t})::SpinErr
                _check(err, $(QuoteNode(c_func)))
                return Int(size[])
            end
        end
    end
end

#------------------------------------------------------------------------------
# SYSTEM

"""
    sys = SpinnakerCameras.System()

yields an instance `sys` of Spinnaker object system.  The following shortcuts
are implemented:

    sys[:] # yields the list of interfaces
    sys[i] # yields the i-th interface

""" System

_finalize(obj::System) = _finalize(obj) do handle
    err = @ccall lib.spinSystemReleaseInstance(
        handle::Ptr{OpaqueSystem})::SpinErr
    _check(err, :spinSystemReleaseInstance)
end

getindex(sys::System, ::Colon) = InterfaceList(sys)
getindex(sys::System, i::Integer) = InterfaceList(sys)[i]

#------------------------------------------------------------------------------
# LISTS OF INTERFACES

"""
    lst = SpinnakerCameras.InterfaceList(sys)

yields a list of Spinnaker interfaces for the system `sys`.  This is the same
as `sys[:]`.

Call `length(lst)` to retrieve the number of interfaces and use syntax `lst[i]`
to get the `i`-th interface.

""" InterfaceList

getindex(lst::InterfaceList, i::Integer) = Interface(lst, i)

_finalize(obj::InterfaceList) = _finalize(obj) do handle
    err1 = @ccall lib.spinInterfaceListClear(
        handle::Ptr{OpaqueInterfaceList})::SpinErr
    err2 = @ccall lib.spinInterfaceListDestroy(
        handle::Ptr{OpaqueInterfaceList})::SpinErr
    _check(err1, :spinInterfaceListClear)
    _check(err2, :spinInterfaceListDestroy)
end

#------------------------------------------------------------------------------
# INTERFACES

"""
    int = SpinnakerCameras.Interface(lst, i)

yields the `i`-th entry of Spinnaker interface list `lst`.  This is the same as
`lst[i]`.

""" Interface

_finalize(obj::Interface) = _finalize(obj) do handle
    err = @ccall lib.spinInterfaceRelease(
        handle::Ptr{OpaqueInterface})::SpinErr
    _check(err, :spinInterfaceRelease)
end

#------------------------------------------------------------------------------
# LISTS OF CAMERAS

"""
    lst = SpinnakerCameras.CameraList(sys|int)

yields a list of Spinnaker cameras for the system `sys` or for the interface
`int`.

Call `length(lst)` to retrieve the number of cameras and use syntax `lst[i]` to
get the `i`-th camera.

""" CameraList

getindex(lst::CameraList, i::Integer) = Camera(lst, i)

_finalize(obj::CameraList) = _finalize(obj) do handle
    err1 = @ccall lib.spinCameraListClear(
        handle::Ptr{OpaqueCameraList})::SpinErr
    err2 = @ccall lib.spinCameraListDestroy(
        handle::Ptr{OpaqueCameraList})::SpinErr
    _check(err1, :spinCameraListClear)
    _check(err2, :spinCameraListDestroy)
end


#------------------------------------------------------------------------------
# CAMERAS

"""
    SpinnakerCameras.Camera(lst, i)

yields the `i`-th entry of Spinnaker interface list `lst`.  This is the same
as `lst[i]`.

""" Camera

"""
    SpinnakerCameras.initialize(cam)

initializes Spinnaker camera `cam`.

""" initialize

"""
    SpinnakerCameras.deinitialize(cam)

deinitializes Spinnaker camera `cam`.

""" deinitialize

"""
    SpinnakerCameras.start(cam)

starts acquisition with Spinnaker camera `cam`.

""" start

"""
    SpinnakerCameras.stop(cam)

stops acquisition with Spinnaker camera `cam`.

""" stop

for (jl_func, c_func) in ((:initialize,   :spinCameraInit),
                          (:deinitialize, :spinCameraDeInit),
                          (:start,        :spinCameraBeginAcquisition),
                          (:stop,         :spinCameraEndAcquisition),)
    _jl_func = Symbol("_", jl_func)
    @eval begin
        $jl_func(obj::Camera) = $_jl_func(handle(obj))
        function $_jl_func(ptr::Ptr{OpaqueCamera})
            err = @ccall lib.$c_func(
                ptr::Ptr{OpaqueCamera})::SpinErr
            _check(err, $(QuoteNode(c_func)))
        end
    end
end

"""
    SpinnakerCameras.isinitialized(cam)

yields whether Spinnaker camera `cam` is initialized.

""" isinitialized

"""
    SpinnakerCameras.isstreaming(cam)

yields whether Spinnaker camera `cam` is currently acquiring images.

""" isstreaming

"""
    isvalid(cam)

yields whether Spinnaker camera `cam` is still valid for use.

""" isvalid

for (jl_func, c_func) in ((:isinitialized, :spinCameraIsInitialized),
                          (:isstreaming,   :spinCameraIsStreaming),
                          (:isvalid,       :spinCameraIsValid),)
    _jl_func = Symbol("_", jl_func)
    @eval begin
        $jl_func(obj::Camera) = $_jl_func(handle(obj))
        function $_jl_func(ptr::Ptr{OpaqueCamera})
            if isnull(ptr)
                return false
            else
                ref = Ref{SpinBool}(0)
                err = @ccall lib.$c_func(
                    ptr::Ptr{OpaqueCamera},
                    ref::Ptr{SpinBool})::SpinErr
                _check(err, $(QuoteNode(c_func)))
                return to_bool(ref[])
            end
        end
    end
end

function _finalize(obj::Camera)
    ptr = handle(obj)
    if _isinitialized(ptr)
        _deinitialize(ptr)
    end
    if !isnull(ptr)
        _clear_handle!(cam)
        err = @ccall lib.spinCameraRelease(
            ptr::Ptr{OpaqueInterface})::SpinErr
        _check(err, :spinCameraRelease)
    end
    return nothing
end

#------------------------------------------------------------------------------
# NODES
