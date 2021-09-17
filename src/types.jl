#
# types.jl -
#
# Type definitions for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

# Julia type for a C enumeration.
const Cenum = Cint

# The error codes used in Spinnaker C.  These codes are returned from every
# function in Spinnaker C.
@enum Err::Cenum begin
    # An error code of 0 means that the function has run without error.
    SPINNAKER_ERR_SUCCESS = 0
    #
    # The error codes in the range of -1000 to -1999 are reserved for Spinnaker
    # exceptions.
    SPINNAKER_ERR_ERROR =               -1001
    SPINNAKER_ERR_NOT_INITIALIZED =     -1002
    SPINNAKER_ERR_NOT_IMPLEMENTED =     -1003
    SPINNAKER_ERR_RESOURCE_IN_USE =     -1004
    SPINNAKER_ERR_ACCESS_DENIED =       -1005
    SPINNAKER_ERR_INVALID_HANDLE =      -1006
    SPINNAKER_ERR_INVALID_ID =          -1007
    SPINNAKER_ERR_NO_DATA =             -1008
    SPINNAKER_ERR_INVALID_PARAMETER =   -1009
    SPINNAKER_ERR_IO =                  -1010
    SPINNAKER_ERR_TIMEOUT =             -1011
    SPINNAKER_ERR_ABORT =               -1012
    SPINNAKER_ERR_INVALID_BUFFER =      -1013
    SPINNAKER_ERR_NOT_AVAILABLE =       -1014
    SPINNAKER_ERR_INVALID_ADDRESS =     -1015
    SPINNAKER_ERR_BUFFER_TOO_SMALL =    -1016
    SPINNAKER_ERR_INVALID_INDEX =       -1017
    SPINNAKER_ERR_PARSING_CHUNK_DATA =  -1018
    SPINNAKER_ERR_INVALID_VALUE =       -1019
    SPINNAKER_ERR_RESOURCE_EXHAUSTED =  -1020
    SPINNAKER_ERR_OUT_OF_MEMORY =       -1021
    SPINNAKER_ERR_BUSY =                -1022
    #
    # The error codes in the range of -2000 to -2999 are reserved for Gen API
    # related errors.
    GENICAM_ERR_INVALID_ARGUMENT =      -2001
    GENICAM_ERR_OUT_OF_RANGE =          -2002
    GENICAM_ERR_PROPERTY =              -2003
    GENICAM_ERR_RUN_TIME =              -2004
    GENICAM_ERR_LOGICAL =               -2005
    GENICAM_ERR_ACCESS =                -2006
    GENICAM_ERR_TIMEOUT =               -2007
    GENICAM_ERR_DYNAMIC_CAST =          -2008
    GENICAM_ERR_GENERIC =               -2009
    GENICAM_ERR_BAD_ALLOCATION =        -2010
    #
    # The error codes in the range of -3000 to -3999 are reserved for image
    # processing related errors.
    SPINNAKER_ERR_IM_CONVERT =          -3001
    SPINNAKER_ERR_IM_COPY =             -3002
    SPINNAKER_ERR_IM_MALLOC =           -3003
    SPINNAKER_ERR_IM_NOT_SUPPORTED =    -3004
    SPINNAKER_ERR_IM_HISTOGRAM_RANGE =  -3005
    SPINNAKER_ERR_IM_HISTOGRAM_MEAN =   -3006
    SPINNAKER_ERR_IM_MIN_MAX =          -3007
    SPINNAKER_ERR_IM_COLOR_CONVERSION = -3008
end

# Julia type for `bool8_t`, the type of booleans used in the Spinnaker SDK.
const SpinBool = UInt8

struct CallError <: Exception
    code::Err
    func::Symbol
end

# Julia equivalent to C structure `spinLibraryVersion`.
struct LibraryVersion
    major::Cuint # Major version of the library
    minor::Cuint # Minor version of the library
    type::Cuint  # Version type of the library
    build::Cuint # Build number of the library
end

# `SpinObject` is the abstract super-type of Julia objects defined in this
# package.  Such objects have a "handle" member which is the address of an
# opaque Spinnaker object.
abstract type SpinObject end

# In the SDK, all handle types are anonymous pointers (`void*`), but in the low
# level Julia interface, we use more specific pointers to avoid errors.
# `Ptr{<:OpaqueObject}` is the super-type of all pointers to Spinnaker objects.
abstract type OpaqueObject end

for T in (:System, :Camera, :CameraList, :Interface, :InterfaceList,
          :Node, :NodeMap, :Image)
    @eval begin
        abstract type $(Symbol("Opaque",T)) <: OpaqueObject; end
        const $(Symbol(T,"Handle")) = Ptr{$(Symbol("Opaque",T))}
    end
end

# For clarity, the finalizers of objects defined by this package are all named
# `_finalize` and are implemented right after the definition of the object
# structure.
#
# This following of `_finalize` implements the do-block syntax.  If the handle
# of object `obj` is not null, function `func` is called with the handle value
# and the object handle is set to null.
function _finalize(func::Function, obj::SpinObject)
    ptr = _take_handle!(obj)
    isnull(ptr) || func(ptr)
    return nothing
end

@inline function _take_handle!(obj::T) where {T<:SpinObject}
    ptr = getfield(obj, :handle)
    setfield!(obj, :handle, fieldtype(T, :handle)(0))
    return ptr
end

mutable struct System <: SpinObject
    handle::SystemHandle
    function System()
        ref = Ref{SystemHandle}(0)
        @checked_call(:spinSystemGetInstance, (Ptr{SystemHandle},), ref)
        return finalizer(_finalize, new(ref[]))
    end
end

_finalize(obj::System) = _finalize(obj) do ptr
    @checked_call(:spinSystemReleaseInstance, (SystemHandle,), ptr)
end

mutable struct InterfaceList <: SpinObject
    handle::InterfaceListHandle
    parent::System # needed to maintain a reference to the "system" instance
    function InterfaceList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty interface list.
        ref = Ref{InterfaceListHandle}(0)
        @checked_call(:spinInterfaceListCreateEmpty,
                      (Ptr{InterfaceListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the interface list from the parent system.
        @checked_call(:spinSystemGetInterfaces,
                      (SystemHandle, InterfaceListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end
end

_finalize(obj::InterfaceList) = _finalize(obj) do ptr
    err = @unchecked_call(:spinInterfaceListClear, (InterfaceListHandle,), ptr)
    @checked_call(:spinInterfaceListDestroy, (InterfaceListHandle,), ptr)
    _check(err, :spinInterfaceListClear)
end

mutable struct Interface <: SpinObject
    handle::InterfaceHandle
    parent::System # needed to maintain a reference to the "system" instance
    function Interface(lst::InterfaceList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(parent(check(lst)))
        ref = Ref{InterfaceHandle}(0)
        @checked_call(:spinInterfaceListGet,
                      (InterfaceListHandle, Csize_t,
                       Ptr{InterfaceHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
end

_finalize(obj::Interface) = _finalize(obj) do ptr
    @checked_call(:spinInterfaceRelease, (InterfaceHandle,), ptr)
end

mutable struct CameraList <: SpinObject
    handle::CameraListHandle
    parent::System # needed to maintain a reference to the "system" instance

    function CameraList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty camera list.
        ref = Ref{CameraListHandle}(0)
        @checked_call(:spinCameraListCreateEmpty,
                      (Ptr{CameraListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list from the system instance.
        @checked_call(:spinSystemGetCameras,
                      (SystemHandle, CameraListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end

    function CameraList(int::Interface)
        # Check argument and get object system.
        sys = check(parent(check(int)))

        # Create an empty camera list.
        ref = Ref{CameraListHandle}(0)
        @checked_call(:spinCameraListCreateEmpty,
                      (Ptr{CameraListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list for the interface.
        @checked_call(:spinInterfaceGetCameras,
                      (InterfaceHandle, CameraListHandle),
                      handle(int), handle(lst))

        # Return the instanciated object.
        return lst
    end
end

_finalize(obj::CameraList) = _finalize(obj) do ptr
    err = @unchecked_call(:spinCameraListClear, (CameraListHandle,), ptr)
    @checked_call(:spinCameraListDestroy, (CameraListHandle,), ptr)
    _check(err, :spinCameraListClear)
end

mutable struct Camera <: SpinObject
    handle::CameraHandle
    parent::System # needed to maintain a reference to the "system" instance
    function Camera(lst::CameraList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(parent(check(lst)))
        ref = Ref{CameraHandle}(0)
        @checked_call(:spinCameraListGet,
                      (CameraListHandle, Csize_t, Ptr{CameraHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
end

function _finalize(obj::Camera)
    ptr = _take_handle!(obj)
    if _isinitialized(ptr)
        _deinitialize(ptr)
    end
    if !isnull(ptr)
        @checked_call(:spinCameraRelease, (CameraHandle,), ptr)
    end
    return nothing
end

# The `parent` member of a node map is needed to keep a reference on the
# associated object to avoid it being garbage collected while the node map is
# in use.  There are no functions in the SDK to release or destroy a node map,
# so there are no needs for a finalizer and a node map may be immutable.
struct NodeMap <: SpinObject
    handle::NodeMapHandle
    parent::Union{System,Interface,Camera}
end

# The `parent` member of a node is needed to keep a reference on the associated
# mode map and its parent object so as to avoid them being garbage collected
# while the node is in use.  The function `spinNodeMapReleaseNode` must be
# called to release a node, so a node must have a finalizer and is thus a
# mutable object.
mutable struct Node <: SpinObject
    handle::NodeHandle
    parent::NodeMap # needed to maintain a reference to the parent node map instance
    function Node(nodemap::NodeMap, str::AbstractString)
        check(parent(nodemap))
        ref = Ref{NodeHandle}(0)
        @checked_call(:spinNodeMapGetNode,
                      (NodeMapHandle, Cstring, Ptr{NodeHandle}),
                      handle(nodemap), str, ref)
        return finalizer(_finalize, new(ref[], nodemap))
    end
    function Node(nodemap::NodeMap, i::Integer)
        # Retrieving the length of the node map costs some time, but the error
        # returned by spinNodeMapGetNodeByIndex when the index is invalid is
        # SPINNAKER_ERR_ERROR which is not very indicative.  So we only compare
        # the index to the node map length in case of error.  When error is
        # SPINNAKER_ERR_ERROR while the index is in bounds (which does occur),
        # a "null" node is returned.
        check(parent(nodemap))
        ref = Ref{NodeHandle}(0)
        inbounds = (i ≥ 1) # check lower bound
        if inbounds
            err = @unchecked_call(:spinNodeMapGetNodeByIndex,
                                  (NodeMapHandle, Csize_t, Ptr{NodeHandle}),
                                  handle(nodemap), i - 1, ref)
            if err != SPINNAKER_ERR_SUCCESS
                inbounds &= (i ≤ length(nodemap)) # check upper bound
                if inbounds && err != SPINNAKER_ERR_ERROR
                    # error not due to out of bounds index
                    throw_call_error(err, :spinNodeMapGetNodeByIndex)
                end
            end
        end
        inbounds || error(
            "out of bounds index in Spinnaker ", shortname(nodemap))
        return finalizer(_finalize, new(ref[], nodemap))
    end
end

function _finalize(obj::Node)
    ptr = _take_handle!(obj)
    isnull(ptr) || @checked_call(:spinNodeMapReleaseNode,
                                 (NodeMapHandle, NodeHandle),
                                 handle(parent(obj)), ptr)
    return nothing
end

"""
    SpinnakerCameras.NodeType

enumeration of the possible types of a node.

"""
@enum NodeType::Cenum begin
    ValueNode
    BaseNode
    IntegerNode
    BooleanNode
    FloatNode
    CommandNode
    StringNode
    RegisterNode
    EnumerationNode
    EnumEntryNode
    CategoryNode
    PortNode
    UnknownNode = -1
end

"""
    SpinnakerCameras.AccessMode

enumeration of the possible access modes of a node.

"""
@enum AccessMode::Cenum begin
    NI
    NA
    WO
    RO
    RW
    UndefinedAccesMode
    CycleDetectAccesMode
end

"""
    SpinnakerCameras.Visibility

enumeration of the possible recommended visibilities of a node.

"""
@enum Visibility::Cenum begin
    Beginner = 0
    Expert = 1
    Guru = 2
    Invisible = 3
    UndefinedVisibility = 99
end

"""
    SpinnakerCameras.CachingMode

enumeration of the possible caching modes of a register.

"""
@enum CachingMode::Cenum begin
    NoCache              # Do not use cache
    WriteThrough         # Write to cache and register
    WriteAround          # Write to register, write to cache on read
    UndefinedCachingMode # Not yet initialized
end

"""
    SpinnakerCameras.NameSpace

enumeration of the possible namespaces of a register.

"""
@enum NameSpace::Cenum begin
    Custom             # name resides in custom namespace
    Standard           # name resides in one of the standard namespaces
    UndefinedNameSpace # Object is not yet initialized
end

mutable struct Image <: SpinObject
    # The `created` member of images is to distinguish between the two kinds of
    # images provided by the Spinnaker C SDK:
    #
    # - images obtained from a call to `spinCameraGetNextImage` or
    #   `spinCameraGetNextImageEx` and released by `spinImageRelease`,
    #
    # - images created by `spinImageCreateEmpty`, `spinImageCreateEx`,
    #   `spinImageCreateEx2`, or `spinImageCreate`, and destroyed by
    #   `spinImageDestroy`.
    #
    handle::ImageHandle
    created::Bool
    Image(handle::ImageHandle, created::Bool) =
        finalizer(_finalize, new(handle, created))
    Image() = Image(ImageHandle(0), false)
end

function _finalize(obj::Image)
    ptr = _take_handle!(obj)
    if !isnull(ptr)
        if getfield(obj, :created)
            setfield!(obj, :created, false)
            @checked_call(:spinImageDestroy, (ImageHandle,), ptr)
        else
            @checked_call(:spinImageRelease, (ImageHandle,), ptr)
        end
    end
    return nothing
end
