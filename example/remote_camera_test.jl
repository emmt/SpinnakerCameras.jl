using SpinnakerCameras
import Printf

# Acquisition params
modeStr = "Continuous"

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

dev = SpinnakerCameras.create(SpinnakerCameras.SharedCamera)
