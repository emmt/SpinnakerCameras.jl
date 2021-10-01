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


function setAcquisitionmode(obj::NodeMap, mode_str::AbstractString)
   # get acquisition node
   acquisitionModeNode = getindex(obj, "AcquisitionMode")

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

   # print("Successfully set acquisition mode ... \n")

end

"""
   SpinnakerCameras.acquire_n_save_images(camear, numImg, fname, fileformat)

   acquire images of which number is specified by numImg and save the images
   in the format given by imageFormat; eg. ".jpeg". The fname is the base name of the images.
   The file name is tagged by the order of the imaging. Timeout can be specified
""" acquire_n_save_images

function acquire_n_save_images(camera::Camera, numImg::Int64, fname::String, imageFormat::String; timeoutSec::Int64 = 1)
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
end

#---
#==========

   Exposure time

===========#
"""
   SpinnakerCameras.configure_exposure(camNodeMap,


""" configure_exposure

function configure_exposure(camNodeMap::NodeMap, exposure_time::Float64)
   # turn off automatic exposure time
   exposureAutoNode = getindex(camNodeMap,"ExposureAuto")
   isavailable(exposureAutoNode)
   isreadable(exposureAutoNode)
   exposureOffNode = EntryNode(exposureAutoNode, "Off")
   exposureOffInt = getEntryValue(exposureOffNode)

   isavailable(exposureAutoNode)
   iswritable(exposureAutoNode)
   setEnumValue(exposureAutoNode, exposureOffInt)

   # check maximum exposure time
   exposureTimeNode = getindex(camNodeMap,"ExposureTime")
   isavailable(exposureTimeNode)
   isreadable(exposureTimeNode)
   exposureMax = getmax(Float64, exposureTimeNode)
   exposure_time > exposureMax ? exposure_time = exposureMax : nothing

   isavailable(exposureTimeNode)
   iswritable(exposureTimeNode)
   setValue(exposureTimeNode, exposure_time)


end

"""
   SpinnakerCameras.reset_exposure(camNodeMap)


""" reset_exposure

function reset_exposure(camNodeMap::NodeMap)
   # turn off automatic exposure time
   exposureAutoNode = getindex(camNodeMap,"ExposureAuto")
   isavailable(exposureAutoNode)
   isreadable(exposureAutoNode)
   exposureOnNode = EntryNode(exposureAutoNode, "Continuous")
   exposureOnInt = getEntryValue(exposureOnNode)

   isavailable(exposureAutoNode)
   iswritable(exposureAutoNode)
   setEnumValue(exposureAutoNode, exposureOnInt)

end
