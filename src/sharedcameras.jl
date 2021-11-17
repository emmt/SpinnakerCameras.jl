#
# cameras.jl --
#
# Management of cameras for the Julia interface to the C libraries of TAO, a
# Toolkit for Adaptive Optics.
#
#------------------------------------------------------------------------------
#
# This file is part of TAO software (https://git-cral.univ-lyon1.fr/tao)
# licensed under the MIT license.
#
# Copyright (C) 2018-2021, Éric Thiébaut.
#

propertynames(cam::SharedCamera) =
    (
     :accesspoint,
     :lock
     :owner,
     :shmid,

    # device control
     # :modelname,
     :serialnumber,
     # :firmware_version,
     # :manufacturerinfo,
     :userid,
     :TLtype,
     :timestamp
     :temperature,

     # Analog Control
     :gain,
     # :gainauto

     # image format control
     # :sensorencoding,
     :sensorheight,
     :sensorwidth,
     :pixelhieght,
     :pixelwidth,
     :shuttermode,
     :reversex,
     :reversey,
     :size,
     :height,
     :pixelformat,
     :width,
     # :xbin,
     # :ybin
     :xoff,
     :yoff,
     :compressionmode,

     # Acquisition Control
     :framerate,
     :exposuretime,


     )
getCameraInfo(dev::SharedCamera) = begin
        print(dev.camera.s)

end

getfield(dev::SharedCamera, ::Val{:camera}) = throw(ErrorException("Cannot access the camera directly"))


propertynames(cam::RemoteCamera) =
    (
      :cached_image,
      :accesspoint,
      :lock
      :owner,
      :shmid,


     # device control
      # :modelname,
      :serialnumber,
      # :firmware_version,
      # :manufacturerinfo,
      :userid,
      :TLtype,
      :timestamp
      :temperature,

      # Analog Control
      :gain,
      # :gainauto

      # image format control
      # :sensorencoding,
      :sensorheight,
      :sensorwidth,
      :pixelhieght,
      :pixelwidth,
      :shuttermode,
      :reversex,
      :reversey,
      :size,
      :height,
      :pixelformat,
      :width,
      # :xbin,
      # :ybin
      :xoff,
      :yoff,
      :compressionmode,

      # Acquisition Control
      :framerate,
      :exposuretime,

     )

getproperty(cam::RemoteCamera, sym::Symbol) =
    getattribute(cam, Val(sym))

setproperty!(cam::RemoteCamera, sym::Symbol, val) =
setattribute!(cam, Val(sym), val)

getattribute(cam::RemoteCamera, ::Val{:lock}) = getfield(cam, :lock)
getattribute(cam::RemoteCamera, ::Val{:cached_image}) = getfield(cam, :img)
getattribute(cam::RemoteCamera{T}, ::Val{:pixeltype}) where {T} = T

getattribute(cam::RemoteCamera, key::Val) = getattribute(device(cam), key)

# Constructors for `RemoteCamera`s.
RemoteCamera(dev::SharedCamera) = RemoteCamera{dev.pixeltype}(dev)
# RemoteCamera(srv::ServerName) = RemoteCamera(attach(SharedCamera, srv))
# RemoteCamera{T}(srv::ServerName) where {T<:AbstractFloat} =
#     RemoteCamera{T}(attach(SharedCamera, srv))

# Private accessors specific to remote cameras.
_get_shmids(cam::RemoteCamera) = getfield(cam, :shmids)
_get_arrays(cam::RemoteCamera) = getfield(cam, :arrays)
_get_timestamps(cam::RemoteCamera) = getfield(cam, :timestamps)
# Accessors.
camera(cam::RemoteCamera) = cam
camera(cam::SharedCamera) = cam
device(cam::RemoteCamera) = getfield(cam, :device)
device(cam::SharedCamera) = cam
eltype(::AbstractCamera{T}) where {T} = T
#==
eltype(::Type{<:SingleImage}, ::RemoteCamera{T}) where {T} = T
eltype(::Type{<:WeightedImage}, ::RemoteCamera{T}) where {T} = T
length(cam::RemoteCamera) = length(_get_shmids(cam))
length(::Type{<:CameraOutput}, cam::RemoteCamera) = length(device(cam))
size(::Type{<:CameraOutput}, cam::RemoteCamera) = size(device(cam))
size(::Type{<:CameraOutput}, cam::RemoteCamera, k) = size(device(cam), k)
==#

show(io::IO, cam::RemoteCamera{T}) where {T} =
    print(io, "RemoteCamera{$T}(owner=\"", cam.owner,
          "\", accesspoint=\"", cam.accesspoint,
          "\", counter=", cam.counter, ")")

# Make cameras iterable. We call the `timedwait` method rather that `wait` to
# avoid waiting forever.  FIXME: Compute a reasonable timeout for cameras
# (requires to known the framerate and the exposure time).
iterate(cam::AbstractCamera, ::Union{Nothing,Tuple{Any,Any}}=nothing) =
                (timedwait(cam, 30.0), nothing)



# function create(::Type{SharedCamera}; owner::AbstractString = default_owner(),
#                 perms::Integer = 0o600)
#
#     length(owner) < SHARED_OWNER_SIZE || error("owner name too long")
#
#     ptr = ccall((:tao_create_shared_object, taolib), Ptr{AbstractSharedObject},
#                 (Cstring, UInt32, Csize_t, Cuint),
#                 owner, _fix_shared_object_type(SHARED_CAMERA), sizeof(SharedCamera), perms)
#
#     _check(ptr != C_NULL)
#
#     return _wrap(SharedCamera, ptr)
# end


## attach extension
function attach(::Type{SharedCamera}, shmid::Integer)
    # Attach the shared object to the address space of the caller, then wrap it
    # in a Julia object.
    ptr = ccall((:tao_attach_shared_camera, taolib),
                Ptr{AbstractSharedObject}, (ShmId,), shmid)
    _check(ptr != C_NULL)
    cam = _wrap(SharedCamera, ptr)
    return cam
end

"""
    Tao.start(cam; skip=0, timeout=5.0)

    starts image acquisition by shared or remote camera `cam`.  If acquisition is
    already running, nothing is done; otherwise a `"start"` command is sent to the
    server and keywords `skip` and `timeout` amy be used to specify the number of
    initial frames to skip (none by default) and the maximum number of seconds to
    wait for each skipped image (5 seconds by default).  This is useful to avoid
    initial garbage images for cameras without a shutter.

"""
start(cam::RemoteCamera; kwds...) = start(device(cam); kwds...)
start(cam::SharedCamera; skip::Integer=0, timeout::Real=5.0) = begin

    skip ≥ 0 || throw(ArgumentError("invalid number of images to skip"))
    timeout > 0 || throw(ArgumentError("invalid timeout"))

    state, apt = rdlock(cam, timeout) do
        cam.state, cam.accesspoint
    end

    if state != CAMERA_STATE_ACQUIRING && state != CAMERA_STATE_STARTING
        if state != CAMERA_STATE_SLEEPING
            error("acquisition cannot be started")
        end

        XPA.set(apt, "start")
        while skip > 0
            timedwait(cam, timeout) # FIXME:
            skip -= one(skip) # takes care of type-stability
        end
    end
    nothing
end

"""
    Tao.stop(cam; timeout=5.0)

    stops image acquisition by shared or remote camera `cam` not waiting more than
    the limit set by `timeout` in seconds.  Nothing is done if acquisition is not
    running or about to start.

"""
stop(cam::RemoteCamera; kwds...) = stop(device(cam); kwds...)
stop(cam::SharedCamera; timeout::Real=5.0) = begin
    state, apt = rdlock(cam, timeout) do
        cam.state, cam.accesspoint
    end
    if state == CAMERA_STATE_ACQUIRING || state == CAMERA_STATE_STARTING
        XPA.set(apt, "stop")
    end
    nothing
end

"""
    Tao.abort(cam; timeout=5.0)

    aborts image acquisition by shared or remote camera `cam` not waiting more than
    the limit set by `timeout` in seconds.  Nothing is done if acquisition is not
    running or about to start.

"""
abort(cam::RemoteCamera; kwds...) = abort(device(cam); kwds...)
abort(cam::SharedCamera; timeout::Real=5.0) = begin
    state, apt = rdlock(cam, timeout) do
        cam.state, cam.accesspoint
    end
    if state == CAMERA_STATE_ACQUIRING || state == CAMERA_STATE_STARTING
        XPA.set(apt, "abort")
    end
    nothing
end

#==
"""
    registerCamera(SharedCamera,Camera)
    register a camera to a shared camera instance

"""
function registerCamera(shrcam::SharedCamera, camera::Camera)


end


"""
    wait_camera(camera)
    the shared camera waits for the image to be available
"""
==#

"""
    TaoBindings.fetch(cam, sym, timeout=1.0) -> arr

    yields the shared array storing an image acquired by the remote camera `cam`.
    Argument `sym` may be `:last` to fetch the last acquired frame, or `:next` to
    fetch the next one.  The call never blocks more than the limit set by `timeout`
    and is just used for locking the camera (which should never be very long).

    The result is a shared array which should be locked for reading to make sure
    its contents is preserved and up to date.

    When fetching the next frame, the array counter should be checked to assert the
    vailidity of the frame:

        arr = fetch(cam, :next)
        rdlock(arr) do
            if arr.counter > 0
                # This is a valid frame.
                ...
            else
                # Acquisition has been stopped.
                ...
            end
        end

"""
function fetch(cam::RemoteCamera, sym::Symbol, timeout=1.0)
    # Get the number of acquired images and the shared memory identifers of the
    # the last and nex images.
    dev = device(cam)
    counter, last, next, lastTS, nextTS = rdlock(dev, timeout) do
        Int(dev.counter), dev.last, dev.next, dev.lastTS, dev.nextTS
    end
    if sym === :next
        counter += 1
        shmid = next
        timestamp = nextTS
    elseif sym === :last
        shmid = last
        timestamp = lastTS
    else
        throw(ArgumentError("invalid acquisition buffer identifier"))
    end
    if counter < 1 || shmid == BAD_SHMID
        error("no images have been acquired yet, first start acquisition")
    end

    # To avoid the overheads of systematically attaching/detaching shared
    # arrays, figure out whether we already have attached the shared array in
    # our list.
    arrays = _get_arrays(cam)                # list of shared arrays
    shmids = _get_shmids(cam)                # list if shared memory identifiers
    timestamps = _get_timestamps(cam)
    index = (counter - 1)%length(shmids) + 1
    if shmids[index] != shmid
        # FIXME: if shmid != BAD_SHMID
        # FIXME:     warning("we are loosing frames!")
        # FIXME: end
        arrays[index] = attach(SharedArray, shmid)
        shmids[index] = shmid
        timestamps[index] = timestamp
    end
    return arrays[index], timestamps[index]
end

"""
    timedwait(T, cam, timeout) -> [wgt,] img

    waits for a new image to be available from the remote camera `cam` and returns
    the result specified by `T`, that is either a simple image if `T = SingleImage`
    or an array of weights and an image if `T = WeightedImage`.

    The `timeout` argument is to specify a time limit for waiting.  If it is a
    2-tuple, `timeout[1]` is for waiting for the remote camera and `timeout[2]` is
    for waiting for the image.  Otherwise the default time limit of
    `TaoBindings.fetch` is assumed for waiting for the camera and `timeout` is for
    waiting for the image.

    For example, to wait for the next image with a timout of 0.1 second on the
    shared camera and a timeout of 2 seconds on the image, call:

        timedwait( cam, (0.1, 2))


    See also: [`TaoBindings.fetch`](@ref), [`TaoBindings.rdlock`](@ref).

"""

function Base.timedwait(cam::RemoteCamera, timeout)
    # fetch the image data from Remote Camera
    arr, ts = fetch(cam, :next)
    # made the data available in the acquisition buffer
    rdlock(arr, timeout) do
        _produce(arr, cam)
        cam.imgTime = ts
    end

end

@inline fastmax(a::T, b::T) where {T<:AbstractFloat} = (b > a ? b : a)

function _produce(buf::SharedArray{<:Any,2},
                  cam::RemoteCamera{T}) where {T}
      #copy the shared array to RemoteCamera buffer
    nx, ny = size(buf)
    img = cam.cached_imag
    @inbounds for y in 1:ny
        @simd for x in 1:nx
            img[x,y] = T(buf[x,y])
        end
    end

end
