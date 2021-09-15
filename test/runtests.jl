module TestingSpinnakerCameras

using SpinnakerCameras
using Test

@testset "Errors" begin
    err = SpinnakerCameras.CallError(-1003, :spinFunc)
    str = let buf = IOBuffer();
        show(buf, MIME("text/plain"), err);
        String(take!(buf));
    end
    @test str == "error SPINNAKER_ERR_NOT_IMPLEMENTED (-1003) returned by function `spinFunc`"
end

end # module
