#
# Spinnaker.jl -
#
# Julia interface to Spinnaker cameras.
#
#------------------------------------------------------------------------------

module SpinnakerCameras

let deps = normpath(joinpath(@__DIR__, "../deps/deps.jl"))
    isfile(deps) || error(
        "file \"$deps\" does not exits, see \"README.md\" for installation.")
    include(deps)
end

import Base:
    length, eltype, show,
    isvalid,
    getindex, setindex!,
    getproperty, setproperty!, propertynames

include("types.jl")
include("errors.jl")
include("methods.jl")

end # module
