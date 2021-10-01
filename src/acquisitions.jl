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

=========#

"""
   SpinnakerCameras.setAcquisitionmode(CameraNodemap, mode)
   Set acquisition mode
""" setAcquisitionmode


function setAcquisitionmode(obj::NodeMap, mode_str::AbstractString)
   # get acquisition node
   acquisitionModeNode = getindex(obj, "AcquisitionMode")
   # check availability and readability
   # isavailable(acquisitionModeNode)
   # isreadable(handle(acquisitionModeNode))

   # get entry node
   acquisitionModeEntryNode = EntryNode(acquisitionModeNode, mode_str)

   # get entry node value
   mode_num = getEntryValue(acquisitionModeEntryNode)

   # set the acquisitionmode node
   # isavailable(acquisitionModeNode)
   # iswritable(acquisitionModeNode)

   setvalue(acquisitionModeNode, mode_num)

end
