#
# cameras.jl --
#
# Management of cameras for the Julia interface to the C libraries of TAO, a
# Toolkit for Adaptive Optics.
#
#------------------------------------------------------------------------------
#
# This file is part of TAO software (https://git-cral.univ-lyon1.fr/tao)
# licensed under the MIT license.
#
# Copyright (C) 2018-2021, Éric Thiébaut.
#

propertynames(cam::SharedCamera) =
    (
     #tao attribute
     :owner,
     :shmid,
     :size,

     :lock,
     :attachedCam,
     :cameras,
     :img_config,      #shared TODO file
     :listlength,
     :last,
     :next,
     :lastTS,
     :nextTS

#==
    # device control
     # :modelname,
     :serialnumber,
     # :firmware_version,
     # :manufacturerinfo,
     :userid,
     :TLtype,
     :timestamp
     :temperature,

     # Analog Control
     :gain,
     # :gainauto

     # image format control
     # :sensorencoding,
     :sensorheight,
     :sensorwidth,
     :pixelhieght,
     :pixelwidth,
     :shuttermode,
     :reversex,
     :reversey,
     :size,
     :height,
     :pixelformat,
     :width,
     # :xbin,
     # :ybin
     :xoff,
     :yoff,
     :compressionmode,

     # Acquisition Control
     :framerate,
     :exposuretime,
==#

     )
# dispatch for sharedcamera
getproperty(dev::SharedCamera, sym::Symbol) =
                            getproperty(dev,Val(sym))

#dispatch tao attribute
getproperty(dev::SharedCamera,::Val{:shmid}) = getattribute(dev,Val(:shmid))
getproperty(dev::SharedCamera,::Val{:size}) = getattribute(dev,Val(:size))
getproperty(dev::SharedCamera,::Val{:owner}) = getattribute(dev,Val(:owner))

# relay to taolib
getattribute(obj::SharedCamera, ::Val{:shmid}) =
    ccall((:tao_get_shared_data_shmid, taolib), ShmId,
          (Ptr{AbstractSharedObject},), obj)

getattribute(obj::SharedCamera, ::Val{:size}) =
    ccall((:tao_get_shared_data_size, taolib), Csize_t,
          (Ptr{AbstractSharedObject},), obj)

getattribute(obj::SharedCamera, ::Val{:owner}) =
  _pointer_to_string(ccall((:tao_get_shared_object_owner, taolib),
                             Ptr{UInt8}, (Ptr{AbstractSharedObject},), obj))


# dispatch Julia properties
getproperty(dev::SharedCamera, ::Val{sym}) where{sym} =
                                        getfield(dev, sym)

# property is read-only
setproperty!(dev::SharedCamera, sym::Symbol, val)  =
                                setattribute!(dev,Val(sym),val)


# attribute manipulation function
inc_attachedCam(dev::SharedCamera) = begin
                        val = dev.attachedCam +1
                        setfield!(dev, :attachedCam,Int8(val))
                    end

# get_pixeltype(dev::SharedCamera) = PixelType(dev.img_config.pixelformat)
#TODO: PixelType = > pair pixel format to Julia Type

for sym in (
            :last,
            :next,
            :lastTs,
            :nextTS
                    )
    _sym = "$sym"
    @eval $(Symbol("set_",sym))(dev::SharedCamera,val::Integer) =
                                    setfield!(dev,Symbol($_sym),Int16(val))
end

#--- RemoteCamera property

propertynames(cam::RemoteCamera) =
    (
      # RemoteCamera properties
      :timestamps,
      :img,
      :imgTime,
      :cmds,
      :time_origin,

      # SharedCamera
      :owner,
      :shmid,
      :lock,
      :attachedcam,
      :listlength,
      :state,
      :counter,
      :last,
      :next,
      :lastTS,
      :nextTS
#==
     # device control
      # :modelname,
      :serialnumber,
      # :firmware_version,
      # :manufacturerinfo,
      :userid,
      :TLtype,
      :timestamp
      :temperature,

      # Analog Control
      :gain,
      # :gainauto

      # image format control
      # :sensorencoding,
      :sensorheight,
      :sensorwidth,
      :pixelhieght,
      :pixelwidth,
      :shuttermode,
      :reversex,
      :reversey,
      :size,
      :height,
      :pixelformat,
      :width,
      # :xbin,
      # :ybin
      :xoff,
      :yoff,
      :compressionmode,

      # Acquisition Control
      :framerate,
      :exposuretime,
      ==#
     )

#top level dispatch
getproperty(remoteCam::RemoteCamera,sym::Symbol) = getproperty(remoteCam, Val(sym))

#RemoteCamera properties (read-only)
for sym in (:timestamps,
            :img,
            :imgTime,
            :shmids,
            :arrays,
            :device,
            :time_origin)
    _sym = "$sym"
    @eval getproperty(remoteCam::RemoteCamera,::$(Val{sym})) =
                        getfield(remoteCam,Symbol($_sym))
end


# Shared Camera properties
# getattribute(cam::RemoteCamera, ::Val{:lock}) = getfield(device(cam), :lock)
getproperty(remoteCam::RemoteCamera, key::Val)=
                                        getproperty(device(remoteCam), key)


# wall to setting properties
setproperty!(remoteCam::RemoteCamera, sym::Symbol, val) =
    throw_non_existing_or_read_only_attribute(remoteCam,sym)


# Constructors for `RemoteCamera`s.
# RemoteCamera(dev::SharedCamera) = RemoteCamera{dev.pixeltype}(dev)

# RemoteCamera(srv::ServerName) = RemoteCamera(attach(SharedCamera, srv))
# RemoteCamera{T}(srv::ServerName) where {T<:AbstractFloat} =
#     RemoteCamera{T}(attach(SharedCamera, srv))

#--- Abstract Monitor property
propertynames(monitor::RemoteCameraMonitor) = (
                                            :shmid,
                                            :cmds,
                                            :state,
                                            :procedures,
                                            :lock,
                                            :empty_cmds,
                                            :state_updating    )

getproperty(monitor::AbstractMonitor, sym::Symbol) = getproperty(monitor, Val(sym))

getproperty(monitor::RemoteCameraMonitor, ::Val{:cmds}) = getfield(monitor, :cmds)
getproperty(monitor::RemoteCameraMonitor, ::Val{:state}) = getfield(monitor, :state)
getproperty(monitor::RemoteCameraMonitor, ::Val{:procedures}) = getfield(monitor, :procedures)
getproperty(monitor::RemoteCameraMonitor, ::Val{:lock}) = getfield(monitor, :lock)

getproperty(monitor::RemoteCameraMonitor, ::Val{:shmid}) =
ccall((:tao_get_shared_data_shmid, taolib), ShmId,(Ptr{AbstractSharedObject},), monitor)

getproperty(monitor::RemoteCameraMonitor, ::Val{:empty_cmds}) = getfield(monitor, :empty_cmds)
getproperty(monitor::RemoteCameraMonitor, ::Val{:state_updating}) = getfield(monitor, :state_updating)



propertynames(monitor::SharedCameraMonitor) = (
                                                :cmd,
                                                :shmid,
                                                :start_status,
                                                :completion,
                                                :image_counter,
                                                :procedures,
                                                :lock,
                                                :no_cmd,
                                                :not_started,
                                                :not_complete)


getproperty(monitor::SharedCameraMonitor, ::Val{:cmd}) = getfield(monitor, :cmd)
getproperty(monitor::SharedCameraMonitor, ::Val{:start_status}) = getfield(monitor, :start_status)
getproperty(monitor::SharedCameraMonitor, ::Val{:completion}) = getfield(monitor, :completion)
getproperty(monitor::SharedCameraMonitor, ::Val{:image_counter}) = getfield(monitor, :image_counter)
getproperty(monitor::SharedCameraMonitor, ::Val{:procedures}) = getfield(monitor, :procedures)
getproperty(monitor::SharedCameraMonitor, ::Val{:lock}) = getfield(monitor, :lock)

getproperty(monitor::SharedCameraMonitor, ::Val{:shmid}) =
    ccall((:tao_get_shared_data_shmid, taolib), ShmId,(Ptr{AbstractSharedObject},), monitor)

getproperty(monitor::SharedCameraMonitor, ::Val{:no_cmd}) = getfield(monitor, :no_cmd)
getproperty(monitor::SharedCameraMonitor, ::Val{:not_started}) = getfield(monitor, :not_started)
getproperty(monitor::SharedCameraMonitor, ::Val{:not_complete}) = getfield(monitor, :not_complete)

propertynames(monitor::DataMonitor) = ( :lock,
                                        :fetch_index,
                                        :release_counter,
                                        :procedures,

                                        :wait_to_fetch,
                                        :fetch_index_updated,
                                        :fetch_index_read)

getproperty(monitor::DataMonitor, ::Val{:lock}) = getfield(monitor, :lock)

getproperty(monitor::DataMonitor, ::Val{:fetch_index}) = getfield(monitor, :fetch_index)
getproperty(monitor::DataMonitor, ::Val{:release_counter}) = getfield(monitor, :release_counter)
getproperty(monitor::DataMonitor, ::Val{:procedures}) = getfield(monitor, :procedures)

getproperty(monitor::DataMonitor, ::Val{:wait_to_fetch}) = getfield(monitor, :wait_to_fetch)
getproperty(monitor::DataMonitor, ::Val{:fetch_index_updated}) = getfield(monitor, :fetch_index_updated)
getproperty(monitor::DataMonitor, ::Val{:fetch_index_read}) = getfield(monitor, :fetch_index_read)

#--- Accessors.
camera(cam::RemoteCamera) = cam
camera(cam::SharedCamera) = cam
device(cam::RemoteCamera) = getfield(cam, :device)
device(cam::SharedCamera,i::Int64) = cam.cameras[i]
eltype(::AbstractCamera{T}) where {T} = T
cmds(monitor::RemoteCameraMonitor) = begin
                                    rdlock(monitor.cmds,0.5) do
                                        monitor.cmds
                                    end
                                end
state(monitor::RemoteCameraMonitor) = begin
                                    rdlock(monitor.state,0.5) do
                                        monitor.state
                                    end
                                end


show(io::IO, cam::RemoteCamera{T}) where {T} =
    print(io, "RemoteCamera{$T}(owner=\"", cam.owner,")")

# Make cameras iterable. We call the `timedwait` method rather that `wait` to
# avoid waiting forever.  FIXME: Compute a reasonable timeout for cameras
# (requires to known the framerate and the exposure time).
iterate(cam::AbstractCamera, ::Union{Nothing,Tuple{Any,Any}}=nothing) =
                (timedwait(cam, 30.0), nothing)

thread_safe_wait(r::Condition) = begin
                                lock(r)
                                try
                                  wait(r)
                                finally
                                  unlock(r)
                                end
                              end
thread_safe_notify(r::Condition) = begin
                                lock(r)
                                try
                                  wait(r)
                                finally
                                  unlock(r)
                                end
                              end
#--- create functions
function create(::Type{SharedCamera}; owner::AbstractString = default_owner(),
                perms::Integer = 0o600)

    length(owner) < SHARED_OWNER_SIZE || error("owner name too long")

    ptr = ccall((:tao_create_shared_object, taolib), Ptr{AbstractSharedObject},
                (Cstring, UInt32, Csize_t, Cuint),
                owner, _fix_shared_object_type(SHARED_CAMERA), 464, perms)
                # 464 bytes from sizeof(tao_shar_camera) in C program
    _check(ptr != C_NULL)

    return _wrap(SharedCamera, ptr)
end

function create_monitor_shared_object!(::Type{SharedObject},monitor::AbstractMonitor;
                owner::AbstractString = default_owner(),perms::Integer = 0o600)
        length(owner) < SHARED_OWNER_SIZE || error("owner name too long")

        ptr = ccall((:tao_create_shared_object, taolib), Ptr{AbstractSharedObject},
                    (Cstring, UInt32, Csize_t, Cuint),
                    owner, _fix_shared_object_type(SHARED_OBJECT), 256, perms)
                    # 256 bytes from sizeof(tao_shar_camera) in C program
        _check(ptr != C_NULL)
        _set_ptr!(monitor,ptr)
        if ptr != C_NULL
            finalizer(_finalize, monitor)
            _set_final!(monitor, true)
        end

        return monitor
end

function register(dev::SharedCamera, cam::Camera)
    inc_attachedCam(dev)
    try
        dev.cameras[dev.attachedCam] = cam
    catch
        throw(ErrorException("No more space to attach cameras"))
    end
end


function broadcast_shmids(shmids::Vector{ShmId})
    fname = "shmid.txt"
    path = "/tmp/SpinnakerCameras/"
    open(path*fname,"w") do f
        for shmid in shmids
            write(f,@sprintf("%d\n",shmid))
        end
    end
end
#--- Server

for (cmd, now_state, next_state) in (
        (:CMD_INIT,  :STATE_UNKNOWN   ,   STATE_INIT),
        (:CMD_WORK,  :STATE_WAIT      ,   STATE_WORK),
        (:CMD_STOP,  :STATE_WORK      ,   STATE_WAIT),
        (:CMD_QUIT,  :STATE_WAIT      ,   STATE_QUIT),
    )

    @eval sort_next_state(::Val{$cmd}, ::Val{$now_state}) = $next_state
end

# sort_next_state(Val(),::Val{SIG_ERROR})
for (sig, cmd, next_state) in (
        (:SIG_DONE,  :CMD_INIT      ,   STATE_WAIT),
        (:SIG_DONE,  :CMD_STOP      ,   STATE_WAIT),
        (:SIG_DONE,  :CMD_WORK      ,   STATE_WORK),
        (:SIG_DONE,  :CMD_ABORT     ,   STATE_WAIT),
        (:SIG_DONE,  :CMD_QUIT      ,   STATE_QUIT),
        (:SIG_ERROR,  :CMD_WORK      ,   STATE_ERROR),
    )

    @eval sort_next_state(::Val{$cmd}, ::Val{$sig}) = $next_state
end
# util functions
sort_next_state(cmd::RemoteCameraCommand, current_state::RemoteCameraState) = sort_next_state(Val(cmd), Val(current_state))
sort_next_state(cmd::RemoteCameraCommand, shcam_sig::ShCamSIG) = sort_next_state(Val(cmd), Val(shcam_sig))

updating_shcam_cmd(shcam::SharedCamera,monitorSC::SharedCameraMonitor,
                   remcam::RemoteCamera, monitorRC::RemoteCameraMonitor) =
                        @spawn _updating_shcam_cmd(shcam,monitorSC,remcam,monitorRC)

function _updating_shcam_cmd(shcam::SharedCamera,monitorSC::SharedCameraMonitor,
                              remcam::RemoteCamera, monitorRC::RemoteCameraMonitor)

    thr_id = Threads.threadid()
    @info "shcam thread id = $thr_id"
    while true
        wait(monitorSC.no_cmd)
        cmd = rdlock(monitorSC,0.5) do
             monitorSC.cmd
         end
         # start command
        next_camera_operation(cmd,shcam,monitorSC,remcam,monitorRC)
        # reset cmd
        wrlock(monitorSC,0.5)do
            monitorSC.procedures[7](monitorSC)
        end

        # @info "ShCam monitor is on standby...\n"
    end
end


"""
    SpinnakerCameras.listening()
    Does command and state updates on the Remotecamera
""" listening
listening(monitorRC::RemoteCameraMonitor, monitorSC::SharedCameraMonitor) = begin
                                              try
                                                 addproc()
                                                 @spawn _listening(monitorRC,monitorSC)
                                               catch ex
                                                 @error ex
                                               end
                                          end

function _listening(monitorRC::RemoteCameraMonitor, monitorSC::SharedCameraMonitor)
    thr_id = Threads.threadid()
    println(" listening thread id = $thr_id")
    while true
        @label start
        emp =  rdlock(monitorRC,1) do
          iscmdempty(monitorRC)
        end
        if emp
            @info "RemoteCamera is on standby"
            thread_safe_wait(monitorRC.empty_cmds)

        end
        # read cmd and current state
        cmd, current_state = rdlock(monitorRC,0) do
            monitorRC.procedures[1](monitorRC) , monitorRC.procedures[3](monitorRC)
        end

        # sent command to shared camera
        wrlock(monitorSC,0.5) do
            monitorSC.procedures[2](monitorSC,cmd)

        end
        # check response
        thread_safe_wait(monitorSC.not_started)

        shcam_response = rdlock(monitorSC,0.5) do
            monitorSC.start_status
        end
        if shcam_response != SIG_OK
            wrlock(monitorRC,0.5) do
                monitorRC.procedures[4](monitorRC,STATE_ERROR)
                monitorRC.procedures[5](monitorRC)
            end
            @goto start

        end

        # figure out state to write
        state_to_write = sort_next_state(cmd,current_state)
        @info "next state $state_to_write"
        # update the state and push the cmds
        wrlock(monitorRC,0.5) do
            monitorRC.procedures[4](monitorRC,state_to_write)
            monitorRC.procedures[5](monitorRC)
        end
        thread_safe_notify(monitorRC.state_updating)
        # @info "update state after start"
        # wait the shared camera to signal is completion
        thread_safe_wait(monitorSC.not_complete)
        completion = rdlock(monitorSC,1) do
            monitorSC.completion
        end
        state_to_write = sort_next_state(cmd, completion)
        # @info "next state $state_to_write"
        wrlock(monitorRC,0.5) do
            monitorRC.procedures[4](monitorRC,state_to_write)
        end

    end

end


@inline unpack(pack::DataPack) = (pack.img, pack.ts, pack.numID)
@inline fecth_lastest_index(ind_now::Int64, buff_length::Int64) = (ind_now-1)%buff_length+1
"""
    SpinnakerCameras.grabbing()
    Grab data from camera and put in RemoteCamera Arrays
""" grabbing
grabbing(c_buff::Channel{DataPack},shcam::SharedCamera,
          remcam::RemoteCamera,monitorRC::RemoteCameraMonitor,
           monitorDT::DataMonitor) = begin

                  try
                      @spawn _grabbing(c_buff,shcam,remcam,monitorRC,monitorDT)
                    catch ex
                      @error ex
                    end
                  end

function _grabbing(c_buff::Channel{DataPack},shcam::SharedCamera,remcam::RemoteCamera,
                    monitorRC::RemoteCameraMonitor, monitorDT::DataMonitor)

      buff_length = shcam.listlength
      signaling_fetching = true
      thr_id = Threads.threadid()
      @info "start grabbing loop thread id = $thr_id"
      while true
        if isempty(c_buff)
          thread_safe_wait(c_buff)
        end
        # @info "grabbing data"
        data_pack = take!(c_buff)
        (img, ts, id) = unpack(data_pack)
        ind_array = fecth_lastest_index(id, Int64(buff_length))
        println("id = $id")
        # lock data monitor
        wrlock(monitorDT,1.0) do
          copyto!(remcam.arrays[ind_array], img)
          remcam.timestamps[ind_array] = ts
        end
        # FIXME critical section: bottom neck suspected

        # start fetch
        if signaling_fetching
          thread_safe_notify(monitorDT.wait_to_fetch)
          signaling_fetching = false
        end

        thread_safe_wait(monitorDT.fetch_index_read)

        wrlock(monitorDT,0.5) do
            monitorDT.procedures[2](monitorDT,ind_array)
            thread_safe_notify(monitorDT.fetch_index_updated)
        end

        @info "updated index to $ind_array .."

    end
end


"""
    SpinnakerCameras.fetching()
    fetches data from RemoteCamera arrays to RemoteCamera buffers
""" fetching
fetching(remcam::RemoteCamera, monitorRC::RemoteCameraMonitor,
          monitorDT::DataMonitor) = begin
          try
            @spawn _fetching(remcam, monitorRC,monitorDT)
          catch ex
            @error ex
          end
        end


function _fetching(remcam::RemoteCamera, monitorRC::RemoteCameraMonitor, monitorDT::DataMonitor)
    first_loop = true
    timeout = 0.5
    thr_id = Threads.threadid()
    while true
        # FIXME critical section: bottom neck suspected
        # first loop skip waiting

        if first_loop
          @info "first fetching thread id = $thr_id"
          fetch_from_array(remcam,monitorRC,monitorDT,timeout)
          first_loop = false
        else
          thread_safe_wait(monitorDT.fetch_index_updated)
          fetch_from_array(remcam,monitorRC,monitorDT,timeout)

        end

    end
end




## attach extension
function attach(::Type{SharedCamera}, shmid::Integer)
    # Attach the shared object to the address space of the caller, then wrap it
    # in a Julia object.
    ptr = ccall((:tao_attach_shared_camera, taolib),
                Ptr{AbstractSharedObject}, (ShmId,), shmid)
    _check(ptr != C_NULL)
    cam = _wrap(SharedCamera, ptr)
    return cam
end

function attach_monitor_mutex!(monitor::AbstractMonitor, shmid::Integer)

    ptr = _call_attach(shmid, SHARED_OBJECT)
    _check(ptr != C_NULL)
    _set_ptr!(monitor, ptr)
    if ptr != C_NULL && !_get_final(obj)
        finalizer(_finalize, obj)
        _set_final!(obj, true)
    end
    return monitor
end

#--- shared camera operations
# Operation - Commands table
next_camera_operation(cmd::RemoteCameraCommand,
shcam::SharedCamera,monitorSC::SharedCameraMonitor,
  remcam::RemoteCamera, monitorRC::RemoteCameraMonitor) = next_camera_operation(Val(cmd),shcam,monitorSC ,remcam , monitorRC)

for (cmd, cam_op) in (
    (:CMD_INIT, :init),
    (:CMD_WORK, :start)

    )
@eval begin
    function next_camera_operation(::Val{$cmd}, shcam::SharedCamera,
                        monitorSC::SharedCameraMonitor, remcam::RemoteCamera,monitorRC::RemoteCameraMonitor)
        try
            cameraTask = @spawn $cam_op(shcam, monitorSC,remcam , monitorRC)
            str_op = $cam_op
            # @info "Executed  $str_op \n"
        catch ex
            if !isa(ex, SpinnakerCameras.CallError)
                rethrow(ex)
            end
            @warn "Error occurs $(ex.func)"

            wrlock(monitorSC) do
                monitorSC.start_status = SIG_ERROR
            end

            return_val =  false
            return return_val
        end

        wrlock(monitorSC) do
            monitorSC.start_status = SIG_OK
        end

        return_val =  true
        thread_safe_notify(monitorSC.not_started)
        return return_val
    end
end
end

"""
    SpinnakerCameras.init()
""" init
init(shcam::SharedCamera, monitorSC::SharedCameraMonitor,
    remcam::RemoteCamera, monitorRC::RemoteCameraMonitor) = begin
    camera = device(shcam,1)
    try
        initialize(camera)
        wrlock(monitorSC,0.5) do
            monitorSC.completion = SIG_DONE
        end
        thread_safe_wait(monitorRC.state_updating)
        thread_safe_notify(monitorSC.not_complete)
    catch ex
        wrlock(monitorSC,0.5) do
            monitorSC.completion = SIG_ERROR
        end
        thread_safe_notify(monitorSC.not_complete)
        rethrow(ex)
    end
    nothing
end
"""
    Tao.start(cam; skip=0, timeout=5.0)
"""

start(shcam::SharedCamera,  monitorSC::SharedCameraMonitor,
      remcam::RemoteCamera, monitorRC::RemoteCameraMonitor) = begin

    shcam.attachedCam > 0 || throw(ErrorException("No attached cameras"))

    camera = device(shcam,1)
    img_buffer = Channel{DataPack}(1)
    monitorDT =  DataMonitor(default_p_list_data)
    create_monitor_shared_object!(SharedObject,monitorDT)

    # start working thread
    working(camera,img_buffer)
      # @info "working starts"

    try
        # start grabbing
        grabbing(img_buffer,shcam, remcam, monitorRC,monitorDT)
        # @info "grabbing starts"
      catch ex
        println(ex)
        @warn "failed at grabbing"
      end

      try
        # start fetching
        thread_safe_wait(monitorDT.wait_to_fetch)
        fetching(remcam, monitorRC,monitorDT)
        # @info "fetching starts"

      catch ex
        @warn "error with start"
        wrlock(monitorSC,0.5) do
            monitorSC.completion = SIG_ERROR
        end
        thread_safe_notify(monitorSC.not_complete)
        throw(ex)
    end
    # @info "wait state update"
    thread_safe_wait(monitorRC.state_updating)
    wrlock(monitorSC,0.5) do
        monitorSC.completion = SIG_DONE
    end
    thread_safe_notify(monitorSC.not_complete)
    @info "start is DONE"
    nothing
end

"""
    Tao.stop(cam; timeout=5.0)

    stops image acquisition by shared or remote camera `cam` not waiting more than
    the limit set by `timeout` in seconds.  Nothing is done if acquisition is not
    running or about to start.

"""
stop(remoteCam::RemoteCamera,  camNum::Integer; timeout::Real=5.0) = begin
    cam = device(remoteCam)
    cam.attachedCam > 0 || throw(ErrorException("No attached cameras"))
    cam.attachedCam >= camNum || throw(ErrorException("Invalid camera number"))

    camera = cam.cameras[camNum]
    state = rdlock(cam, timeout) do
        cam.state
    end

    if state == STATE_WORK
        schedule(@task stop(camera))
    else
        throw(ErrorException("Camera is not working: $state"))
    end

    nothing

end

"""
    Tao.abort(cam; timeout=5.0)

    aborts image acquisition by shared or remote camera `cam` not waiting more than
    the limit set by `timeout` in seconds.  Nothing is done if acquisition is not
    running or about to start.

"""
# abort(cam::RemoteCamera; kwds...) = abort(device(cam); kwds...)
abort(remoteCam::RemoteCamera; timeout::Real=5.0) = begin
    cam = device(remoteCam)
    cam.attachedCam > 0 || throw(ErrorException("No attached cameras"))
    cam.attachedCam >= camNum || throw(ErrorException("Invalid camera number"))

    camera = cam.cameras[camNum]

    state = rdlock(cam, timeout) do
        cam.state
    end

    if state == STATE_WORK
        schedule(@task aborting(camera))
    end
    nothing
end


#---
"""
    TaoBindings.fetch(cam, sym, timeout=1.0) -> arr

    yields the shared array storing an image acquired by the remote camera `cam`.
    Argument `sym` may be `:last` to fetch the last acquired frame, or `:next` to
    fetch the next one.  The call never blocks more than the limit set by `timeout`
    and is just used for locking the camera (which should never be very long).

    The result is a shared array which should be locked for reading to make sure
    its contents is preserved and up to date.

    When fetching the next frame, the array counter should be checked to assert the
    vailidity of the frame:

        arr = fetch(cam, :next)
        rdlock(arr) do
            if arr.counter > 0
                # This is a valid frame.
                ...
            else
                # Acquisition has been stopped.
                ...
            end
        end

"""
function fetch_from_array(remcam::RemoteCamera, monitorRC:: RemoteCameraMonitor,
                          monitorDT::DataMonitor, timeout::Float64)
    # retrieve the index in the array to be fetch

      ind = rdlock(monitorDT,timeout) do
          monitorDT.fetch_index
      end

    thread_safe_notify(monitorDT.fetch_index_read)
    @info "index $ind is read..."

    # put data in the acquisition buffer
    try
      # lock shared arrays
      wrlock(remcam.img,timeout) do
          copyto!(remcam.img, remcam.arrays[ind])
      end
      wrlock(remcam.imgTime,timeout) do
         remcam.imgTime[1] =  remcam.timestamps[ind]
      end

      # increment release counter
      wrlock(monitorDT,timeout) do
          monitorDT.procedures[4](monitorDT)
      end
    catch ex
      println(ex)
    end

end




#===
"""
    TaoBindings.fetch(cam, sym, timeout=1.0) -> arr

    yields the shared array storing an image acquired by the remote camera `cam`.
    Argument `sym` may be `:last` to fetch the last acquired frame, or `:next` to
    fetch the next one.  The call never blocks more than the limit set by `timeout`
    and is just used for locking the camera (which should never be very long).

    The result is a shared array which should be locked for reading to make sure
    its contents is preserved and up to date.

    When fetching the next frame, the array counter should be checked to assert the
    vailidity of the frame:

        arr = fetch(cam, :next)
        rdlock(arr) do
            if arr.counter > 0
                # This is a valid frame.
                ...
            else
                # Acquisition has been stopped.
                ...
            end
        end

"""
function fetch(cam::RemoteCamera, sym::Symbol, timeout=1.0)
    # Get the number of acquired images and the shared memory identifers of the
    # the last and nex images.
    dev = device(cam)
    counter, last, next, lastTS, nextTS = rdlock(dev, timeout) do
        Int(dev.counter), dev.last, dev.next, dev.lastTS, dev.nextTS
    end
    if sym === :next
        counter += 1
        shmid = next
        timestamp = nextTS
    elseif sym === :last
        shmid = last
        timestamp = lastTS
    else
        throw(ArgumentError("invalid acquisition buffer identifier"))
    end
    if counter < 1 || shmid == BAD_SHMID
        error("no images have been acquired yet, first start acquisition")
    end

    # To avoid the overheads of systematically attaching/detaching shared
    # arrays, figure out whether we already have attached the shared array in
    # our list.
    arrays = _get_arrays(cam)                # list of shared arrays
    shmids = _get_shmids(cam)                # list if shared memory identifiers
    timestamps = _get_timestamps(cam)
    index = (counter - 1)%length(shmids) + 1
    if shmids[index] != shmid
        # FIXME: if shmid != BAD_SHMID
        # FIXME:     warning("we are loosing frames!")
        # FIXME: end
        arrays[index] = attach(SharedArray, shmid)
        shmids[index] = shmid
        timestamps[index] = timestamp
    end
    return arrays[index], timestamps[index]
end

"""
    timedwait(T, cam, timeout) -> [wgt,] img

    waits for a new image to be available from the remote camera `cam` and returns
    the result specified by `T`, that is either a simple image if `T = SingleImage`
    or an array of weights and an image if `T = WeightedImage`.

    The `timeout` argument is to specify a time limit for waiting.  If it is a
    2-tuple, `timeout[1]` is for waiting for the remote camera and `timeout[2]` is
    for waiting for the image.  Otherwise the default time limit of
    `TaoBindings.fetch` is assumed for waiting for the camera and `timeout` is for
    waiting for the image.

    For example, to wait for the next image with a timout of 0.1 second on the
    shared camera and a timeout of 2 seconds on the image, call:

        timedwait( cam, (0.1, 2))


    See also: [`TaoBindings.fetch`](@ref), [`TaoBindings.rdlock`](@ref).

"""

function Base.timedwait(cam::RemoteCamera, timeout)
    # fetch the image data from Remote Camera
    arr, ts = fetch(cam, :next)
    # made the data available in the acquisition buffer
    rdlock(arr, timeout) do
        _produce(arr, cam)
        cam.imgTime = ts
    end

end

@inline fastmax(a::T, b::T) where {T<:AbstractFloat} = (b > a ? b : a)

function _produce(buf::SharedArray{<:Any,2},
                  cam::RemoteCamera{T}) where {T}
      #copy the shared array to RemoteCamera buffer
    nx, ny = size(buf)
    img = cam.cached_imag
    @inbounds for y in 1:ny
        @simd for x in 1:nx
            img[x,y] = T(buf[x,y])
        end
    end

end
===#
