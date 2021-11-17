#
# camera.jl
#
# general camera status functions
# APIs
#

#------------------------------------------------------------------------------
#==
    Configuration functions
==#

"""
   SpinnakerCameras.setAcquisitionmode(camera, mode_str)
   Set acquisition mode
""" set_acquisitionmode
function set_acquisitionmode(camera::Camera, mode_str::AbstractString)

    _camNodemape = camera.nodemap
   # get acquisition node
   acquisitionModeNode = _camNodemape["AcquisitionMode"]

   # check availability and readability
   isavailable(acquisitionModeNode)
   isreadable(acquisitionModeNode)

   # get entry node
   acquisitionModeEntryNode = EntryNode(acquisitionModeNode, mode_str)

   # get entry node value
   mode_num = getEntryValue(acquisitionModeEntryNode)

   # set the acquisitionmode node
   isavailable(acquisitionModeNode)
   iswritable(acquisitionModeNode)

   setEnumValue(acquisitionModeNode, mode_num)

   finalize(acquisitionModeEntryNode)
   finalize(acquisitionModeNode)
   finalize(_camNodemape)

end

"""
   SpinnakerCameras.configure_exposure(camera,exposure_time)

""" set_exposuretime
function set_exposuretime(camera::Camera, exposure_time::Float64)
    _camNodemape = camera.nodemap

   # turn off automatic exposure time
   exposureAutoNode = _camNodemape["ExposureAuto"]
   isavailable(exposureAutoNode)
   isreadable(exposureAutoNode)
   exposureOffNode = EntryNode(exposureAutoNode, "Off")
   exposureOffInt = getEntryValue(exposureOffNode)

   isavailable(exposureAutoNode)
   iswritable(exposureAutoNode)
   setEnumValue(exposureAutoNode, exposureOffInt)

   # check maximum exposure time
   exposureTimeNode = _camNodemape["ExposureTime"]
   isavailable(exposureTimeNode)
   isreadable(exposureTimeNode)
   exposureMax = getmax(Float64, exposureTimeNode)
   exposure_time > exposureMax ? exposure_time = exposureMax : nothing

   isavailable(exposureTimeNode)
   iswritable(exposureTimeNode)
   setValue(exposureTimeNode, exposure_time)

end

"""
   SpinnakerCameras.reset_exposure(camera)
""" reset_exposure

function reset_exposure(camera::Camera)
    _camNodemape =  camera.nodemap

   # turn off automatic exposure time
   exposureAutoNode = _camNodemape["ExposureAuto"]
   isavailable(exposureAutoNode)
   isreadable(exposureAutoNode)
   exposureOnNode = EntryNode(exposureAutoNode, "Continuous")
   exposureOnInt = getEntryValue(exposureOnNode)

   isavailable(exposureAutoNode)
   iswritable(exposureAutoNode)
   setEnumValue(exposureAutoNode, exposureOnInt)
end

"""
 SpinnakerCameras.set_gain(camera, gainvalue)

""" set_gain

function set_gain(camera::Camera, gainvalue::Float64)
    _camNodemape = camera.nodemap

   # turn off automatic exposure time
   gainAutoNode = _camNodemape["GainAuto"]
   isavailable(gainAutoNode)
   isreadable(gainAutoNode)
   gainOffNode = EntryNode(gainAutoNode, "Off")
   gainOffNodeInt = getEntryValue(gainOffNode)

   isavailable(gainAutoNode)
   iswritable(gainAutoNode)
   setEnumValue(gainAutoNode, gainOffNodeInt)

   # check maximum exposure time
   gainValueNode = _camNodemape["Gain"]
   isavailable(gainValueNode)
   isreadable(gainValueNode)
   gainMax = getmax(Float64, gainValueNode)
   gainvalue > gainMax ? gainvalue = gainMax : nothing

   isavailable(gainValueNode)
   iswritable(gainValueNode)
   setValue(gainValueNode, gainvalue)
end

"""
    SpinnakerCameras.set_shuttermode(camera, shuttermode)
""" set_shuttermode

function set_shuttermode(camera::Camera, shuttermode::AbstractString)

    _camNodemape = camera.nodemap
    # get shuttermode node
    SensorShutterModeNode = _camNodemape["SensorShutterMode"]

    # check availability and readability
    isavailable(SensorShutterModeNode)
    isreadable(SensorShutterModeNode)

    # get entry node
    SensorShutterModeEntryNode = EntryNode(SensorShutterModeNode, shuttermode)

    # get entry node value
    mode_num = getEntryValue(SensorShutterModeEntryNode)

    # set the shuttermode node
    isavailable(SensorShutterModeNode)
    iswritable(SensorShutterModeNode)

    setEnumValue(SensorShutterModeNode, mode_num)
end

"""
    SpinnakerCameras.set_reverse(cameara,reverse_dir)
""" set_reverse
function set_reverse(camera::Camera, reverse_dir::Symbol)
    input = [:x,:y,:X,:Y]
    reverse_dir ∈ inpuy || throw(ArgumentError("invalid reverse direction"))

    if reverse_dir == :x
        reverse_dir == :X
    else
        reverse_dir == :Y
    end

    _camNodemape = camera.nodemap
    # get reverse node
    ReverseNode = _camNodemape["Reverse$(reverse_dir)"]

    # check availability and readability
    isavailable(ReverseNode)
    isreadable(ReverseNode)

    setValue(ReverseNode,true)
end


#==
    CAMEARA OPERATION
==#
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


for (jl_func, c_func) in ((:initialize,         :spinCameraInit),
                          (:deinitialize,       :spinCameraDeInit),
                          (:start,              :spinCameraBeginAcquisition),
                          (:stop,               :spinCameraEndAcquisition),)
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


"""
    Acquisition
    create image buffer, and start image acquisition.
""" beginCameraAcquisition
#==
function beginCameraAcquisition(camera::Camera, imgConfig::ImageConfigContext ; nbufs::Integer = 2)

    # allocate image buffer
    camAcquisitionBuffer =fill!(Vector{Array{UInt8,2}}(undef, nbufs),zeros(imgConfig.height,imgConfig.width))

    # set acquisition mode
    set_acquisitionmode(camera, "Continuous")

    # config the camera
    set_exposuretime(camera, imgConfig.exposuretime)
    set_gain(camera, imgConfig.gainvalue)
    # set_reverse(img.Config.)

    # begin acquisition
    @info "start acquisition loop"
    start(camera)
    counter = 1
    while true

        img =
        try
            SpinnakerCameras.next_image(camera, 1)
        catch ex
            if (!isa(ex, SpinnakerCameras.CallError) ||
                ex.code != SpinnakerCameras.SPINNAKER_ERR_TIMEOUT)
                rethrow(ex)
            end
            nothing
        end

        img.incomplete != 1 ||  @goto clear_img
        img.status == 0     ||  @goto clear_img

            ind = (counter-1)%nbufs + 1
            copyto!(camAcquisitionBuffer[ind], img.data)
            counter +=1

        @label clear_img
            finalize(img)


    end

end
==#

"""
    SpinnakerCameras.reset(camera)
    Power cycle the device. The device needs to be rediscovered

""" reset
function reset(camera::Camera)
    _camNodemape = camera.nodemap
    deviceResetNode = _camNodemape["DeviceReset"]
    command_execute(deviceResetNode)
    print("Camera is reset... \n")
    return finalize(_camNodemape)
end

"""
    SpinnakerCameras.device_tempertaure(camera)
    return current device temperature in °C
""" camear_temperature

function camera_temperature(camera::Camera)
    _camNodemape =  camera.nodemap
    deviceTemperatureNode = _camNodemape["DeviceTemperature"]
    isavailable(deviceTemperatureNode)
    isreadable(deviceTemperatureNode)

    temperature =  getvalue(Cdouble, deviceTemperatureNode, true)
    finalize(_camNodemape)

    return  temperature
end


function _finalize(obj::Camera)
    ptr = handle(obj)
    if _isinitialized(ptr)
        _deinitialize(ptr)
    end
    if !isnull(ptr)

        err1 = @unchecked_call(:spinCameraDeInit, (CameraHandle,), ptr)
        err2 = @unchecked_call(:spinCameraRelease, (CameraHandle,), ptr)
        _check(err1,:spinCameraDeInit)
        _check(err2,:spinCameraRelease)

        _clear_handle!(obj)
    end
    return nothing
end
