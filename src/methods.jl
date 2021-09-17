#
# methods.jl -
#
# Implementation of methods for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

# Make sure to initialize handles and references to handles with NULL.
Base.Ref{T}() where {T<:Ptr{<:OpaqueObject}} = Ref{T}(0)
Base.Ptr{T}() where {T<:OpaqueObject} = Ptr{T}(0)

to_bool(x::SpinBool) = (x != zero(x))

"""
    SpinnakerCameras.isnull(ptr)

yields whether `ptr` is a null pointer.

"""
isnull(ptr::Ptr) = (UInt(ptr) == 0)

"""
    SpinnakerCameras.handle(obj) -> ptr

yields the handle of Spinnaker object `obj`.  This function is for the
low-level interface, it shall not be used by the end-user.

"""
handle(obj::SpinObject) = getfield(obj, :handle)

# Union of types whose instances have a "parent" member.
const ChildObjects = Union{InterfaceList, Interface,
                           CameraList, Camera,
                           NodeMap, Node}

parent(obj::ChildObjects) = getfield(obj, :parent)

# A bit of magic to simplify writing calls to the SDK functions.
for T in (:System, :InterfaceList, :Interface, :CameraList, :Camera,
          :NodeMap, :Node, :Image)
    @eval unsafe_convert($(Symbol(T,"Handle")), obj::$T) = handle(obj)
end

"""
    SpinnakerCameras.shortname(obj) -> str

yields the name of Spinnaker object `obj`.  The object type may be specified
instead.

"""
shortname(obj::SpinObject) = shortname(typeof(obj))
shortname(::Type{<:System}) = "object system"
shortname(::Type{<:Interface}) = "interface"
shortname(::Type{<:InterfaceList}) = "interface list"
shortname(::Type{<:CameraList}) = "camera list"
shortname(::Type{<:Camera}) = "camera"
shortname(::Type{<:Image}) = "image"
shortname(::Type{<:Node}) = "node"
shortname(::Type{<:NodeMap}) = "node map"

"""
    SpinnakerCameras.check(obj) -> obj

throws an exception if the handle of object `obj` is null, otherwise returns
the object.

"""
function check(obj::SpinObject)
    isnull(handle(obj)) && error(
        "Spinnaker ", shortname(obj), " has been finalized")
    return obj
end

# Get length/size of some Spinnaker objects.
# FIXME: spinNodeMapGetNumNodes seems broken
for (jl_func, type, c_func) in (
    (:length, :InterfaceList, :spinInterfaceListGetSize),
    #(:sizeof, :Image,         :spinImageGetSize),
    (:length, :CameraList,    :spinCameraListGetSize),
    (:length, :NodeMap,       :spinNodeMapGetNumNodes),)
    handle_type = Symbol(type,"Handle")
    @eval begin
        function $jl_func(obj::$type)
            isnull(handle(obj)) && return 0
            ref = Ref{Csize_t}(0)
            @checked_call($c_func, ($handle_type, Ptr{Csize_t}),
                          obj, ref)
            return Int(ref[])
        end
    end
end

#------------------------------------------------------------------------------
# Methods for properties of any Spinnaker object type.
#
# Specialize `getproperty` and `setproperty!` in the name of the member (for
# type-stability and faster code).
getproperty(obj::SpinObject, sym::Symbol) = getproperty(obj, Val(sym))
setproperty!(obj::SpinObject, sym::Symbol, val) =
    setproperty!(obj, Val(sym), val)
#
# The following metgods are to deal with errors.
getproperty(obj::T, ::Val{M}) where {T<:SpinObject,M} =
    throw_unknown_field(T, M)

setproperty!(obj::T, ::Val{M}, val) where {T<:SpinObject,M} =
    if M in propertynames(obj)
        throw_read_only_field(T, M)
    else
        throw_unknown_field(T, M)
    end

@noinline throw_unknown_field(T::Type, sym::Union{Symbol,AbstractString}) =
    throw(ErrorException("objects of type $T have no field `$sym`"))

@noinline throw_read_only_field(T::Type, sym::Union{Symbol,AbstractString}) =
    throw(ErrorException("field `$sym` of objects of type $T is read-only"))

#------------------------------------------------------------------------------
# ERRORS

"""
    SpinnakerCameras.CallError(err, func)

yields an exception representing an error with code `err` occuring in a call to
function `func` of the Spinnaker SDK.

""" CallError

# Throws a `CallError` exception if `err` indicates an error in function `func`.
function _check(err::Err, func::Symbol)
    if err != SPINNAKER_ERR_SUCCESS
        throw_call_error(err, func)
    end
    return nothing
end

@noinline throw_call_error(err::Err, func::Symbol) =
    throw(CallError(err, func))

# `show` and `print` methods must be extended for `Err` to avoid errors with
# invalid enumeration values.
for func in (:print, :show)
    @eval $func(io::IO, err::Err) = begin
        try
            $func(io, Symbol(err))
        catch
            $func(io, Integer(err))
        end
    end
end

show(io::IO, ::MIME"text/plain", err::CallError) =
    print(io, "error ", err.code, " returned by function `", err.func, "`")

#------------------------------------------------------------------------------
# SYSTEM

"""
    sys = SpinnakerCameras.System()

yields an instance `sys` of Spinnaker object system.  The following properties
are implemented:

    sys.cameras        # yields the list of cameras
    sys.interfaces     # yields the list of interfaces
    sys.libraryversion # yields the version number of the SDK library
    sys.tlnodemap      # yields the transport layer node map
    sys.logginglevel   # yields the logging level

The `logginglevel` property can be set, the other are read-only.  For example:

    sys.logginglevel = SpinnakerCameras.LOG_LEVEL_INFO

""" System

propertynames(::System) = (
    :cameras,
    :interfaces,
    :libraryversion,
    :tlnodemap,
    :logginglevel)

getproperty(sys::System, ::Val{:cameras}) = CameraList(sys)
getproperty(sys::System, ::Val{:interfaces}) = InterfaceList(sys)
getproperty(sys::System, ::Val{:libraryversion}) = VersionNumber(sys)
getproperty(sys::System, ::Val{:logginglevel}) = begin
    ref = Ref{LogLevel}()
    @checked_call(:spinSystemGetLoggingLevel, (SystemHandle, Ptr{LogLevel}),
                  sys, ref)
    return ref[]
end
setproperty!(sys::System, key::Val{:logginglevel}, val::Integer) =
    setproperty!(sys, key, LogLevel(val))
setproperty!(sys::System, ::Val{:logginglevel}, val::LogLevel) =
    @checked_call(:spinSystemSetLoggingLevel, (SystemHandle, LogLevel),
                  sys, val)

"""
    SpinnakerCameras.LibraryVersion(sys)

yields the version of the Spinnaker library for object system `sys`.

"""
function LibraryVersion(sys::System)
    ref = Ref{LibraryVersion}()
    @checked_call(:spinSystemGetLibraryVersion,
                  (SystemHandle, Ptr{LibraryVersion},),
                  sys, ref)
    return ref[]
end

VersionNumber(sys::System) = VersionNumber(LibraryVersion(sys))
VersionNumber(v::LibraryVersion) =
    VersionNumber(v.major, v.minor, v.type, (), (v.build,))

#------------------------------------------------------------------------------
# LISTS OF INTERFACES

"""
    lst = SpinnakerCameras.InterfaceList(sys)

yields a list of Spinnaker interfaces for the system `sys`.  This is the same
as `sys.interfaces`.

Call `length(lst)` to retrieve the number of interfaces and use syntax `lst[i]`
to get the `i`-th interface.

""" InterfaceList

# This constructor creats an empty interface list and retrieve the interface
# list from the parent system.
function InterfaceList(system::System)
    interfacelist = InterfaceList(system, nothing)
    @checked_call(:spinSystemGetInterfaces,
                  (SystemHandle, InterfaceListHandle),
                  system, interfacelist)
    return interfacelist
end

getindex(lst::InterfaceList, i::Integer) = Interface(lst, i)

empty!(obj::InterfaceList) = begin
    @checked_call(:spinInterfaceListClear, (InterfaceListHandle,), obj)
    return obj
end

# Make interface lists, camera lists and mode maps iterable.
function iterate(itr::Union{InterfaceList,CameraList,NodeMap},
                 state::NTuple{2,Int} = (1, length(itr)))
    idx, len = state
    if idx ≤ len
        return itr[idx], (idx+1, len)
    else
        return nothing
    end
end

#------------------------------------------------------------------------------
# INTERFACES

"""
    SpinnakerCameras.Interface(lst, i)

yields the `i`-th entry of Spinnaker interface list `lst`.  This is the same as
`lst[i]`.

The following properties are implemented for interface instance:

    interface.cameras   # yields the list of cameras of the interface
    interface.tlnodemap # yields the transport layer node map of the interface

""" Interface

propertynames(::Interface) = (:cameras, :tlnodemap)

getproperty(obj::Interface, ::Val{:cameras}) = CameraList(obj)

#------------------------------------------------------------------------------
# LISTS OF CAMERAS

"""
    lst = SpinnakerCameras.CameraList(sys[, updateinterfaces, updatecameras])
    lst = SpinnakerCameras.CameraList(int[, updatecameras])

yield a list of Spinnaker cameras for the system `sys` or for the interface
`int`.   This is the same as `sys.cameras` and `int.cameras` respectively.
Optional arguments `updateinterfaces` and `updatecameras` specify whether
to update the list of interfaces and the list of cameras respectively.

Call `length(lst)` to retrieve the number of cameras and use syntax `lst[i]` to
get the `i`-th camera or `lst[ser]` to retrieve a camera by its serial number
`ser` (a string).

""" CameraList

# The following constructors create an empty camera list, then retrieve the
# camera list from the system instance.
function CameraList(system::System)
    cameralist = CameraList(system, nothing)
    @checked_call(:spinSystemGetCameras,
                  (SystemHandle, CameraListHandle),
                  system, cameralist)
    return cameralist
end
function CameraList(system::System,
                    updateinterfaces::Bool,
                    updatecameras::Bool)
    cameralist = CameraList(system, nothing)
    @checked_call(:spinSystemGetCamerasEx,
                  (SystemHandle, SpinBool, SpinBool, CameraListHandle),
                  system, updateinterfaces, updatecameras,
                  cameralist)
    return cameralist
end

# The following constructors create an empty camera list, then retrieve the
# camera list from the system instance.
function CameraList(interface::Interface)
    cameralist = CameraList(parent(check(interface)), nothing)
    @checked_call(:spinInterfaceGetCameras,
                  (InterfaceHandle, CameraListHandle),
                  interface, cameralist)
    return cameralist
end
function CameraList(interface::Interface, updatecameras::Bool)
    cameralist = CameraList(parent(check(interface)), nothing)
    @checked_call(:spinInterfaceGetCamerasEx,
                  (InterfaceHandle, SpinBool, CameraListHandle),
                  interface, updatecameras, cameralist)
    return cameralist
end

getindex(lst::CameraList, idx::Union{Integer,AbstractString}) = Camera(lst, idx)

empty!(obj::CameraList) = begin
    @checked_call(:spinCameraListClear, (CameraListHandle,), obj)
    return obj
end

#------------------------------------------------------------------------------
# CAMERAS

propertynames(::Camera) = (:nodemap, :tldevicenodemap, :tlstreamnodemap)

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
        $_jl_func(ptr::CameraHandle) =
            @checked_call($c_func, (CameraHandle,), ptr)
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
        function $_jl_func(ptr::CameraHandle)
            isnull(ptr) && return false
            ref = Ref{SpinBool}(false)
            @checked_call($c_func, (CameraHandle, Ptr{SpinBool}), ptr, ref)
            return to_bool(ref[])
        end
    end
end

#------------------------------------------------------------------------------
# NODE MAPS AND NODES

for (T, key, func) in (
    (:System,    :tlnodemap,       :spinSystemGetTLNodeMap),
    (:Interface, :tlnodemap,       :spinInterfaceGetTLNodeMap),
    (:Camera,    :nodemap,         :spinCameraGetNodeMap),
    (:Camera,    :tldevicenodemap, :spinCameraGetTLDeviceNodeMap),
    (:Camera,    :tlstreamnodemap, :spinCameraGetTLStreamNodeMap))
    @eval begin
        function getproperty(obj::$T, ::$(Val{key}))
            ref = Ref{NodeMapHandle}(0)
            @checked_call($func, ($(Symbol(T,"Handle")), Ptr{NodeMapHandle}),
                          obj, ref)
            return NodeMap(ref[], obj)
        end
    end
end

getindex(obj::NodeMap, idx::Integer) = Node(obj, idx)
getindex(obj::NodeMap, str::AbstractString) = Node(obj, str)

show(io::IO, ::MIME"text/plain", obj::NodeMap) =
    print(io, "SpinnakerCameras.NodeMap: ", length(obj), " node(s)")

show(io::IO, ::MIME"text/plain", obj::Node) =
    print(io, "SpinnakerCameras.Node: name = \"", obj.name, "\", type = ",
          Symbol(obj.type))

"""
    SpinnakerCameras.getvalue(T, node[, verif])

yields the value of a Spinnaker node.  Argument `T` is the type of the result,
`T<:Integer` for an integer-valued node and `T<:AbstractFloat` for a
real-valued node.  Optional argument `verif` is to manually specify whether to
verify the node.

""" getvalue

"""
    SpinnakerCameras.getmin(T, node)

yields the minimum value of a Spinnaker node.  Argument `T` is the type of the
result, `T<:Integer` for an integer-valued node and `T<:AbstractFloat` for a
real-valued node.

""" getmin

"""
    SpinnakerCameras.getmax(T, node)

yields the maximum value of a Spinnaker node.  Argument `T` is the type of the
result, `T<:Integer` for an integer-valued node and `T<:AbstractFloat` for a
real-valued node.

""" getmax

"""
    SpinnakerCameras.getinc(T, node)

yields the increment of an integer Spinnaker node.  Argument `T` is the type of
the result.

""" getinc

for (jl_func, type, c_func) in (
    (:getvalue, Int64,   :spinIntegerGetValue),
    (:getmin,   Int64,   :spinIntegerGetMin),
    (:getmax,   Int64,   :spinIntegerGetMax),
    (:getinc,   Int64,   :spinIntegerGeInc),
    (:getvalue, Cdouble, :spinFloatGetValue),
    (:getmin,   Cdouble, :spinFloatGetMin),
    (:getmax,   Cdouble, :spinFloatGetMAx),)
    @eval function $jl_func(::Type{$type}, node::Node)
        ref = Ref{$type}(0)
        @checked_call($c_func, (NodeHandle, Ptr{$type}), node, ref)
        return ref[]
    end
    if jl_func === :getvalue
        c_func_ex = Symbol(c_func, "Ex")
        @eval function $jl_func(::Type{$type}, node::Node, verif::Bool)
            ref = Ref{$type}(0)
            @checked_call($c_func_ex, (NodeHandle, SpinBool, Ptr{$type}),
                          node, verif, ref)
            return ref[]
        end
    end
end

for func in (:getvalue, :getmin, :getmax, :getinc)
    for (T, U) in ((:Integer, :Int64),
                   (:AbstractFloat, :Cdouble))
        if func !== :getinc || T === :Integer
            @eval $func(T::Type{<:$T}, node::Node) =
                convert(T, $func($U, node))
        end
        if func === :getvalue
            @eval $func(T::Type{<:$T}, node::Node, verif::Bool) =
                convert(T, $func($U, node, verif))
        end
    end
end

"""
    SpinnakerCameras.isavailable(nd)

yields whether node `nd` is available.

""" isavailable

"""
    SpinnakerCameras.isimplemented(nd)

yields whether node `nd` is implemented.

""" isimplemented

"""
    SpinnakerCameras.isreadable(nd)

yields whether node `nd` is readable.

""" isreadable

"""
    SpinnakerCameras.iswritable(nd)

yields whether node `nd` is writable.

""" iswritable

for (jl_func, c_func) in ((:isavailable,   :spinNodeIsAvailable),
                          (:isimplemented, :spinNodeIsImplemented),
                          (:isreadable,    :spinNodeIsReadable),
                          (:iswritable,    :spinNodeIsWritable),)
    _jl_func = Symbol("_", jl_func)
    @eval begin
        $jl_func(obj::Node) = $_jl_func(handle(obj))
        function $_jl_func(ptr::NodeHandle)
            isnull(ptr) && return false
            ref = Ref{SpinBool}(false)
            @checked_call($c_func, (NodeHandle, Ptr{SpinBool}),
                          node, ref)
            return to_bool(ref[])
        end
    end
end

isequal(a::Node, b::Node) = _isequal(handle(a), handle(b))
function _isequal(a::NodeHandle, b::NodeHandle)
    (isnull(a) || isnull(b)) && return false
    ref = Ref{SpinBool}(false)
    @checked_call(:spinNodeIsEqual,
                  (NodeHandle, NodeHandle, Ptr{SpinBool}), a, b, ref)
    return to_bool(ref[])
end

propertynames(::Node) = (
    :accessmode,
    :name,
    :cachingmode,
    :namespace,
    :visibility,
    :tooltip,
    :displayname,
    :type,
    :pollingtime)

# Implement `getproperty` for node objects.  Note that a node handle may be
# NULL (see comments about calling `spinNodeMapGetNodeByIndex`), so a default
# value is provided in that case.
for (sym, func, T, def) in (
    (:accessmode,  :spinNodeGetAccessMode,  AccessMode,  UndefinedAccesMode),
    (:name,        :spinNodeGetName,        Cstring,     ""),
    (:cachingmode, :spinNodeGetCachingMode, CachingMode, UndefinedCachingMode),
    (:namespace,   :spinNodeGetNameSpace,   NameSpace,   UndefinedNameSpace),
    (:visibility,  :spinNodeGetVisibility,  Visibility,  UndefinedVisibility),
    (:tooltip,     :spinNodeGetToolTip,     Cstring,     ""),
    (:displayname, :spinNodeGetDisplayName, Cstring,     ""),
    (:type,        :spinNodeGetType,        NodeType,    UnknownNode),
    (:pollingtime, :spinNodeGetPollingTime, Int64,       -1))
    if T === Cstring
        @eval function getproperty(obj::Node, ::$(Val{sym}))
            isnull(handle(obj)) && return $def
            local buf
            len = 0
            ptr = Ptr{UInt8}(0)
            while true
                siz = Ref{Csize_t}(len)
                @checked_call($func,
                              (NodeHandle, Ptr{UInt8}, Ptr{Csize_t}),
                              obj, ptr, siz)
                if len > 0
                    return String(resize!(buf, siz[] - 1))
                end
                len = siz[]
                buf = Vector{UInt8}(undef, len)
                ptr = pointer(buf)
            end
        end
    else
        @eval function getproperty(obj::Node, ::$(Val{sym}))
            isnull(handle(obj)) && return $def
            ref = Ref{$T}($def)
            @checked_call($func, (NodeHandle, Ptr{$T}), obj, ref)
            return ref[]
        end
    end
end
