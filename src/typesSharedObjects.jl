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

Type `Tao.AbstractCamera{T}` is the super-type of camera and image provider
concrete types in TAO.  Parameter `T` is the pixel type of the acquired images
or `Any` when the pixel type is unknown or undetermined.

"""
abstract type AbstractCamera{T} end


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

Type `TaoBindings.SharedCamera` is used to represent shared camera data in
Julia. It served as an interface to camera's configuration within a camera server.
A shared camera instance implements the `cam.key` syntax with the following
public properties:

| Name              | Const. | Description                                                |
|:------------------|:-------|:-----------------------------------------------------------|
| `accesspoint`     | yes    | Address of the server owning the object                    |
| `bufferrencoding` | no     | Encoding of the camera acquisition buffers                 |
| `counter`         | no     | Counter of the last acquired frame                         |
| `exposuretime`    | no     | Exposure time in seconds per frame                         |
| `framerate`       | no     | Frames per second                                          |
| `height`          | no     | Height of the ROI in macro pixels                          |
| `last`            | no     | Shared memory identifier of the last acquired image        |
| `listlength`      | yes    | Number of shared images memorized by the camera owner      |
| `lock`            | no     | Type of lock owned by the caller                           |
| `next`            | no     | Shared memory identifier of the next acquired image        |
| `owner`           | yes    | Name of the server owning the object                       |
| `pixeltype`       | no     | Pixel type of the axquired images                          |
| `sensorencoding`  | no     | Encoding of the pixel data sent by the device              |
| `sensorheight`    | yes    | Number of rows of physical pixels of the sensor            |
| `sensorwidth`     | yes    | Number of physical pixels per row of the sensor            |
| `shmid`           | yes    | Identifier of the shared memory segment storing the object |
| `size`            | yes    | Number of bytes allocated for the shared object            |
| `state`           | no     | State of the remote camera                                 |
| `type`            | yes    | Type identifier of the shared object                       |
| `width`           | no     | Width of the ROI in macro pixels                           |
| `xbin`            | no     | Horizontal binning factor                                  |
| `xoff`            | no     | Horizontal offset of the ROI                               |
| `ybin`            | no     | Vertical binning factor                                    |
| `yoff`            | no     | Vertical offset of the ROI                                 |

Notes: *ROI* is the Region Of Interest of the acquired image.  ROI offsets are
a number of physical pixels.  Binning factors are in physical pixels per macro
pixel.  Column *Const.* indicates whether the property is constant during
shared object lifetime.  To make sure that the values of non-immutable fields
are consistent, the camera should be locked by the caller.  For example:

    timeout = 30.0 # 30 seconds timeout
    if rdlock(cam, timeout)
        # Camera `cam` has been succesfuly locked for read-only access.
        stat = cam.state
        counter = cam.counter
        last = cam.last
        unlock(cam) # do not forget to release the lock as soon as possible
    else
        # Time-out occured before read-only access can be granted.
        ...
    end

!!! warn
    Properties should all be considered as read-only by the end-user and never
    directly modified or unexpected behavior may occur.

"""
mutable struct SharedCamera <: AbstractCamera{Any}

    ptr::Ptr{AbstractSharedObject}
    img_config::ImageConfigContext

    counter::Int32
    last::Int16
    next::Int16
    lastTS::Int16
    nextTS::Int16

    state::Int8
    lock::LockMode
    final::Bool    # a finalizer has been installed
    # Provide a unique inner constructor which forces starting with a NULL
    # pointer and no finalizer.
    SharedCamera() = new(C_NULL, ImageConfigContext(),
    0,UNLOCKED, false)
end

"""

Union `TaoBindings.AnySharedObject` is defined to represent any shared objects
in `TaoBindings` because shared arrays and shared cameras inherit from
`DenseArray` and `AbstractCamera` respectively, not from
`TaoBindings.AbstractSharedObject`.

"""
const AnySharedObject = Union{AbstractSharedObject,SharedArray,SharedCamera}

# The following is to have a complete signature for type statbility.
const DynamicArray{T,N} = ResizableArray{T,N,Vector{T}}

"""
    RemoteCamera{T}(dev) -> cam

wraps TAO shared camera `dev` into a higher level camera instance.  The camera
instance `dev` can also be replaced by the remote camera name.  For instance:

    cam = RemoteCamera{T}("TAO:SpinnakerCameras")

The parameter `T` is the pixel type of the acquired images.  If not specified,
it is obtained from the associated shared camera.  In any cases, it will be
asserted that `T` matches the element type of the shared arrays storing the
acquired images (and their weights).

The remote camera `cam` always provides images of element type `T` using the
connected remote camera to get/wait images.  It takes care of avoiding
attaching shared images by maintaining a mirror of the list of shared images
stored by the virtual frame-grabber owning the remote camera.  This saves the
time of attaching shared arrays.  This also avoid critical issues in a
continuous processing loop because Julia garbage collector may not finalize
(hence detach) attached arrays fast enough and their number of attachments will
therefore grow indefinitely until resources are exhausted.

The remote camera `cam` may be used as an iterator which provides images until
the acquisition is stopped (by someone else).

Compared to shared cameras (of type [`TaoBindings.SharedCamera`](@ref)),
remotes cameras (of type `RemoteCamera`) are needed to:

- provide type-stability (i.e., pixel type is known);
- preprocess images (if not yet done by the server);
- hide the list of attached shared arrays;
- avoid re-allocating resources as much as possible.

A remote camera instance implements the `cam.key` syntax with the same public
properties as a shared camera plus `cam.cached_image`
which are arrays used to store the image


| Name              | Const. | Description                                                |
|:------------------|:-------|:-----------------------------------------------------------|
| `cached_image`    | no     | Image ready to be grabed                         |

"""


mutable struct RemoteCamera{T<:AbstractFloat} <: AbstractCamera{T}
    arrays::Vector{SharedArray{T,2}} # list of attached shared arrays
    shmids::Vector{ShmId}            # list of corresponding identifiers
    timestamps::Vector{HighResolutionTime}         # list of timestamps of the shared array
    device::SharedCamera             # connection to remote camera
    cmds::ResizableVector{Int32}               # command queue
    time_origin::HighResolutionTime     # timestamp when the server is up

    # Preprocessing parameters.
    #==
    a::DynamicArray{T,2}          # gain correction
    b::DynamicArray{T,2}          # bias correction
    q::DynamicArray{T,2}          # numerator for weights
    r::DynamicArray{T,2}          # denominator for weights
==#
    # To avoid (re)allocations, the pre-processed image and its weights are
    # stored in arrays that are owned by the image provider object.
    # wgt::DynamicArray{T,2}        # weights of last image
    img::DynamicArray{T,2}        # last image
    imgTime::HighResolutionTime       # last image timestamp

    function RemoteCamera{T}(device::SharedCamera) where {T<:AbstractFloat}
        isconcretetype(T) || error("pixel type $T must be concrete")
        len = Int(device.listlength)
        arrays = Vector{SharedArray{T,2}}(undef, len)
        shmids = fill!(Vector{ShmId}(undef, len), -1)
        timestamps = fill!(Vector{HighResolutionTime}(undef,len), -1)
        cmds = ResizableVector{Int32}(undef,0)
        time_origin = device.timestamp
        # dims = (0, 0) # size is not yet known
        #==
        a = fill!(ResizableArray{T,2}(undef, dims), 1)
        b = fill!(ResizableArray{T,2}(undef, dims), 0)
        q = fill!(ResizableArray{T,2}(undef, dims), 1)
        r = fill!(ResizableArray{T,2}(undef, dims), 1)
        wgt = fill!(ResizableArray{T,2}(undef, dims), 0)
        ==#
        img = fill!(ResizableArray{T,2}(undef, dims), 0)
        imgTime = HighResolutionTime(0,0)
        return new{T}(arrays, shmids, timestamps, device,cmds,time_origin,img,imgTime)
    end
end

const RemoteCameraOutput{T} = DynamicArray{T,2}
const RemoteCameraOutputs{N,T} = NTuple{N,DynamicArray{T,2}}


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

"""
    SpinnakerCameras.RemoteCameraState
    enumeration of the RemoteCamera States

"""
@enum RemoteCameraState begin
    STATE_INIT
    STATE_WAIT
    STATE_ERROR
    STATE_WORK
    STATE_QUIT
end

"""
    SpinnakercCameras.RemoteCameraCommand
enumeration of the Remote Camera Commands

"""
@enum RemoteCameraCommand begin
    CMD_INIT
    CMD_WAIT
    CMD_ERROR
    CMD_WORK
    CMD_QUIT
end
