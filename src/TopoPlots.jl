module TopoPlots

using PythonCall

const SciPy = PythonCall.pynew()
const SciPy_Spatial = PythonCall.pynew()


# taken from https://github.com/beacon-biosignals/PyMNE.jl/blob/main/src/PyMNE.jl
function __init__()
    # all of this is __init__() so that it plays nice with precompilation
    # see https://github.com/cjdoris/PythonCall.jl/blob/5ea63f13c291ed97a8bacad06400acb053829dd4/src/Py.jl#L85-L96
    PythonCall.pycopy!(SciPy, pyimport("scipy"))
    PythonCall.pycopy!(SciPy_Spatial, pyimport("scipy.spatial"))
    return nothing
end


using Makie
using LinearAlgebra
using Statistics
using GeometryBasics
using GeometryBasics: origin, radius
using Parameters
using InteractiveUtils
using Dierckx
using ScatteredInterpolation


assetpath(files...) = normpath(joinpath(dirname(@__DIR__), "assets", files...))

function example_data()
    data = Array{Float32}(undef, 64, 400, 3)
    read!(TopoPlots.assetpath("example-data.bin"), data)

    positions = Vector{Point2f}(undef, 64)
    read!(TopoPlots.assetpath("layout64.bin"), positions)
    return data, positions
end

# Write your package code here.
include("interpolators.jl")
include("extrapolation.jl")
include("core-recipe.jl")
include("eeg.jl")

# Interpolators
export ClaughTochter, SplineInterpolator, DelaunayMesh, NullInterpolator, ScatteredInterpolationMethod
# Extrapolators
export GeomExtrapolation, NullExtrapolation

end
