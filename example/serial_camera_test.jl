using Revise

using SpinnakerCameras
system = SpinnakerCameras.System()
camList = SpinnakerCameras.CameraList(system)
camNum = length(camList)

if camNum == 0
    finalize(camList)
    finalize(system)
    print("No cameras found... \n Done...")

end
print("$(camNum) cameras are found \n" )

camera = camList[1]

dev = SpinnakerCameras.create(SpinnakerCameras.SharedCamera)
shcam = SpinnakerCameras.attach(SpinnakerCameras.SharedCamera, dev.shmid)

SpinnakerCameras.register(shcam,camera)
dims = (800,800)
remcam = SpinnakerCameras.RemoteCamera{UInt8}(shcam, dims)


#--- listening
# 1. broadcasting shmid of cmds, state, img, imgBuftime, remote camera monitor
img_shmid = SpinnakerCameras.get_shmid(remcam.img)
imgTime_shmid = SpinnakerCameras.get_shmid(remcam.imgTime)
cmds_shmid = SpinnakerCameras.get_shmid(remcam.cmds)
shmids = [img_shmid,imgTime_shmid,cmds_shmid]
SpinnakerCameras.broadcast_shmids(shmids)

# 2. initialize
RemoteCameraEngine = SpinnakerCameras.listening(shcam, remcam)
remcam.cmds[1] = SpinnakerCameras._to_Cint(SpinnakerCameras.CMD_INIT)
notify(remcam.no_cmds)

# 3. configure camera
# update ImageConfigContext in shared camera
new_conf = SpinnakerCameras.ImageConfigContext()
#  nanosecond exposure time
new_conf.exposuretime = 3000.0
# ROI
new_conf.width = 800
new_conf.height = 800
new_conf.offsetX = (2048-new_conf.width )/2
new_conf.offsetY = (1536-new_conf.height)/2

SpinnakerCameras.set_img_config(shcam,new_conf)
remcam.cmds[1] = SpinnakerCameras._to_Cint(SpinnakerCameras.CMD_CONFIG)
notify(remcam.no_cmds)

# 4. start acquisition
remcam.cmds[1] = SpinnakerCameras._to_Cint(SpinnakerCameras.CMD_WORK)
notify(remcam.no_cmds)

# 5. stop acquisition
# remcam.cmds[1] = SpinnakerCameras._to_Cint(SpinnakerCameras.CMD_STOP)
# notify(remcam.no_cmds)
