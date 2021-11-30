#
# Spinnaker.jl -
#
# Julia interface to Spinnaker cameras.
#
#------------------------------------------------------------------------------

module SpinnakerCameras

using Printf
using Images

using Base: @propagate_inbounds
using Base.Threads: @spawn, Condition
import Base:
    VersionNumber,
    axes,
    copy,
    deepcopy,
    eachindex,
    eltype,
    empty!,
    fill!,
    firstindex,
    getindex,
    getproperty,
    isvalid,
    isreadable,
    iswritable,
    isequal,
    islocked,
    iterate,
    IndexStyle,
    last,
    lastindex,
    length,
    lock,
    ndims,
    propertynames,
    parent,
    reset,
    reshape,
    size,
    show,
    showerror,
    similar,
    stride,
    setproperty!,
    setindex!,
    timedwait,
    trylock,
    unlock,
    wait

using Printf


# TAO bindings
using Statistics
using ArrayTools
using ResizableArrays
import Base.Libc: TimeVal
using Base: @propagate_inbounds

# include dependents
begin deps = normpath(joinpath(@__DIR__, "../deps/deps.jl"))
    isfile(deps) || error(
        "File \"$deps\" does not exits, see \"README.md\" for installation.")
    include(deps)
end
# Spinnaker interface
include("macros.jl")
include("types.jl")
include("errors.jl")
include("methods.jl")
include("images.jl")

include("typesSharedObjects.jl")
include("times.jl")
include("sharedobjects.jl")
include("sharedarrays.jl")
include("sharedcameras.jl")
include("taoerrors.jl")

include("camera.jl")
include("acquisitions.jl")




end # module
