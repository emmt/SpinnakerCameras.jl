"""
    SpinnakerCameras

module implementing the Julia interface to Spinnaker cameras.

"""
module SpinnakerCameras

let filename = normpath(joinpath(@__DIR__, "../deps/deps.jl"))
    isfile(filename) || error(
        "File \"", filename, "\" does not exits, see \"README.md\" ",
        "for installation.")
    filename
end |> include

export
    isavailable,
    isimplemented,
    poll

import Base:
    VersionNumber,
    length, size, eltype, show, print, iterate, parent, empty!,
    isvalid, isreadable, iswritable, isequal,
    getindex, setindex!,
    getproperty, setproperty!, propertynames,
    unsafe_convert

include("macros.jl")
include("types.jl")
include("methods.jl")
include("images.jl")

end # module
