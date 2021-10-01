#
# images.jl -
#
# Management of images in the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

const PixelFormat_Mono8 = Cenum(0)
const PixelFormat_Mono16 = Cenum(1)

function _finalize(obj::Image)
    ptr = handle(obj)
    if !isnull(ptr)
        _clear_handle!(obj)
        if getfield(obj, :created)
            setfield!(obj, :created, false)
            @checked_call(:spinImageDestroy, (ImageHandle,), ptr)
        else
            @checked_call(:spinImageRelease, (ImageHandle,), ptr)
        end
    end
    return nothing
end

"""
   SpinnakerCameras.next_image(cam[, secs=Inf]) -> img

yiedls the next image from camera `cam` waiting no longer than `secs` seconds.

See [`SpinnakerCameras.Image`](@ref) for properties of images.

"""
function next_image(camera::Camera)
    ref = Ref{ImageHandle}(0)
    @checked_call(:spinCameraGetNextImage,
                  (CameraHandle, Ptr{ImageHandle}),
                  handle(camera), ref)
    return Image(ref[], false)
end

function next_image(camera::Camera, seconds::Real)
    ref = Ref{ImageHandle}(0)
    milliseconds = round(Int64, seconds*1_000)
    @checked_call(:spinCameraGetNextImageEx,
                  (CameraHandle, Int64, Ptr{ImageHandle}),
                  handle(camera), milliseconds, ref)
    return Image(ref[], false)
end

"""
    img = SpinnakerCameras.Image(pixelformat, (width, height); offsetx=0, offsety=0)

builds a new Spinnaker image instance.  The pixel format is an integer, for
example one of:

- `SpinnakerCameras.PixelFormat_Mono8`

- `SpinnakerCameras.PixelFormat_Mono16`

The `img.key` syntax is supported for the following properties:

    img.bitsperpixel     # yields the number of bits per pixel of `img`
    img.buffersize       # yields the buffer size of `img`
    img.data             # yields the image data of `img`
    img.privatedata      # yields the private data of `img`
    img.frameid          # yields the frame Id of `img`
    img.height           # yields the height of `img`
    img.id               # yields the Id of `img`
    img.offsetx          # yields the X-offset of `img`
    img.offsety          # yields the Y-offset of `img`
    img.paddingx         # yields the X-padding of `img`
    img.paddingy         # yields the Y-padding of `img`
    img.payloadtype      # yields the payload type of `img`
    img.pixelformat      # yields the pixel format of `img`
    img.pixelformatname  # yields the pixel format name of `img`
    img.size             # yields the size of `img` (number of bytes)
    img.stride           # yields the stride of `img`
    img.timestamp        # yields the timestamp of `img`
    img.validpayloadsize # yields the valid payload size of `img`
    img.width            # yields the width of `img`

Call `size(img)` to get its dimensions as a 2-tuple of `Int`s.

See also [`SpinnakerCameras.next_image`](@ref).

""" Image

function Image(pixelformat::Integer,
               dims::Tuple{Integer,Integer};
               offsetx::Integer = 0,
               offsety::Integer = 0)
    width, height = dims
    width   ≥ 1 || throw(ArgumentError("invalid image width"))
    height  ≥ 1 || throw(ArgumentError("invalid image height"))
    offsetx ≥ 0 || throw(ArgumentError("invalid image X-offset"))
    offsety ≥ 0 || throw(ArgumentError("invalid image Y-offset"))
    ref = Ref{ImageHandle}(0)
    @checked_call(
        :spinImageCreateEx,
        (Ptr{ImageHandle}, Csize_t, Csize_t, Csize_t, Csize_t, Cenum, Ptr{Cvoid}),
        ref, width, height, offsetx, offsety, pixelformat, C_NULL)
    return Image(ref[], true)
end


size(img::Image) = (Int(img.width), Int(img.height))

getproperty(img::Image, sym::Symbol) = getproperty(img, Val(sym))

setproperty!(img::Image, sym::Symbol, val) =
    error("members of Spinnaker ", shortname(img), " are read-only")

propertynames(::Image) = (
    :bitsperpixel,
    :buffersize,
    :data,
    :privatedata,
    :frameid,
    :height,
    :id,
    :offsetx,
    :offsety,
    :paddingx,
    :paddingy,
    :payloadtype,
    :pixelformat,
    :pixelformatname,
    :size,
    :stride,
    :timestamp,
    :validpayloadsize,
    :width)

for (sym, func, type) in (
    (:bitsperpixel,     :spinImageGetBitsPerPixel,     Csize_t),
    (:buffersize,       :spinImageGetBufferSize,       Csize_t),
    (:data,             :spinImageGetData,             Ptr{Cvoid}),
    (:privatedata,      :spinImageGetPrivateData,      Ptr{Cvoid}),
    (:frameid,          :spinImageGetFrameID,          UInt64),
    (:height,           :spinImageGetHeight,           Csize_t),
    (:id,               :spinImageGetID,               UInt64),
    (:offsetx,          :spinImageGetOffsetX,          Csize_t),
    (:offsety,          :spinImageGetOffsetY,          Csize_t),
    (:paddingx,         :spinImageGetPaddingX,         Csize_t),
    (:paddingy,         :spinImageGetPaddingY,         Csize_t),
    (:payloadtype,      :spinImageGetPayloadType,      Csize_t),
    (:pixelformat,      :spinImageGetPixelFormat,      Cenum),
    (:size,             :spinImageGetSize,             Csize_t),
    (:stride,           :spinImageGetStride,           Csize_t),
    (:timestamp,        :spinImageGetTimeStamp,        UInt64),

    (:tlpixelformat,    :spinImageGetTLPixelFormat,    UInt64),

    (:validpayloadsize, :spinImageGetValidPayloadSize, Csize_t),
    (:width,            :spinImageGetWidth,            Csize_t),)

    @eval function getproperty(img::Image, ::$(Val{sym}))
        ref = Ref{$type}(0)
        @checked_call($func, (ImageHandle, Ptr{$type}), handle(img), ref)
        return ref[]
    end
end

function getproperty(img::Image, ::Val{:pixelformatname})
    # FIXME: first call with NULL buffer to get the size.
    buf = Vector{UInt8}(undef, 32)
    siz = Ref{Csize_t}(0)
    while true
        siz[] = length(buf)
        err = @unchecked_call(:spinImageGetPixelFormatName,
                              (ImageHandle, Ptr{UInt8}, Ptr{Csize_t}),
                              handle(img), buf, siz)
        if err == SPINNAKER_ERR_SUCCESS
            return String(resize!(buf, siz[] - 1))
        elseif err == SPINNAKER_ERR_INVALID_BUFFER
            # Double the buffer size.
            resize!(buf, 2*length(buf))
        else
            throw(CallError(err, :spinImageGetPixelFormatName))
        end
    end
end


"""
    SpinnakerCameras.save_image(image, filename)

save the image contained in the handle in the given filename

""" save_image
save_image(image::Image, fname::AbstractString)= @checked_call(:spinImageSaveFromExt,
                                                    (ImageHandle, Cstring),
                                                    handle(image), fname)

#SPINNAKERC_API spinImageIsIncomplete(spinImage hImage, bool8_t* pbIsIncomplete);
#(:tlpayloadtype, :spinImageGetTLPayloadType, spinPayloadTypeInfoIDs*),
#(:status, :spinImageGetStatus, spinImageStatus*),
"""
    SpinnakerCameras.image_incomplete(image) -> bool


""" image_incomplete
function image_incomplete(image::Image)
    ref = Ref{SpinBool}(false)
    @checked_call(:spinImageIsIncomplete,(ImageHandle, Ptr{SpinBool}),
                handle(image), ref)

    return to_bool(ref[])
end
