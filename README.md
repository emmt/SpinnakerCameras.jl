# Julia interface to Spinnaker cameras

The `SpinnakerCameras` package is to use cameras via the Spinnaker SDK
(Software Development Kit).

Compared to the Spinnaker SDK for C code, the managment of objects is much
simplified by the Julia interface:

- Spinnaker objects are automatically released or destroyed when their Julia
  counterpart is garbage collected.

- The syntax `obj.key` is implemented to *get* the value of the property `key`
  for object `obj` as a counterpart of the `spin*Get*` functions of the SDK.
  The syntax, `obj.key = val` is allowed for a limited number of properties.

- Julia objects provided by the `SpinnakerCameras` package should track all
  necessary dependencies so that the user do not have to worry about that.  For
  instance, a camera keeps a reference to its parent *system*.


## Installation

Copy file `deps/example-deps.jl` as `deps/deps.jl` and edit the value of
constant `lib` to reflect the full path to the Spinnaker SDK dynamic library
for C code.


## Usage

### System, list of interface, list of of camera and node maps

To deal with Spinnaker cameras and interfaces, you must first get an instance
of the Spinnaker object system:

```.jl
using SpinnakerCameras
system = SpinnakerCameras.System()
```

To retrieve a list of Spinnaker interfaces to which cameras may be connected,
call one of (the two are completely equivalent):

```.jl
interfaces = system.interfaces
interfaces = SpinnakerCameras.InterfaceList(system)
```

To get a specific interface instance, say the `i`-th one, call one of:

```.jl
interface = SpinnakerCameras.Interface(interfaces, i)
interface = interfaces[i]
```

which are completely equivalent.  As you may expect, calling
`length(interfaces)` yields the number of entries in the interface list.  Note
that the indices of Spinnaker interfaces, cameras, enumerations, and nodes are
1-based in Julia.

To retrieve a list of all cameras connected to the system, call one of:

```.jl
cameras = system.cameras
cameras = SpinnakerCameras.CameraList(system)
```

To retrieve a list of cameras connected to a given interface, call one of:

```.jl
cameras = interface.cameras
cameras = SpinnakerCameras.CameraList(interface)
```

Calling `length(cameras)` yields the number of cameras in the list.

An instance of a specific camera, say the `i`-th one, is given by:

```.jl
camera = SpinnakerCameras.Camera(cameras, i)
camera = cameras[i]
```

which are completely equivalent.

Note that you may chain operations.  For instance, you may do:

```.jl
camera = system.interfaces[2].cameras[1]
```

to retrieve the 1st camera on the 2nd interface.  Chaining operations however
results in creating temporary objects which are automatically released or destroyed
but which are only used once.

Lists of interfaces and lists of cameras are iterable so you may write:

```.jl
for camera in system.cameras
    ...
end
```

to loop over the cameras of the system.


### Node maps and nodes

Nodes have numerous properties:

```.julia
node.accessmode  # yields the access mode of `node`
node.name        # yields the name of `node`
node.cachingmode # yields the caching mode for the register of `node`
node.namespace   # yields the namespace of `node`
node.visibility  # yields the visibility of `node`,
node.tooltip     # yields the tool-tip of `node`,
node.displayname # yields the display name of `node`,
node.type        # yields the type of `node`
node.pollingtime # yields the polling-time of `node`
```


### Images

A Spinnaker image may be created by:

```.jl
img = SpinnakerCameras.Image(pixelsformat, (width,height))
```

where `pixelsformat` is an integer specifying the pixel format (see enumeration
`spinImageFileFormat` in header `SpinnakerDefsC.h` for possible values) while
the 2-tuple `(width,height)` specifies the dimensions of the image in pixels.

An image may also be acquired from a camera (streaming acquisition must be
running):

```.jl
img = SpinnakerCameras.next_image(camera)
```

which waits forever until a new image is available.  In general it is better to
specify a time limit, for instance:

```.jl
secs = 5.0 # maximum number of seconds to wait
img = SpinnakerCameras.next_image(camera, secs)
```

If you want to catch timeout errors, the following piece of code yields a
result `img` that is an image if a new image gets acquired before the time
limit, or `nothing` if the time limit is exceeded, and throws an exception
otherwise:

```.jl
img = try
    SpinnakerCameras.next_image(camera, secs)
catch ex
    if (!isa(ex, SpinnakerCameras.CallError) ||
        ex.code != SpinnakerCameras.SPINNAKER_ERR_TIMEOUT)
        rethrow(ex)
    end
    nothing
end
```

Images implement many properties.  For example:

```.jl
img.bitsperpixel     # yields the number of bits per pixel of `img`
img.buffersize       # yields the buffer size of `img`
img.data             # yields the image data of `img`
img.privatedata      # yields the private data of `img`
img.frameid          # yields the frame Id of `img`
img.height           # yields the height of `img`
img.id               # yields the Id of `img`
img.offsetx          # yields the X-offset of `img`
img.offsety          # yields the Y-offset of `img`
img.paddingx         # yields the X-padding of `img`
img.paddingy         # yields the Y-padding of `img`
img.payloadtype      # yields the payload type of `img`
img.pixelformat      # yields the pixel format of `img`
img.pixelformatname  # yields the pixel format name of `img`
img.size             # yields the size of `img` (number of bytes)
img.stride           # yields the stride of `img`
img.timestamp        # yields the timestamp of `img`
img.validpayloadsize # yields the valid payload size of `img`
img.width            # yields the width of `img`
```
