#
# acquisitions.jl
#
# Implement acquisition control feature
# APIs
#
#-----------------------------------------------------------------------------------

#===========
Acquisition Control Root Node

   - Root node generation
   - Enumerate
TODO: add acquisition control functionalities
=========#

"""
   SpinnakerCameras.setAcquisitionmode(CameraNodemap, mode)
   Set acquisition mode
""" setAcquisitionmode


function setAcquisitionmode(camera::Camera, mode_str::AbstractString)

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

   return  finalize(_camNodemape)

end

"""
   SpinnakerCameras.acquire_n_save_images(camera, numImg, fname, fileformat)

   acquire images of which number is specified by numImg and save the images
   in the format given by imageFormat; eg. ".jpeg". The fname is the base name of the images.
   The file name is tagged by the order of the imaging. Timeout can be specified
""" acquire_n_save_images

function acquire_n_save_images(camera::Camera, numImg::Int64, fname::String,
                            imageFormat::String; timeoutSec::Int64 = 1)
   #Begin acquisition
   SpinnakerCameras.start(camera)

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
       if  img.incomplete == 1
           print("Image $ind is incomplete.. skipepd \n")
           finalize(img)

       elseif img.status != 0
           print("Image $ind has error.. skipepd \n")
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
end


"""
    SpinnakerCameras.acquire_n_share_image(camera, shared_array)

"""

#===
    1. acquire the next image
    2. check writability of the shared array
    3. lock the shared array
    4. copy the image into the shared_array
    5. unlock the shared array
    6. destroy the image
===#


function acquire_n_share_image(camera::Camera, arr::SharedArray, timeoutSec::Int64 = 1 )
    #Begin acquisition
    SpinnakerCameras.start(camera)

    # retreive, post images

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
    if  img.incomplete == 1
        print("Image $ind is incomplete.. skipepd \n")
        finalize(img)
    elseif img.status != 0
        print("Image $ind has error.. skipepd \n")
        finalize(img)
    else

        print("Image size =",img.size,"\n")
        # copy image content to an array
        img_data = img.data
        print("image array size",  size(img_data),"\n")
        # wait for the array to be available
        sharrHandle = attach(SharedArray{Float64}, arr.shmid)
        # copy
        print("Copy image data .. \n")
        copyto!(arr, img_data)

        detach(sharrHandle)
        finalize(img)
    end

    SpinnakerCameras.stop(camera)


end
#---
#==========

   Exposure time

===========#
"""
   SpinnakerCameras.configure_exposure(camNodeMap,


""" configure_exposure

function configure_exposure(camera::Camera, exposure_time::Float64)
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

   return finalize(_camNodemape)
end

"""
   SpinnakerCameras.reset_exposure(camNodeMap)


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
    return finalize(_camNodemape)
end
