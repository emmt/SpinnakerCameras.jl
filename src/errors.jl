#
# errors.jl -
#
# Management of errors for the Julia interface to the Spinnaker SDK.
#
#------------------------------------------------------------------------------

"""
    SpinnakerCameras.CallError(err, func)

yields an exception representing an error with code `err` occuring in a call to
function `func` of the Spinnaker SDK.

""" CallError

# Throws a `CallError` exception if `err` indicates an error in function `func`.
function _check(err::Err, func::Symbol)
    if err != SPINNAKER_ERR_SUCCESS
        throw_call_error(err, func)
    end
    return nothing
end

@noinline throw_call_error(err::Err, func::Symbol) =
    throw(CallError(err, func))

# `show` and `print` methods must be extended for `Err` to avoid errors with
# invalid enumeration values.
for func in (:print, :show)
    @eval $func(io::IO, err::Err) = begin
        try
            $func(io, Symbol(err))
        catch
            $func(io, Integer(err))
        end
    end
end

show(io::IO, ::MIME"text/plain", err::CallError) =
    print(io, "error ", err.code, " returned by function `", err.func, "`")
