using SpinnakerCameras
import Printf

# Acquisition params
modeStr = "Continuous"
numImg = 5
# Image format params
imageFormat = ".jpeg"
imageSize = (500, 350)

# Exposure
exposure_time = 100.0


system = SpinnakerCameras.System()
camList = SpinnakerCameras.CameraList(system)
camNum = length(camList)

if camNum == 0
    finalize(camList)
    finalize(system)
    print("No cameras found... \n Done...")

end
print("$(camNum) cameras are found \n" )
print("Starting a camera....\n\n")

camera = camList[1]
SpinnakerCameras.initialize(camera)
camNodeMap = SpinnakerCameras.getproperty(camera, Val(:nodemap))

print("Set acquisition mode to $modeStr ... \n")

SpinnakerCameras.setAcquisitionmode(camNodeMap, modeStr)

# set exposure
print("Set exposure time to $exposure_time\n")
SpinnakerCameras.configure_exposure(camNodeMap, exposure_time)


# acquire image
print("Acquiring images ..\n")
fname = "SpinnakerCameras_image"
SpinnakerCameras.acquire_n_save_images(camera, numImg, fname, imageFormat)

SpinnakerCameras.reset_exposure(camNodeMap)
SpinnakerCameras.deinitialize(camera)

# finalize the objects
for obj in (:camera, :camList, :system)
    eval(Expr(:call,:finalize, obj))
end
print("Example is complete ..\n")
