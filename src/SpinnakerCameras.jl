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
    length, eltype, show, isvalid, isreadable, iswritable, isequal, parent,
    getindex, setindex!,
    getproperty, setproperty!, propertynames

include("macros.jl")
include("types.jl")
include("errors.jl")
include("methods.jl")

end # module
