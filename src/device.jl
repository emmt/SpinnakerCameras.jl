#
# device.jl
#
# general camera status functions
# APIs
#
#-----------------------------------------------------------------------------------



#===========
Reset
=========#
"""
    SpinnakerCameras.reset()
"""
function reset(camera::Camera)
    _camNodemape = camera.nodemap
    deviceResetNode = camNodemape["DeviceReset"]
    command_execute(deviceResetNode)
    print("Camera is reset... \n")
    return finalize(_camNodemape)
end

#============


===========#

function device_temperature(camera::Camera)
    _camNodemape =  camera.nodemap
    deviceTemperatureNode = _camNodemape["DeviceTemperature"]
    isavailable(deviceTemperatureNode)
    isreadable(deviceTemperatureNode)

    temperature =  getvalue(Cdouble, deviceTemperatureNode, true)
    finalize(_camNodemape)

    return  temperature
end
