using SpinnakerCameras
import Printf

# Acquisition params
modeStr = "Continuous"
const numImg = UInt(5)
# Image format params
imageFormat = ".jpeg"
imageSize = (500, 350)

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


print("Set acquisition mode to $modeStr ... \n ")

SpinnakerCameras.setAcquisitionmode(camNodeMap, modeStr)

# acquire image
print("Acquiring images ..\n")
SpinnakerCameras.start(camera)
timeoutSec = 2
fname = "SpinnakerCameras_image"
# retreive, convert, and save images
for ind in 1:numImg

    img =
    try
        SpinnakerCameras.next_image(camera, timeoutSec)
    catch ex
        if (!isa(ex, SpinnakerCameras.CallError) ||
            ex.code != SpinnakerCameras.SPINNAKER_ERR_TIMEOUT)
            rethrow(ex)
        end
        nothing
    end
    # check image completeness
    if SpinnakerCameras.image_incomplete(img)
        print("Image $ind is incomplete.. skipepd \n")
        finalize(img)

    else
            # save image
        fname_now = Printf.@sprintf "%s_%d%s" fname ind imageFormat
        SpinnakerCameras.save_image(img, fname_now )
        print("Image $ind is complete.. saved as $fname_now \n")
        finalize(img)
    end

end

SpinnakerCameras.stop(camera)
SpinnakerCameras.deinitialize(camera)

finalize(camera)
finalize(camList)
finalize(system)

print("Example is complete....\n")
