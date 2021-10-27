#
# Spinnaker.jl -
#
# Julia interface to Spinnaker cameras.
#
#------------------------------------------------------------------------------

module SpinnakerCameras

using Printf




using Base: @propagate_inbounds
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

include("typesSharedObjects.jl")
include("sharedobjects.jl")
include("sharedarrays.jl")
include("taoerrors.jl")

# Spinnaker interface
include("macros.jl")
include("types.jl")
include("errors.jl")
include("methods.jl")
include("images.jl")
include("acquisitions.jl")
include("device.jl")




end # module
