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
function reset(camera::Camera)
    _camNodemape =  getproperty(camera, Val(:nodemap))
    deviceResetNode = getindex(_camNodemape, "DeviceReset")
    command_execute(deviceResetNode)
    print("Camera is reset... \n")
    return nothing

end
