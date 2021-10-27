#
# device.jl
#
# general camera status functions
# APIs
#
#-----------------------------------------------------------------------------------

# export device_reset, device_temperature

#===========
Reset
=========#
"""
    SpinnakerCameras.device_reset(camera)
    Power cycle the device. The device needs to be rediscovered

""" device_reset
function device_reset(camera::Camera)
    _camNodemape = camera.nodemap
    deviceResetNode = _camNodemape["DeviceReset"]
    command_execute(deviceResetNode)
    print("Camera is reset... \n")
    return finalize(_camNodemape)
end

#============


===========#
"""
    SpinnakerCameras.device_tempertaure(camera)
    return current device temperature in °C
""" device_temperature

function device_temperature(camera::Camera)
    _camNodemape =  camera.nodemap
    deviceTemperatureNode = _camNodemape["DeviceTemperature"]
    isavailable(deviceTemperatureNode)
    isreadable(deviceTemperatureNode)

    temperature =  getvalue(Cdouble, deviceTemperatureNode, true)
    finalize(_camNodemape)

    return  temperature
end
