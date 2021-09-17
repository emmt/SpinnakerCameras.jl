#
# types.jl -
#
# Type definitions for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

# Julia type for a C enumeration.
const Cenum = Cint

# Julia type for `spinErr`, the type of the result returned by most functions
# of the Spinnaker SDK.
const SpinErr = Cenum

# Julia type for `bool8_t`, the type of booleans used in the Spinnaker SDK.
const SpinBool = UInt8

struct CallError <: Exception
    code::Cint
    func::Symbol
    name::Symbol # symbolic name of error
end

# Julia equivalent to C structure `spinLibraryVersion`.
struct LibraryVersion
    major::Cuint # Major version of the library
    minor::Cuint # Minor version of the library
    type::Cuint  # Version type of the library
    build::Cuint # Build number of the library
end

# `SpinObject` is the abstract super-type of Julia objects.  Such objects have
# a "handle" member which is the address of an opaque Spinnaker object.
abstract type SpinObject end

# In the SDK, all handle types are anonymous pointers (`void*`), but in the low
# level Julia interface, we use more specific pointers to avoid errors.
# `Ptr{<:OpaqueObject}` is the super-type of all pointers to Spinnaker objects.
abstract type OpaqueObject end

for T in (:System, :Camera, :CameraList, :Interface, :InterfaceList,
          :Node, :NodeMap, :Image)
    @eval begin
        abstract type $(Symbol("Opaque",T)) <: OpaqueObject; end
        const $(Symbol(T,"Handle")) = Ptr{$(Symbol("Opaque",T))}
    end
end

mutable struct System <: SpinObject
    handle::SystemHandle
    function System()
        ref = Ref{SystemHandle}()
        @checked_call(:spinSystemGetInstance, (Ptr{SystemHandle},), ref)
        return finalizer(_finalize, new(ref[]))
    end
end

mutable struct InterfaceList <: SpinObject
    handle::InterfaceListHandle
    system::System # needed to maintain a reference to the "system" instance
    function InterfaceList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty interface list.
        ref = Ref{InterfaceListHandle}()
        @checked_call(:spinInterfaceListCreateEmpty,
                      (Ptr{InterfaceListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the interface list from the system.
        @checked_call(:spinSystemGetInterfaces,
                      (SystemHandle, InterfaceListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end
end

mutable struct Interface <: SpinObject
    handle::InterfaceHandle
    system::System # needed to maintain a reference to the "system" instance
    function Interface(lst::InterfaceList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{InterfaceHandle}()
        @checked_call(:spinInterfaceListGet,
                      (InterfaceListHandle, Csize_t,
                       Ptr{InterfaceHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
end

mutable struct CameraList <: SpinObject
    handle::CameraListHandle
    system::System # needed to maintain a reference to the "system" instance

    function CameraList(sys::System)
        # Check argument.
        check(sys)

        # Create an empty camera list.
        ref = Ref{CameraListHandle}()
        @checked_call(:spinCameraListCreateEmpty,
                      (Ptr{CameraListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list from the system.
        @checked_call(:spinSystemGetCameras,
                      (SystemHandle, CameraListHandle),
                      handle(sys), handle(lst))

        # Return the instanciated object.
        return lst
    end

    function CameraList(int::Interface)
        # Check argument and get object system.
        sys = check(system(check(int)))

        # Create an empty camera list.
        ref = Ref{CameraListHandle}()
        @checked_call(:spinCameraListCreateEmpty,
                      (Ptr{CameraListHandle},), ref)

        # Instanciate the object and associate its finalizer (in case of
        # subsequent errors).
        lst = finalizer(_finalize, new(ref[], sys))

        # Retrieve the camera list for the interface.
        @checked_call(:spinInterfaceGetCameras,
                      (InterfaceHandle, CameraListHandle),
                      handle(int), handle(lst))

        # Return the instanciated object.
        return lst
    end
end

mutable struct Camera <: SpinObject
    handle::CameraHandle
    system::System # needed to maintain a reference to the "system" instance
    function Camera(lst::CameraList, i::Integer)
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        sys = check(system(check(lst)))
        ref = Ref{CameraHandle}()
        @checked_call(:spinCameraListGet,
                      (CameraListHandle, Csize_t, Ptr{CameraHandle}),
                      handle(lst), i - 1, ref)
        return finalizer(_finalize, new(ref[], sys))
    end
end

# FIXME: not yet interfaced

mutable struct NodeMap <: SpinObject
    handle::NodeMapHandle
    system::System # needed to maintain a reference to the "system" instance
end

mutable struct Node <: SpinObject
    handle::NodeHandle
    system::System # needed to maintain a reference to the "system" instance
    parent::NodeMap # needed to maintain a reference to the parent node map instance
    function Node(lst::NodeMap, str::AbstractString)
        sys = check(system(check(lst)))
        ref = Ref{NodeHandle}()
        @checked_call(:spinNodeMapGetNode,
                      (NodeMapHandle, Cstring, Ptr{NodeHandle}),
                      lst, str, ref)
        return finalizer(_finalize, new(ref[], sys, lst))
    end
    function Node(lst::NodeMap, i::Integer)
        sys = check(system(check(lst)))
        1 ≤ i ≤ length(lst) || error(
            "out of bound index in Spinnaker ", shortname(lst))
        ref = Ref{NodeHandle}()
        @checked_call(:spinNodeMapGetNodeByIndex,
                      (NodeMapHandle, Csize_t, Ptr{NodeHandle}),
                      lst, i - 1, ref)
        _check(err, :spinNodeMapGetNodeByIndex)
        return finalizer(_finalize, new(ref[], sys, lst))
    end
end

mutable struct Image <: SpinObject
    # The `created` member of images is to distinguish between the two kinds of
    # images provided by the Spinnaker C SDK:
    #
    # - images obtained from a call to `spinCameraGetNextImage` or
    #   `spinCameraGetNextImageEx` and released by `spinImageRelease`,
    #
    # - images created by `spinImageCreateEmpty`, `spinImageCreateEx`,
    #   `spinImageCreateEx2`, or `spinImageCreate`, and destroyed by
    #   `spinImageDestroy`.
    #
    handle::ImageHandle
    created::Bool
    Image(handle::ImageHandle, created::Bool) =
        finalizer(_finalize, new(handle, created))
    Image() = Image(ImageHandle(0), false)
end
