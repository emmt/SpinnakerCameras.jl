module TestingSpinnakerCameras

using SpinnakerCameras:
    SPINNAKER_ERR_NOT_IMPLEMENTED,
    LOG_LEVEL_OFF,
    LOG_LEVEL_FATAL,
    LOG_LEVEL_ALERT,
    LOG_LEVEL_CRIT,
    LOG_LEVEL_ERROR,
    LOG_LEVEL_WARN,
    LOG_LEVEL_NOTICE,
    LOG_LEVEL_INFO,
    LOG_LEVEL_DEBUG,
    LOG_LEVEL_NOTSET,
    SpinnakerCameras,
    Cenum,
    LogLevel

using Test

@testset "Errors" begin
    err = SpinnakerCameras.CallError(SPINNAKER_ERR_NOT_IMPLEMENTED, :spinFunc)
    str = let buf = IOBuffer();
        show(buf, MIME("text/plain"), err);
        String(take!(buf));
    end
    @test str == "error SPINNAKER_ERR_NOT_IMPLEMENTED returned by function `spinFunc`"
end

@testset "Images" begin
    dims = (13, 22)
    for bpp in (8, 16)
        pixelformat = (bpp ==  8 ? SpinnakerCameras.PixelFormat_Mono8 :
                       bpp == 16 ? SpinnakerCameras.PixelFormat_Mono16 : -1)
        img = SpinnakerCameras.Image(pixelformat, dims)
        @test size(img) === dims
        @test img.bitsperpixel == bpp
        @test img.pixelformat == pixelformat
        @test img.pixelformatname == "Mono$bpp"
        @test img.stride*8 ≥ img.bitsperpixel*img.width
        @test img.buffersize ≥ img.stride*img.height

        # Check type returned by all properties.
        @test isa(img.bitsperpixel,     Csize_t)
        @test isa(img.buffersize,       Csize_t)
        @test isa(img.data,             Ptr{Cvoid})
        @test isa(img.privatedata,      Ptr{Cvoid})
        @test isa(img.frameid,          UInt64)
        @test isa(img.height,           Csize_t)
        @test isa(img.id,               UInt64)
        @test isa(img.offsetx,          Csize_t)
        @test isa(img.offsety,          Csize_t)
        @test isa(img.paddingx,         Csize_t)
        @test isa(img.paddingy,         Csize_t)
        @test isa(img.payloadtype,      Csize_t)
        @test isa(img.pixelformat,      Cenum)
        @test isa(img.pixelformatname,  String)
        @test isa(img.size,             Csize_t)
        @test isa(img.stride,           Csize_t)
        @test isa(img.timestamp,        UInt64)
        @test isa(img.tlpixelformat,    UInt64)
        @test isa(img.validpayloadsize, Csize_t)
        @test isa(img.width,            Csize_t)
    end
end

@testset "Object System" begin
    sys = SpinnakerCameras.System()
    @test isa(VersionNumber(sys), VersionNumber)
    @test isa(sys.libraryversion, VersionNumber)
    @test_throws ErrorException sys.libraryversion = v"1.2.3"
    @test isa(sys.logginglevel, LogLevel)
    for logginglevel in (LOG_LEVEL_ERROR, LOG_LEVEL_WARN)
        sys.logginglevel = logginglevel
        @test sys.logginglevel == logginglevel
    end
    @test isa(sys.interfaces, SpinnakerCameras.InterfaceList)
    @test length(sys.interfaces) ≥ 0
    @test length(empty!(sys.interfaces)) == 0
    @test all(x -> isa(x, SpinnakerCameras.Interface), sys.interfaces)
    @test all(x -> isa(x.cameras, SpinnakerCameras.CameraList), sys.interfaces)
    @test isa(sys.cameras, SpinnakerCameras.CameraList)
    @test length(sys.cameras) ≥ 0
    @test length(empty!(sys.cameras)) == 0
    @test all(x -> isa(x, SpinnakerCameras.Camera), sys.cameras)
end

end # module
