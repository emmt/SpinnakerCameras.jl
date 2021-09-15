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

The indices of Spinnaker interfaces, cameras, enumerations, and nodes are
1-based in Julia.

To deal with Spinnaker cameras and interfaces, you must first get an instance
of the Spinnaker object system:

```julia
sys = SpinnakerCameras.System()
```

To retrieve a list of Spinnaker interfaces to which cameras can be connected,
call one of:

```julia
intlst = sys[:]
intlst = SpinnakerCameras.CameraList(sys)
```

To get a specific interface instance, say the `i`-th one, call one of:

```julia
int = sys[i]
int = intlst[i]
```

The two above examples are equivalent except that the former creates a
temporary list of interfaces while the latter use an exiting list.  Calling
`length(intlst)` yields the number of entries in the interface list.

To retrieve a list of Spinnaker cameras, call one of:

```julia
camlst = SpinnakerCameras.CameraList(sys)
camlst = SpinnakerCameras.CameraList(int)
```

where the former yields the list of all cameras connected to Spinnaker system
`sys` while the latter yields the list of all cameras connected to the
Spinnaker interface `int`.  Calling `length(camlst)` yields the number of
cameras in the list.

An instance of a specific camera, say the `i`-th one, is given by:

```julia
cam = SpinnakerCameras.Camera(camlist, i)
cam = camlist[i]
```

which are completely equivalent.
