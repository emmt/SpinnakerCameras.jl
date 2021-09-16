# Julia interface to Spinnaker cameras

The `SpinnakerCameras` package is to use cameras via the Spinnaker SDK
(Software Development Kit).

## Installation

Copy file `deps/example-deps.jl` as `deps/deps.jl` and edit the value of
constant `lib` to reflect the full path to the Spinnaker SDK dynamic library
for C code.


## Usage

Compared to the Spinnaker SDK for C code, the managment of objects is much
simplified by the Julia interface.  For instance, Spinnaker objects are
automatically released or destroyed when their Julia counterpart is rabage
collected.

To deal with Spinnaker cameras and interfaces, you must first get an instance
of the Spinnaker object system:

```julia
using SpinnakerCameras
system = SpinnakerCameras.System()
```

To retrieve a list of Spinnaker interfaces to which cameras can be connected,
call one of:

```julia
interfaces = system.interfaces
interfaces = SpinnakerCameras.InterfaceList(system)
```

To get a specific interface instance, say the `i`-th one, call one of:

```julia
interface = SpinnakerCameras.Interface(interfaces, i)
interface = interfaces[i]
```

which are completely equivalent.  As you may expect, calling
`length(interfaces)` yields the number of entries in the interface list.  Note
that the indices of Spinnaker interfaces, cameras, enumerations, and nodes are
1-based in Julia.

To retrieve a list of all cameras connected to the system, call one of:

```julia
cameras = system.cameras
cameras = SpinnakerCameras.CameraList(system)
```

To retrieve a list of cameras connected to a given interface, call one of:

```julia
cameras = interface.cameras
cameras = SpinnakerCameras.CameraList(interface)
```

Calling `length(cameras)` yields the number of cameras in the list.

An instance of a specific camera, say the `i`-th one, is given by:

```julia
camera = SpinnakerCameras.Camera(cameras, i)
camera = cameras[i]
```

which are completely equivalent.

Note that you may chain operations.  For instance, you may do:

```julia
camera = system.interfaces[2].cameras[1]
```

to retrieve the 1st camera on the 2nd interface.  Chaining operations however
results in creating temporary objects which are automatically released or destroyed
but which are only used once.

Lists of interfaces and lists of cameras are iterable so you may write:

```julia
for camera in system.cameras
    ...
end
```

to loop over the cameras of the system.
