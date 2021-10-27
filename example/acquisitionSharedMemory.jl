using SpinnakerCameras
using Printf

# Acquisition params
modeStr = "SingleFrame"

# Image format params
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

print("Set acquisition mode to $modeStr ... \n")

SpinnakerCameras.setAcquisitionmode(camera, modeStr)

# set exposure
print("Set exposure time to $exposure_time\n")
SpinnakerCameras.configure_exposure(camera, exposure_time)
#---
#==
    Acquire image and post it in the shared memroy via shared array structure
    psuedo code
    1. create shared array
    2. acquire image
    3. put image into the shared memory
    4. invoke data reading script --> read and save image

=#

sharr = SpinnakerCameras.create(SpinnakerCameras.SharedArray{Float64,2},
    (1536,2048), perms = 0o666)


SpinnakerCameras.acquire_n_share_image(camera, sharr)

rarr = SpinnakerCameras.attach(SpinnakerCameras.SharedArray, sharr.shmid)


readImg = Array{Float64,2}(undef,(1536,2048))

copyto!(readImg,rarr)

print("Read image ..\n")
#---

SpinnakerCameras.deinitialize(camera)

# finalize the objects
for obj in (:camera, :camList, :system)
    eval(Expr(:call,:finalize, obj))
end
print("Example is complete ..\n")
