@info "Installing scipy"
using PyCall
try
    run(`$(PyCall.python) -m pip install scipy`)
catch e
    @warn("Couldn't install scipy in TopoPlots.jl build.jl.
           Please make sure manually, that the python PyCall uses has scipy installed")
    rethrow(e)
end
