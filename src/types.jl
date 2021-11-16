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


# Julia equivalent to C structure `spinLibraryVersion`.
struct LibraryVersion
    major::Cuint # Major version of the library
    minor::Cuint # Minor version of the library
    type::Cuint  # Version type of the library
    build::Cuint # Build number of the library
end

# `SpinObject` is the abstract super-type of Julia objects.  Such objects have
# a "handle" member which is the address of an opaque Spinnaker object.
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

@enum PixelFormat::Int32 begin
   PixelFormat_Mono8
   PixelFormat_Mono16
   PixelFormat_RGB8Packed
   PixelFormat_BayerGR8
   PixelFormat_BayerRG8
   PixelFormat_BayerGB8
   PixelFormat_BayerBG8
   PixelFormat_BayerGR16
   PixelFormat_BayerRG16
   PixelFormat_BayerGB16
   PixelFormat_BayerBG16
   PixelFormat_Mono12Packed
   PixelFormat_BayerGR12Packed
   PixelFormat_BayerRG12Packed
   PixelFormat_BayerGB12Packed
   PixelFormat_BayerBG12Packed
   PixelFormat_YUV411Packed
   PixelFormat_YUV422Packed
   PixelFormat_YUV444Packed
   PixelFormat_Mono12p
   PixelFormat_BayerGR12p
   PixelFormat_BayerRG12p
   PixelFormat_BayerGB12p
   PixelFormat_BayerBG12p
   PixelFormat_YCbCr8
   PixelFormat_YCbCr422_8
   PixelFormat_YCbCr411_8
   PixelFormat_BGR8
   PixelFormat_BGRa8
   PixelFormat_Mono10Packed
   PixelFormat_BayerGR10Packed
   PixelFormat_BayerRG10Packed
   PixelFormat_BayerGB10Packed
   PixelFormat_BayerBG10Packed
   PixelFormat_Mono10p
   PixelFormat_BayerGR10p
   PixelFormat_BayerRG10p
   PixelFormat_BayerGB10p
   PixelFormat_Mono2p
   PixelFormat_Mono4p
   PixelFormat_Mono8s
   PixelFormat_Mono10
   PixelFormat_Mono14
   PixelFormat_Mono12
   PixelFormat_Mono16s
   PixelFormat_Mono32f
   PixelFormat_BayerBG10
   PixelFormat_BayerBG12
   PixelFormat_BayerGB10
   PixelFormat_BayerGB12
   PixelFormat_BayerGR10
   PixelFormat_BayerGR12
   PixelFormat_BayerRG10
   PixelFormat_BayerRG12
   PixelFormat_RGBa8
   PixelFormat_RGBa10
   PixelFormat_RGBa10p
   PixelFormat_RGBa12
   PixelFormat_RGBa12p
   PixelFormat_RGBa14
   PixelFormat_RGBa16
   PixelFormat_RGB8
   PixelFormat_RGB10
   PixelFormat_RGB10p
   PixelFormat_RGB10p32
   PixelFormat_RGB12
   PixelFormat_RGB12_Planar
   PixelFormat_RGB12p
   PixelFormat_RGB14
   PixelFormat_RGB16
   PixelFormat_RGB16s
   PixelFormat_RGB32f
   PixelFormat_RGB16_Planar
   PixelFormat_RGB565p
   PixelFormat_BGRa10
   PixelFormat_BGRa10p
   PixelFormat_BGRa12
   PixelFormat_BGRa12p
   PixelFormat_BGRa14
   PixelFormat_BGRa16
   PixelFormat_RGBa32
   PixelFormat_BGR10
   PixelFormat_BGR10p
   PixelFormat_BGR12
   PixelFormat_BGR12p
   PixelFormat_BGR14
   PixelFormat_BGR16
   PixelFormat_BGR565p
   PixelFormat_R8
   PixelFormat_R10
    PixelFormat_R12
    PixelFormat_R16
    PixelFormat_G8
    PixelFormat_G10
    PixelFormat_G12
    PixelFormat_G16
    PixelFormat_B8
    PixelFormat_B10
    PixelFormat_B12
    PixelFormat_B16
    PixelFormat_Coord3D_ABC8
    PixelFormat_Coord3D_ABC10p
    PixelFormat_Coord3D_ABC10p_Planar
    PixelFormat_Coord3D_ABC12p
    PixelFormat_Coord3D_ABC12p_Planar
    PixelFormat_Coord3D_ABC16
    PixelFormat_Coord3D_ABC16_Planar
    PixelFormat_Coord3D_ABC32f
    PixelFormat_Coord3D_ABC32f_Planar
   PixelFormat_Coord3D_AC8
   PixelFormat_Coord3D_AC8_Planar
   PixelFormat_Coord3D_AC10p
   PixelFormat_Coord3D_AC10p_Planar
   PixelFormat_Coord3D_AC12p
   PixelFormat_Coord3D_AC12p_Planar
   PixelFormat_Coord3D_AC16
   PixelFormat_Coord3D_AC16_Planar
   PixelFormat_Coord3D_AC32f
   PixelFormat_Coord3D_AC32f_Planar
   PixelFormat_Coord3D_A8
   PixelFormat_Coord3D_A10p
   PixelFormat_Coord3D_A12p
   PixelFormat_Coord3D_A16
   PixelFormat_Coord3D_A32f
   PixelFormat_Coord3D_B8
   PixelFormat_Coord3D_B10p
   PixelFormat_Coord3D_B12p
   PixelFormat_Coord3D_B16
   PixelFormat_Coord3D_B32f
   PixelFormat_Coord3D_C8
   PixelFormat_Coord3D_C10p
   PixelFormat_Coord3D_C12p
   PixelFormat_Coord3D_C16
   PixelFormat_Coord3D_C32f
   PixelFormat_Confidence1
   PixelFormat_Confidence1p
   PixelFormat_Confidence8
   PixelFormat_Confidence16
   PixelFormat_Confidence32f
   PixelFormat_BiColorBGRG8
   PixelFormat_BiColorBGRG10
   PixelFormat_BiColorBGRG10p
   PixelFormat_BiColorBGRG12
   PixelFormat_BiColorBGRG12p
   PixelFormat_BiColorRGBG8
   PixelFormat_BiColorRGBG10
   PixelFormat_BiColorRGBG10p
   PixelFormat_BiColorRGBG12
   PixelFormat_BiColorRGBG12p
   PixelFormat_SCF1WBWG8
   PixelFormat_SCF1WBWG10p
   PixelFormat_SCF1WBWG12
   PixelFormat_SCF1WBWG12p
   PixelFormat_SCF1WBWG14
   PixelFormat_SCF1WBWG16
   PixelFormat_SCF1WGWB8
   PixelFormat_SCF1WGWB10
   PixelFormat_SCF1WGWB10p
   PixelFormat_SCF1WGWB12
   PixelFormat_SCF1WGWB12p
   PixelFormat_SCF1WGWB14
   PixelFormat_SCF1WGWB16
   PixelFormat_SCF1WGWR8
   PixelFormat_SCF1WGWR10
   PixelFormat_SCF1WGWR10p
   PixelFormat_SCF1WGWR12
   PixelFormat_SCF1WGWR12p
   PixelFormat_SCF1WGWR14
   PixelFormat_SCF1WGWR16
   PixelFormat_SCF1WRWG8
   PixelFormat_SCF1WRWG10
   PixelFormat_SCF1WRWG10p
   PixelFormat_SCF1WRWG12
   PixelFormat_SCF1WRWG12p
   PixelFormat_SCF1WRWG14
   PixelFormat_SCF1WRWG16
   PixelFormat_YCbCr8_CbYCr
   PixelFormat_YCbCr10_CbYCr
   PixelFormat_YCbCr10p_CbYCr
   PixelFormat_YCbCr12_CbYCr
   PixelFormat_YCbCr12p_CbYCr
   PixelFormat_YCbCr411_8_CbYYCrYY
   PixelFormat_YCbCr422_8_CbYCrY
   PixelFormat_YCbCr422_10
   PixelFormat_YCbCr422_10_CbYCrY
   PixelFormat_YCbCr422_10p
   PixelFormat_YCbCr422_10p_CbYCrY
   PixelFormat_YCbCr422_12
   PixelFormat_YCbCr422_12_CbYCrY
   PixelFormat_YCbCr422_12p
   PixelFormat_YCbCr422_12p_CbYCrY
   PixelFormat_YCbCr601_8_CbYCr
   PixelFormat_YCbCr601_10_CbYCr
   PixelFormat_YCbCr601_10p_CbYCr
   PixelFormat_YCbCr601_12_CbYCr
   PixelFormat_YCbCr601_12p_CbYCr
   PixelFormat_YCbCr601_411_8_CbYYCrYY
   PixelFormat_YCbCr601_422_8
   PixelFormat_YCbCr601_422_8_CbYCrY
   PixelFormat_YCbCr601_422_10
   PixelFormat_YCbCr601_422_10_CbYCrY
   PixelFormat_YCbCr601_422_10p
   PixelFormat_YCbCr601_422_10p_CbYCrY
   PixelFormat_YCbCr601_422_12
   PixelFormat_YCbCr601_422_12_CbYCrY
   PixelFormat_YCbCr601_422_12p
   PixelFormat_YCbCr601_422_12p_CbYCrY
   PixelFormat_YCbCr709_8_CbYCr
   PixelFormat_YCbCr709_10_CbYCr
   PixelFormat_YCbCr709_10p_CbYCr
   PixelFormat_YCbCr709_12_CbYCr
   PixelFormat_YCbCr709_12p_CbYCr
   PixelFormat_YCbCr709_411_8_CbYYCYY
   PixelFormat_YCbCr709_422_8
   PixelFormat_YCbCr709_422_8_CbYCr
   PixelFormat_YCbCr709_422_10
   PixelFormat_YCbCr709_422_10_CbYCY
   PixelFormat_YCbCr709_422_10p
   PixelFormat_YCbCr709_422_10p_CbYCrY
   PixelFormat_YCbCr709_422_12
   PixelFormat_YCbCr709_422_12_CbYCrY
   PixelFormat_YCbCr709_422_12p
   PixelFormat_YCbCr709_422_12p_CbYCrY
   PixelFormat_YUV8_UYV
   PixelFormat_YUV411_8_UYYVYY
   PixelFormat_YUV422_8
   PixelFormat_YUV422_8_UYVY
   PixelFormat_Polarized8
   PixelFormat_Polarized10p
   PixelFormat_Polarized12p
   PixelFormat_Polarized16
   PixelFormat_BayerRGPolarized
   PixelFormat_BayerRGPolarized10p
   PixelFormat_BayerRGPolarized12p
   PixelFormat_BayerRGPolarized16
   PixelFormat_LLCMono8
   PixelFormat_LLCBayerRG8
   PixelFormat_JPEGMono8
   PixelFormat_JPEGColor8
   PixelFormat_Raw16
   PixelFormat_Raw8
   PixelFormat_R12_Jpeg
   PixelFormat_GR12_Jpeg
   PixelFormat_GB12_Jpeg
   PixelFormat_B12_Jpeg
   UNKNOWN_PIXELFORMAT = -1
end

# sensor shutter mode dict
SensorShutterMode = Dict(1=>"Global",
                         2 => "Rolling",
                         3 => "GlobalReset"
                        )

"""
    ImageConfigContext
    stores configuration parameters for the hardware to be set prior to the
    next acquisition loop
""" ImageConfigContext

mutable struct ImageConfigContext
    # goes to spinImageCreate
    width::Int32
    height::Int32
    offsetX::Int32
    offsetY::Int32
    pixelformat::PixelFormat

    # goes to camera
    gainvalue::Float64
    exposuretime::Float64
    reversex::Bool
    reversey::Bool

    function ImageConfigContext()
        max_width = 2048
        max_height = 1536
        return new(max_width, max_height, 0, 0,PixelFormat_Mono8,
                    10.0, 10.0, false, false)
    end
end

# Julia ImageStaus type
const ImageStatus = Cenum


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
    # Image() = Image(ImageHandle(0), false)

    # create empty
    Image() = begin
        ref = Ref{ImageHandle}(0)
        @checked_call(:spinImageCreateEmpty,
                      (Ptr{ImageHandle},),
                      ref)
        return finalizer(_finalize, new(ref[], true))

    end
    # create with image format context
    Image(config::ImageConfigContext, data::Array{UInt8}) = begin
        ref = Ref{ImageHandle}(0)
        @checked_call(:spinImageCreateEx,
                      (Ptr{ImageHandle},Csize_t,Csize_t,Csize_t,Csize_t,
                      Cenum,Ptr{Cvoid}),
                      ref, config.width, config.height, config.offsetX,
                      config.offsetY, Integer(config.pixelformat), C_NULL)
        return finalizer(_finalize, new(ref[], true))

    end

end

mutable struct System <: SpinObject
    handle::SystemHandle
    function System()
        ref = Ref{SystemHandle}(0)
        @checked_call(:spinSystemGetInstance, (Ptr{SystemHandle},), ref)
        return finalizer(_finalize, new(ref[]))
    end
end

mutable struct InterfaceList <: SpinObject
    handle::InterfaceListHandle
    system::System # needed to maintain a reference to the "system" instance
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

        # Retrieve the interface list from the system.
        @checked_call(:spinSystemGetInterfaces,
                      (SystemHandle, InterfaceListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end
end

mutable struct Interface <: SpinObject
    handle::InterfaceHandle
    system::System # needed to maintain a reference to the "system" instance
    function Interface(lst::InterfaceList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{InterfaceHandle}(0)
        @checked_call(:spinInterfaceListGet,
                      (InterfaceListHandle, Csize_t,
                       Ptr{InterfaceHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
end

mutable struct CameraList <: SpinObject
    handle::CameraListHandle
    system::System # needed to maintain a reference to the "system" instance

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

        # Retrieve the camera list from the system.
        @checked_call(:spinSystemGetCameras,
                      (SystemHandle, CameraListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end

    function CameraList(int::Interface)
        # Check argument and get object system.
        sys = check(system(check(int)))

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

mutable struct Camera <: SpinObject
    handle::CameraHandle
    system::System # needed to maintain a reference to the "system" instance
    buff::Image
    ts::HighResolutionTime
    registerd::Integer
    function Camera(lst::CameraList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{CameraHandle}(0)
        @checked_call(:spinCameraListGet,
                      (CameraListHandle, Csize_t, Ptr{CameraHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
    # undef camera for shared camera initialization
    Camera() = new()
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

    # get node by nodename
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

# Enumeration node get entry by either index or string name
# use spinEnumerationRelease API to destroy the entry node
mutable struct EntryNode <: SpinObject
    # fields
    handle::NodeHandle # entrynode handle
    parent::Node    # the Enum Node

    # contructors
    # get entry node by name
    function EntryNode(enumnode::Node, entryName::AbstractString)
        check(parent(enumnode))
        ref = Ref{NodeHandle}(0)
        @checked_call(:spinEnumerationGetEntryByName,
                    (NodeHandle, Cstring, Ptr{NodeHandle}),
                    handle(enumnode), entryName, ref)
        return finalizer(_finalize, new(ref[], enumnode))
    end

    # get entry node by index
    function EntryNode(enumnode::Node, index::Csize_t)
        check(parent(enumnode))
        ref = Ref{NodeHandle}(0)
        @checked_call(:spinEnumerationGetEntryByIndex,
                    (NodeHandle, Csize_t, Ptr{NodeHandle}),
                    handle(enumnode), index, ref)
        return finalizer(_finalize, new(ref[], enumnode))
    end
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
