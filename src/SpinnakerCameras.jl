#
# Spinnaker.jl -
#
# Julia interface to Spinnaker cameras.
#
#------------------------------------------------------------------------------

module SpinnakerCameras

let deps = normpath(joinpath(@__DIR__, "../deps/deps.jl"))
    isfile(deps) || error(
        "File \"$deps\" does not exits, see \"README.md\" for installation.")
    include(deps)
end

import Base:
    VersionNumber,
    length, size, eltype, show, iterate, parent, empty!,
    isvalid, isreadable, iswritable, isequal,
    getindex, setindex!,
    getproperty, setproperty!, propertynames

import Printf

include("macros.jl")
include("types.jl")
include("errors.jl")
include("methods.jl")
include("images.jl")
include("acquisitions.jl")
include("device.jl")


end # module
